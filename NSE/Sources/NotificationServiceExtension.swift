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
    var handler: ((UNNotificationContent) -> Void)?
    var modifiedContent: UNMutableNotificationContent?

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
            try await run(with: credentials,
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
                     eventId: String) async throws {
        MXLog.info("\(tag) run with roomId: \(roomId), eventId: \(eventId)")

        let service = NotificationServiceProxy(basePath: URL.sessionsBaseDirectory.path,
                                               userID: credentials.userID)

        guard let itemProxy = try await service.notificationItem(roomId: roomId,
                                                                 eventId: eventId) else {
            MXLog.error("\(tag) got no notification item")

            // Notification should be discarded
            return discard()
        }

        // First process without a media proxy.
        // After this some properties of the notification should be set, like title, subtitle, sound etc.
        guard let firstContent = try await itemProxy.process(mediaProvider: nil) else {
            MXLog.error("\(tag) not even first content")

            // Notification should be discarded
            return discard()
        }

        // After the first processing, update the modified content
        modifiedContent = firstContent

        guard itemProxy.requiresMediaProvider else {
            MXLog.info("\(tag) no media needed")

            // We've processed the item and no media operations needed, so no need to go further
            return notify()
        }

        MXLog.info("\(tag) process with media")

        // There is some media to load, process it again
        if let latestContent = try await itemProxy.process(mediaProvider: createMediaProvider(with: credentials)) {
            // Processing finished, hopefully with some media
            modifiedContent = latestContent
            return notify()
        } else {
            // This is not very likely, as it should discard the notification sooner
            return discard()
        }
    }

    private func createMediaProvider(with credentials: KeychainCredentials) throws -> MediaProviderProtocol {
        let builder = ClientBuilder()
            .basePath(path: URL.sessionsBaseDirectory.path)
            .username(username: credentials.userID)

        let client = try builder.build()
        try client.restoreSession(session: credentials.restorationToken.session)
        
        MXLog.info("\(tag) creating media provider")
        
        return MediaProvider(mediaLoader: MediaLoader(client: client),
                             imageCache: .onlyOnDisk,
                             backgroundTaskService: nil)
    }
    
    private func notify() {
        MXLog.info("\(tag) notify")

        guard let modifiedContent else {
            MXLog.info("\(tag) notify: no modified content")
            return
        }

        guard let identifier = modifiedContent.notificationIdentifier,
              !settings.servedNotificationIdentifiers.contains(identifier) else {
            MXLog.info("\(tag) notify: notification already served")
            return
        }

        settings.servedNotificationIdentifiers.insert(identifier)
        handler?(modifiedContent)
        handler = nil
        self.modifiedContent = nil
    }

    private func discard() {
        MXLog.info("\(tag) discard")

        handler?(UNMutableNotificationContent())
        handler = nil
        modifiedContent = nil
    }

    private var tag: String {
        "[NSE][\(Unmanaged.passUnretained(self).toOpaque())][\(Unmanaged.passUnretained(Thread.current).toOpaque())]"
    }

    deinit {
        NSELogger.logMemory(with: tag)
        MXLog.info("\(tag) deinit")
    }
}
