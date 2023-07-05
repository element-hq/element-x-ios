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

class NotificationServiceExtension: UNNotificationServiceExtension {
    private let settings = NSESettings()
    private lazy var keychainController = KeychainController(service: .sessions,
                                                             accessGroup: InfoPlistReader.main.keychainAccessGroupIdentifier)
    private var handler: ((UNNotificationContent) -> Void)?
    private var modifiedContent: UNMutableNotificationContent?
    private var userSession: NSEUserSession?

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

        NSELogger.configure()

        NSELogger.logMemory(with: tag)

        MXLog.info("\(tag) #########################################")
        MXLog.info("\(tag) Payload came: \(request.content.userInfo)")

        Task {
            await run(with: credentials,
                      roomId: roomId,
                      eventId: eventId)
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
                     eventId: String) async {
        MXLog.info("\(tag) run with roomId: \(roomId), eventId: \(eventId)")

        do {
            let userSession = try NSEUserSession(credentials: credentials)
            self.userSession = userSession
            var itemProxy = await userSession.notificationItemProxy(roomID: roomId, eventID: eventId)
            if settings.isEncryptionSyncEnabled,
               itemProxy?.isEncrypted == true,
               let _ = try? userSession.startEncryptionSync() {
                // TODO: The following wait with a timeout should be handled by the SDK
                // We try to decrypt the notification for 10 seconds at most
                let date = Date()
                repeat {
                    // if the sync terminated we try one last time then we break from the loop
                    guard userSession.isSyncing else {
                        itemProxy = await userSession.notificationItemProxy(roomID: roomId, eventID: eventId)
                        break
                    }
                    itemProxy = await userSession.notificationItemProxy(roomID: roomId, eventID: eventId)
                } while itemProxy?.isEncrypted == true && date.timeIntervalSinceNow > -10
            }

            guard let itemProxy else {
                MXLog.info("\(tag) no notification for the event, discard")
                return discard()
            }

            // After the first processing, update the modified content
            modifiedContent = try await itemProxy.process(mediaProvider: nil)

            guard itemProxy.hasMedia else {
                MXLog.info("\(tag) no media needed")

                // We've processed the item and no media operations needed, so no need to go further
                return notify()
            }

            MXLog.info("\(tag) process with media")

            // There is some media to load, process it again
            if let latestContent = try? await itemProxy.process(mediaProvider: userSession.mediaProvider) {
                // Processing finished, hopefully with some media
                modifiedContent = latestContent
            }
            // We still notify, but without the media attachment if it fails to load
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
        userSession?.stopEncryptionSync()
    }

    deinit {
        cleanUp()
        NSELogger.logMemory(with: tag)
        MXLog.info("\(tag) deinit")
    }
}
