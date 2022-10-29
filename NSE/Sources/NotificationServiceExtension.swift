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

    override init() {
        //  use `en` as fallback language
        Bundle.elementFallbackLanguage = "en"

        super.init()
    }

    override func didReceive(_ request: UNNotificationRequest,
                             withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent

        guard !DataProtectionManager.isDeviceInRebootedAndLockedState(containerURL: FileManager.default.appGroupContainerURL) else {
            contentHandler(request.content)
            return
        }
        guard let credentials = keychainController.restoreTokens().first else {
            // user not logged-in
            contentHandler(request.content)
            return
        }
        guard let roomId = request.content.userInfo[NotificationConstants.UserInfoKey.roomIdentifier] as? String,
              let eventId = request.content.userInfo[NotificationConstants.UserInfoKey.eventIdentifier] as? String else {
            // not a Matrix notification
            contentHandler(request.content)
            return
        }

        setupLogging()

        service = NotificationServiceProxy(basePath: FileManager.default.sessionsBaseDirectory.path,
                                           userId: credentials.userID)

        Task { @MainActor in
            guard let itemProxy = try await service?.getNotificationItem(roomId: roomId, eventId: eventId) else {
                contentHandler(request.content)
                return
            }
            if requiresMediaProxy(itemProxy: itemProxy) {
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
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    private func setupLogging() {
        guard !NotificationServiceExtension.isLoggerInitialized else {
            return
        }
        NotificationServiceExtension.isLoggerInitialized = true
        let configuration = MXLogConfiguration()
        configuration.subLogName = "nse"

        #if DEBUG
        // This exposes the full Rust side tracing subscriber filter for more flexibility.
        // We can filter by level, crate and even file. See more details here:
        // https://docs.rs/tracing-subscriber/0.2.7/tracing_subscriber/filter/struct.EnvFilter.html#examples
//        setupTracing(configuration: "warn,hyper=warn,sled=warn,matrix_sdk_sled=warn")
        configuration.logLevel = .debug
        #else
//        setupTracing(configuration: "info,hyper=warn,sled=warn,matrix_sdk_sled=warn")
        configuration.logLevel = .info
        #endif

        // Avoid redirecting NSLogs to files if we are attached to a debugger.
        if isatty(STDERR_FILENO) == 0 {
            configuration.redirectLogsToFiles = true
        }

        MXLog.configure(configuration)
    }

    private func requiresMediaProxy(itemProxy: NotificationItemProxy) -> Bool {
        if itemProxy.avatarUrl != nil {
            return true
        }
        switch itemProxy.timelineItemProxy {
        case .event(let eventItem):
            guard eventItem.isMessage || eventItem.isRedacted else {
                // To be handled in the future
                return false
            }
            guard let message = eventItem.content.asMessage() else {
                fatalError("Only handled messages")
            }
            switch message.msgtype() {
            case .image:
                return true
            default:
                return false
            }
        case .virtual:
            return false
        case .other:
            return false
        }
    }

    private func process(itemProxy: NotificationItemProxy,
                         roomId: String,
                         contentHandler: @escaping (UNNotificationContent) -> Void) {
        switch itemProxy.timelineItemProxy {
        case .event(let eventItem):
            guard eventItem.isMessage || eventItem.isRedacted else {
                // To be handled in the future
                contentHandler(UNMutableNotificationContent())
                return
            }
            guard let message = eventItem.content.asMessage() else {
                fatalError("Only handled messages")
            }
            process(itemProxy: itemProxy,
                    message: message,
                    senderId: eventItem.sender,
                    roomId: roomId,
                    contentHandler: contentHandler)
        case .virtual:
            contentHandler(UNMutableNotificationContent())
        case .other:
            contentHandler(UNMutableNotificationContent())
        }
    }

    private func process(itemProxy: NotificationItemProxy,
                         message: Message,
                         senderId: String,
                         roomId: String,
                         contentHandler: @escaping (UNNotificationContent) -> Void) {
        switch message.msgtype() {
        case .text(content: let content):
            let notification = UNMutableNotificationContent()
            notification.title = itemProxy.title
            if let subtitle = itemProxy.subtitle {
                notification.subtitle = subtitle
            }
            notification.threadIdentifier = roomId
            notification.body = content.body + " [modified]"
            notification.categoryIdentifier = NotificationConstants.Category.reply
            notification.sound = itemProxy.isNoisy ? UNNotificationSound(named: UNNotificationSoundName(rawValue: "message.caf")) : nil

            guard let avatarUrl = itemProxy.avatarUrl else {
                contentHandler(notification)
                return
            }

            addSenderIcon(to: notification,
                          senderId: senderId,
                          senderName: itemProxy.title,
                          mediaSource: .init(urlString: avatarUrl),
                          roomId: roomId,
                          contentHandler: contentHandler)
        case .image(content: let content):
            let notification = UNMutableNotificationContent()
            notification.title = itemProxy.title
            if let subtitle = itemProxy.subtitle {
                notification.subtitle = subtitle
            }
            notification.threadIdentifier = roomId
            notification.body = content.body + " [modified]"
            notification.categoryIdentifier = NotificationConstants.Category.reply
            notification.sound = itemProxy.isNoisy ? UNNotificationSound(named: UNNotificationSoundName(rawValue: "message.caf")) : nil

            guard let mediaProxy else {
                contentHandler(notification)
                return
            }

            let mediaSource = MediaSourceProxy(source: content.source)
            Task {
                do {
                    let data = try await mediaProxy.loadMediaContentForSource(mediaSource)

                    let attachment = try UNNotificationAttachment.saveImageToDisk(fileIdentifier: ProcessInfo.processInfo.globallyUniqueString,
                                                                                  data: data,
                                                                                  options: nil)
                    notification.attachments = [attachment]

                    guard let avatarUrl = itemProxy.avatarUrl else {
                        contentHandler(notification)
                        return
                    }

                    addSenderIcon(to: notification,
                                  senderId: senderId,
                                  senderName: itemProxy.title,
                                  mediaSource: .init(urlString: avatarUrl),
                                  roomId: roomId,
                                  contentHandler: contentHandler)
                } catch {
                    contentHandler(notification)
                    return
                }
            }
        case .notice(content: let content):
            let notification = UNMutableNotificationContent()
            notification.body = content.body
            contentHandler(notification)
        case .emote(content: let content):
            let notification = UNMutableNotificationContent()
            notification.body = content.body
            contentHandler(notification)
        case .none:
            contentHandler(UNMutableNotificationContent())
        }
    }

    private func addSenderIcon(to content: UNMutableNotificationContent,
                               senderId: String,
                               senderName: String,
                               mediaSource: MediaSourceProxy,
                               roomId: String,
                               contentHandler: @escaping (UNNotificationContent) -> Void) {
        guard let mediaProxy else {
            contentHandler(content)
            return
        }

        Task {
            do {
                let imageData = try await mediaProxy.loadMediaThumbnailForSource(mediaSource, width: 100, height: 100)

                // Initialize only the sender for a one-to-one message intent.
                let handle = INPersonHandle(value: senderId, type: .unknown)
                let sender = INPerson(personHandle: handle,
                                      nameComponents: nil,
                                      displayName: senderName,
                                      image: INImage(imageData: imageData),
                                      contactIdentifier: nil,
                                      customIdentifier: nil)

                // Because this communication is incoming, you can infer that the current user is
                // a recipient. Don't include the current user when initializing the intent.
                let intent = INSendMessageIntent(recipients: nil,
                                                 outgoingMessageType: .outgoingMessageText,
                                                 content: nil,
                                                 speakableGroupName: nil,
                                                 conversationIdentifier: roomId,
                                                 serviceName: nil,
                                                 sender: sender,
                                                 attachments: nil)

                // Use the intent to initialize the interaction.
                let interaction = INInteraction(intent: intent, response: nil)

                // Interaction direction is incoming because the user is
                // recieving this message.
                interaction.direction = .incoming

                // Donate the interaction before updating notification content.
                interaction.donate { error in
                    guard error == nil else {
                        // Handle errors that may occur during donation.
                        return contentHandler(content)
                    }

                    do {
                        // Update notification content before displaying the
                        // communication notification.
                        let updatedContent = try content.updating(from: intent)

                        // Call the content handler with the updated content
                        // to display the communication notification.
                        contentHandler(updatedContent)
                    } catch {
                        // Handle errors that may occur while updating content.
                        contentHandler(content)
                    }
                }
            } catch {
                contentHandler(content)
                return
            }
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
}

extension UNNotificationAttachment {
    static func saveImageToDisk(fileIdentifier: String,
                                data: Data,
                                options: [NSObject: AnyObject]? = nil) throws -> UNNotificationAttachment {
        let folderName = ProcessInfo.processInfo.globallyUniqueString
        guard let folderURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(folderName, isDirectory: true) else {
            fatalError("[NSE] Couldn't create folderURL")
        }

        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        let fileURL = folderURL.appendingPathComponent(fileIdentifier)
        try data.write(to: fileURL, options: [])
        return try UNNotificationAttachment(identifier: fileIdentifier,
                                            url: fileURL,
                                            options: options)
    }
}
