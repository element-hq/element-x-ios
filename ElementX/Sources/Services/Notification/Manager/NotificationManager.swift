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

import Foundation
import UIKit
import UserNotifications

class NotificationManager: NSObject, NotificationManagerProtocol {
    private let notificationCenter = UNUserNotificationCenter.current()
    private let clientProxy: ClientProxyProtocol

    init(clientProxy: ClientProxyProtocol) {
        self.clientProxy = clientProxy
        super.init()
    }

    // MARK: NotificationManagerProtocol

    weak var delegate: NotificationManagerDelegate?

    var isAvailable: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        true
        #endif
    }

    func start() {
        let replyAction = UNTextInputNotificationAction(identifier: NotificationConstants.Action.inlineReply,
                                                        title: ElementL10n.actionQuickReply,
                                                        options: [])
        let replyCategory = UNNotificationCategory(identifier: NotificationConstants.Category.reply,
                                                   actions: [replyAction],
                                                   intentIdentifiers: [],
                                                   options: [])
        notificationCenter.setNotificationCategories([replyCategory])
        notificationCenter.delegate = self
        Task {
            do {
                let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
                MXLog.debug("[NotificationManager] permission granted: \(granted)")

                await MainActor.run {
                    delegate?.authorizationStatusUpdated(self, granted: granted)
                }
            } catch {
                MXLog.debug("[NotificationManager] request authorization failed: \(error)")
            }
        }
    }

    func register(with deviceToken: Data) {
        setPusher(with: deviceToken, clientProxy: clientProxy)
    }

    func registrationFailed(with error: Error) { }

    private func setPusher(with deviceToken: Data, clientProxy: ClientProxyProtocol) {
        Task {
            do {
                try await clientProxy.setPusher(pushkey: deviceToken.base64EncodedString(),
                                                kind: .http,
                                                appId: BuildSettings.pusherAppId,
                                                appDisplayName: "\(InfoPlistReader.target.bundleDisplayName) (iOS)",
                                                deviceDisplayName: UIDevice.current.name,
                                                profileTag: pusherProfileTag(),
                                                lang: Bundle.preferredLanguages.first ?? "en",
                                                url: BuildSettings.pushGatewayBaseURL.absoluteString,
                                                format: .eventIdOnly,
                                                defaultPayload: [
                                                    "aps": [
                                                        "mutable-content": 1,
                                                        "alert": [
                                                            "loc-key": "Notification",
                                                            "loc-args": []
                                                        ]
                                                    ]
                                                ])
                MXLog.debug("[NotificationManager] set pusher succeeded")
            } catch {
                MXLog.debug("[NotificationManager] set pusher failed: \(error)")
            }
        }
    }

    private func pusherProfileTag() -> String {
        if let currentTag = ElementSettings.shared.pusherProfileTag {
            return currentTag
        }
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        let newTag = (0..<16).map { _ in
            let offset = Int.random(in: 0..<chars.count)
            return String(chars[chars.index(chars.startIndex, offsetBy: offset)])
        }.joined()

        ElementSettings.shared.pusherProfileTag = newTag
        return newTag
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        guard ElementSettings.shared.enableInAppNotifications else {
            return completionHandler([])
        }
        guard let delegate else {
            return completionHandler([.badge, .sound, .list, .banner])
        }

        guard delegate.shouldDisplayInAppNotification(self, content: notification.request.content) else {
            return completionHandler([])
        }

        completionHandler([.badge, .sound, .list, .banner])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case NotificationConstants.Action.inlineReply:
            guard let response = response as? UNTextInputNotificationResponse else {
                return
            }
            delegate?.handleInlineReply(self,
                                        content: response.notification.request.content,
                                        replyText: response.userText,
                                        completionHandler: completionHandler)
        case UNNotificationDefaultActionIdentifier:
            delegate?.notificationTapped(self,
                                         content: response.notification.request.content,
                                         completionHandler: completionHandler)
        default:
            break
        }
    }
}
