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

import CallKit
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

private let settings: NSESettingsProtocol = AppSettings()
private let notificationContentBuilder = NotificationContentBuilder(messageEventStringBuilder: RoomMessageEventStringBuilder(attributedStringBuilder: AttributedStringBuilder(mentionBuilder: PlainMentionBuilder())))
private let keychainController = KeychainController(service: .sessions,
                                                    accessGroup: InfoPlistReader.main.keychainAccessGroupIdentifier)

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

        MXLog.info("\(tag) #########################################")
        NSELogger.logMemory(with: tag)
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
        notify(unreadCount: nil)
    }

    private func run(with credentials: KeychainCredentials,
                     roomId: String,
                     eventId: String,
                     unreadCount: Int?) async {
        MXLog.info("\(tag) run with roomId: \(roomId), eventId: \(eventId)")

        do {
            // This function might be run concurrently and from different processes, let the SDK handle race conditions
            // on fetching user sessions
            let userSession = try await NSEUserSession(credentials: credentials, clientSessionDelegate: keychainController)
            
            guard let itemProxy = await userSession.notificationItemProxy(roomID: roomId, eventID: eventId) else {
                MXLog.info("\(tag) no notification for the event, discard")
                return discard(unreadCount: unreadCount)
            }
            
            guard await shouldHandleCallNotification(itemProxy) else {
                return discard(unreadCount: unreadCount)
            }
            
            // After the first processing, update the modified content
            modifiedContent = try await notificationContentBuilder.content(for: itemProxy, mediaProvider: nil)
            
            guard itemProxy.hasMedia else {
                MXLog.info("\(tag) no media needed")

                // We've processed the item and no media operations needed, so no need to go further
                return notify(unreadCount: unreadCount)
            }

            MXLog.info("\(tag) process with media")

            // There is some media to load, process it again
            if let latestContent = try? await notificationContentBuilder.content(for: itemProxy, mediaProvider: userSession.mediaProvider) {
                // Processing finished, hopefully with some media
                modifiedContent = latestContent
            }
            // We still notify, but without the media attachment if it fails to load
            
            return notify(unreadCount: unreadCount)
        } catch {
            MXLog.error("NSE run error: \(error)")
            return discard(unreadCount: unreadCount)
        }
    }
    
    private func notify(unreadCount: Int?) {
        MXLog.info("\(tag) notify")

        guard let modifiedContent else {
            MXLog.info("\(tag) notify: no modified content")
            return discard(unreadCount: unreadCount)
        }
        
        if let unreadCount {
            modifiedContent.badge = NSNumber(value: unreadCount)
        }

        handler?(modifiedContent)
        cleanUp()
    }

    private func discard(unreadCount: Int?) {
        MXLog.info("\(tag) discard")
        
        let content = UNMutableNotificationContent()
        
        if let unreadCount {
            content.badge = NSNumber(value: unreadCount)
        }

        handler?(content)
        cleanUp()
    }

    private var tag: String {
        "[NSE][\(Unmanaged.passUnretained(self).toOpaque())][\(Unmanaged.passUnretained(Thread.current).toOpaque())][\(ProcessInfo.processInfo.processIdentifier)]"
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
    
    private func shouldHandleCallNotification(_ itemProxy: NotificationItemProxyProtocol) async -> Bool {
        // Handle incoming VoIP calls, show the native OS call screen
        // https://developer.apple.com/documentation/callkit/sending-end-to-end-encrypted-voip-calls
        //
        // The way this works is the following:
        // - the NSE receives the notification and decrypts it
        // - checks if it's still time relevant (max 10 seconds old) and whether it should ring
        // - otherwise it goes on to show it as a normal notification
        // - if it should ring then it discards the notification but invokes `reportNewIncomingVoIPPushPayload`
        // so that the main app can handle it
        // - the main app picks this up in `PKPushRegistry.didReceiveIncomingPushWith` and
        // `CXProvider.reportNewIncomingCall` to show the system UI and handle actions on it.
        // N.B. this flow works properly only when background processing capabilities are enabled
        
        guard case let .timeline(event) = itemProxy.event,
              case let .messageLike(content) = try? event.eventType(),
              case let .callNotify(notificationType) = content,
              notificationType == .ring else {
            return true
        }
        
        let timestamp = Date(timeIntervalSince1970: TimeInterval(event.timestamp() / 1000))
        guard abs(timestamp.timeIntervalSinceNow) < ElementCallServiceNotificationDiscardDelta else {
            MXLog.info("Call notification is too old, handling as push notification")
            return true
        }
        
        var payload = [ElementCallServiceNotificationKey.roomID.rawValue: itemProxy.roomID,
                       ElementCallServiceNotificationKey.roomDisplayName.rawValue: itemProxy.roomDisplayName,
                       ElementCallServiceNotificationKey.senderID.rawValue: itemProxy.senderID]
        if let senderDisplayName = itemProxy.senderDisplayName {
            payload[ElementCallServiceNotificationKey.senderDisplayName.rawValue] = senderDisplayName
        }
        
        do {
            try await CXProvider.reportNewIncomingVoIPPushPayload(payload)
        } catch {
            MXLog.error("Failed reporting voip call with error: \(error). Handling as push notification")
            return true
        }
        
        return false
    }
}
