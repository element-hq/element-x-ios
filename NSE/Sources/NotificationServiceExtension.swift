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
    private var service: NotificationServiceProxyProtocol?
    private var mediaProxy: MediaProxyProtocol?
    private lazy var keychainController: KeychainControllerProtocol = KeychainController(service: .sessions,
                                                                                         accessGroup: Bundle.appGroupIdentifier)

    private static var isLoggerInitialized = false
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    /// Memory formatter, uses exact 2 fraction digits and no grouping
    private static var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.alwaysShowsDecimalSeparator = true
        formatter.decimalSeparator = "."
        formatter.groupingSeparator = ""
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }

    override init() {
        //  use `en` as fallback language
        Bundle.elementFallbackLanguage = "en"

        super.init()
    }

    private var formattedMemoryAvailable: String {
        let freeBytes = os_proc_available_memory()
        let freeMB = Double(freeBytes) / 1024 / 1024
        guard let formattedStr = Self.numberFormatter.string(from: NSNumber(value: freeMB)) else {
            return ""
        }
        return "\(formattedStr) MB"
    }

    override func didReceive(_ request: UNNotificationRequest,
                             withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent

        print("Available memory: \(formattedMemoryAvailable)")

        guard !DataProtectionManager.isDeviceInRebootedAndLockedState(containerURL: FileManager.default.appGroupContainerURL) else {
            fallback()
            return
        }
        guard let credentials = keychainController.restoreTokens().first else {
            // user not logged-in
            fallback()
            return
        }
        guard let roomId = request.content.userInfo[NotificationConstants.UserInfoKey.roomIdentifier] as? String,
              let eventId = request.content.userInfo[NotificationConstants.UserInfoKey.eventIdentifier] as? String else {
            // not a Matrix notification
            fallback()
            return
        }

        NSELogger.configure()

        service = NotificationServiceProxy(basePath: FileManager.default.sessionsBaseDirectory.path,
                                           userId: credentials.userID)

        Task { @MainActor in
            guard let itemProxy = try await service?.getNotificationItem(roomId: roomId,
                                                                         eventId: eventId) else {
                fallback()
                return
            }
            if itemProxy.requiresMediaProxy {
                mediaProxy = try await createMediaProxy(credentials)
            }
            process(itemProxy: itemProxy,
                    roomId: roomId,
                    contentHandler: contentHandler)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        fallback()
    }

    private func process(itemProxy: NotificationItemProxy,
                         roomId: String,
                         contentHandler: @escaping (UNNotificationContent) -> Void) {
        switch itemProxy.timelineItemProxy {
        case .event(let eventItem):
            guard eventItem.isMessage || eventItem.isRedacted else {
                // To be handled in the future
                discard()
                return
            }
            guard let message = eventItem.content.asMessage() else {
                fatalError("Only handled messages")
            }
            Task {
                do {
                    let content = try await itemProxy.process(with: message,
                                                              senderId: eventItem.sender,
                                                              roomId: roomId,
                                                              mediaProxy: mediaProxy)
                    contentHandler(content)
                } catch {
                    fallback()
                }
            }
        case .virtual:
            discard()
        case .other:
            discard()
        }
    }

    private func createMediaProxy(_ credentials: KeychainCredentials) async throws -> MediaProxyProtocol {
        let builder = ClientBuilder()
            .basePath(path: FileManager.default.sessionsBaseDirectory.path)
            .username(username: credentials.userID)

        let client = try builder.build()
        try client.restoreLogin(restoreToken: credentials.restoreToken)
        return await MediaProxy(client: client)
    }

    private func fallback() {
        guard let bestAttemptContent else {
            return
        }
        contentHandler?(bestAttemptContent)
        contentHandler = nil
    }

    private func discard() {
        contentHandler?(UNMutableNotificationContent())
        contentHandler = nil
    }
}
