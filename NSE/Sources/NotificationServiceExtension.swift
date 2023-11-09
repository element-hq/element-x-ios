//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Intents
import MatrixRustSDK
import UserNotifications

// The lifecycle of the NSE looks something like the following:
//  1)  App receives notification
//  2)  System creates an instance of the extension class
//      and calls `didReceive` in the background
//  3)  Extension processes messages / displays whatever
//      notifications it needs to
//  4)  Extension notifies its work is complete by calling
//      the contentHandler
//  5)  If the extension takes too long to perform its work
//      (more than 30s), it will be notified and immediately
//      terminated
//
// Note that the NSE does *not* always spawn a new process to
// handle a new notification and will also try and process notifications
// in parallel. `didReceive` could be called twice for the same process,
// but it will always be called on different threads. It may or may not be
// called on the same instance of `NotificationService` as a previous
// notification.
//
// We keep a global `environment` singleton to ensure that our app context,
// database, logging, etc. are only ever setup once per *process*

private let settings = AppSettings()
private let notificationContentBuilder = NotificationContentBuilder(messageEventStringBuilder: RoomMessageEventStringBuilder(attributedStringBuilder: AttributedStringBuilder(permalinkBaseURL: settings.permalinkBaseURL,
                                                                                                                                                                              mentionBuilder: PlainMentionBuilder())))
private let keychainController = KeychainController(service: .sessions,
                                                    accessGroup: InfoPlistReader.main.keychainAccessGroupIdentifier)
private var userSessions = [String: NSEUserSession]()

class NotificationServiceExtension: UNNotificationServiceExtension {
    private var handler: ((UNNotificationContent) -> Void)?
    private var modifiedContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest,
                             withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        guard !DataProtectionManager.isDeviceLockedAfterReboot(containerURL: URL.appGroupContainerDirectory),
              let roomId = request.roomId,
              let eventId = request.eventId,
              let clientID = request.pusherNotificationClientIdentifier,
              let credentials = keychainController.restorationTokens().first(where: { $0.restorationToken.pusherNotificationClientIdentifier == clientID }) else {
            // We cannot process this notification, it might be due to one of these:
            // - Device rebooted and locked
            // - Not a Matrix notification
            // - User is not signed in
            // - NotificationID could not be resolved
            return contentHandler(request.content)
        }

        handler = contentHandler
        modifiedContent = request.content.mutableCopy() as? UNMutableNotificationContent

        NSELogger.configure(logLevel: settings.logLevel)

        NSELogger.logMemory(with: tag)

        MXLog.info("\(tag) #########################################")
        MXLog.info("\(tag) Payload came: \(request.content.userInfo)")

        Task {
            await run(with: credentials,
                      roomId: roomId,
                      eventId: eventId,
                      unreadCount: request.unreadCount)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        MXLog.warning("\(tag) serviceExtensionTimeWillExpire")
        notify()
    }

    private func run(with credentials: KeychainCredentials,
                     roomId: String,
                     eventId: String,
                     unreadCount: Int?) async {
        MXLog.info("\(tag) run with roomId: \(roomId), eventId: \(eventId)")

        do {
            let userSession: NSEUserSession
            if let existingSession = userSessions[credentials.userID] {
                userSession = existingSession
            } else {
                userSession = try NSEUserSession(credentials: credentials, clientSessionDelegate: keychainController)
                userSessions[credentials.userID] = userSession
            }
            
            guard let itemProxy = await userSession.notificationItemProxy(roomID: roomId, eventID: eventId) else {
                MXLog.info("\(tag) no notification for the event, discard")
                return discard()
            }
            
            // After the first processing, update the modified content
            modifiedContent = try await notificationContentBuilder.content(for: itemProxy, mediaProvider: nil)
            
            guard itemProxy.hasMedia else {
                MXLog.info("\(tag) no media needed")

                // We've processed the item and no media operations needed, so no need to go further
                return notify()
            }

            MXLog.info("\(tag) process with media")

            // There is some media to load, process it again
            if let latestContent = try? await notificationContentBuilder.content(for: itemProxy, mediaProvider: userSession.mediaProvider) {
                // Processing finished, hopefully with some media
                modifiedContent = latestContent
            }
            // We still notify, but without the media attachment if it fails to load
            
            // Finally update the app badge
            if let unreadCount {
                modifiedContent?.badge = NSNumber(value: unreadCount)
            }
            
            return notify()
        } catch {
            MXLog.error("NSE run error: \(error)")
            return discard()
        }
    }
    
    private func notify() {
        MXLog.info("\(tag) notify")

        guard let modifiedContent else {
            MXLog.info("\(tag) notify: no modified content")
            return discard()
        }

        handler?(modifiedContent)
        cleanUp()
    }

    private func discard() {
        MXLog.info("\(tag) discard")

        handler?(UNMutableNotificationContent())
        cleanUp()
    }

    private var tag: String {
        "[NSE][\(Unmanaged.passUnretained(self).toOpaque())][\(Unmanaged.passUnretained(Thread.current).toOpaque())]"
    }

    private func cleanUp() {
        handler = nil
        modifiedContent = nil
    }

    deinit {
        cleanUp()
        NSELogger.logMemory(with: tag)
        MXLog.info("\(tag) deinit")
    }
}
