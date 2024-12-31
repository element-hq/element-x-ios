//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import UIKit
import UserNotifications

final class NotificationManager: NSObject, NotificationManagerProtocol {
    private let notificationCenter: UserNotificationCenterProtocol
    private let appSettings: AppSettings
    
    private var userSession: UserSessionProtocol?
    
    private var cancellables = Set<AnyCancellable>()
    private var notificationsEnabled = false
    
    init(notificationCenter: UserNotificationCenterProtocol,
         appSettings: AppSettings) {
        self.notificationCenter = notificationCenter
        self.appSettings = appSettings
        super.init()
    }

    // MARK: NotificationManagerProtocol

    weak var delegate: NotificationManagerDelegate?
    
    func start() {
        let replyAction = UNTextInputNotificationAction(identifier: NotificationConstants.Action.inlineReply,
                                                        title: L10n.actionQuickReply,
                                                        options: [])
        let messageCategory = UNNotificationCategory(identifier: NotificationConstants.Category.message,
                                                     actions: [replyAction],
                                                     intentIdentifiers: [],
                                                     options: [])
        
        let inviteCategory = UNNotificationCategory(identifier: NotificationConstants.Category.invite,
                                                    actions: [],
                                                    intentIdentifiers: [],
                                                    options: [])
        notificationCenter.setNotificationCategories([messageCategory, inviteCategory])
        notificationCenter.delegate = self
        
        notificationsEnabled = appSettings.enableNotifications
        MXLog.info("[NotificationManager] app setting 'enableNotifications' is '\(notificationsEnabled)'")
        
        // Listen for changes to AppSettings.enableNotifications
        appSettings.$enableNotifications
            .sink { [weak self] newValue in
                self?.enableNotifications(newValue)
            }
            .store(in: &cancellables)
    }
        
    func requestAuthorization() {
        guard appSettings.enableNotifications, !userSession.isNil else { return }
        Task {
            do {
                let permissionGranted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
                MXLog.info("[NotificationManager] permission granted: \(permissionGranted)")
                await MainActor.run {
                    if permissionGranted {
                        self.delegate?.registerForRemoteNotifications()
                    }
                }
            } catch {
                MXLog.error("[NotificationManager] request authorization failed: \(error)")
            }
        }
    }

    func register(with deviceToken: Data) async -> Bool {
        guard let userSession else {
            return false
        }
        return await setPusher(with: deviceToken, clientProxy: userSession.clientProxy)
    }

    func setUserSession(_ userSession: UserSessionProtocol?) {
        self.userSession = userSession
        
        // If notification permissions were given previously then attempt re-registering
        // for remote notifications on startup. Otherwise let the onboarding flow handle it
        Task { [weak self] in
            guard let self else { return }
            
            if await notificationCenter.authorizationStatus() == .authorized, appSettings.enableNotifications {
                await MainActor.run { [weak self] in
                    self?.delegate?.registerForRemoteNotifications()
                }
            }
        }
    }

    func registrationFailed(with error: Error) {
        MXLog.error("[NotificationManager] device token registration failed with error: \(error)")
    }

    func showLocalNotification(with title: String, subtitle: String?) async {
        let content = UNMutableNotificationContent()
        content.title = title
        if let subtitle {
            content.subtitle = subtitle
        }
        let request = UNNotificationRequest(identifier: ProcessInfo.processInfo.globallyUniqueString,
                                            content: content,
                                            trigger: nil)
        do {
            try await notificationCenter.add(request)
            MXLog.info("[NotificationManager] show local notification succeeded")
        } catch {
            MXLog.error("[NotificationManager] show local notification failed: \(error)")
        }
    }
    
    func removeDeliveredMessageNotifications(for roomID: String) async {
        let notificationsIdentifiers = await notificationCenter
            .deliveredNotifications()
            .filter { $0.request.content.roomID == roomID }
            .map(\.request.identifier)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: notificationsIdentifiers)
    }

    func removeDeliveredInviteNotifications() async {
        let notificationsIdentifiers = await notificationCenter
            .deliveredNotifications()
            .filter { $0.request.content.categoryIdentifier == NotificationConstants.Category.invite }
            .map(\.request.identifier)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: notificationsIdentifiers)
    }
    
    private func setPusher(with deviceToken: Data, clientProxy: ClientProxyProtocol) async -> Bool {
        do {
            let defaultPayload = APNSPayload(aps: APSInfo(mutableContent: 1,
                                                          alert: APSAlert(locKey: "Notification",
                                                                          locArgs: [])),
                                             pusherNotificationClientIdentifier: clientProxy.pusherNotificationClientIdentifier)

            let configuration = try await PusherConfiguration(identifiers: .init(pushkey: deviceToken.base64EncodedString(),
                                                                                 appId: appSettings.pusherAppId),
                                                              kind: .http(data: .init(url: appSettings.pushGatewayBaseURL.absoluteString,
                                                                                      format: .eventIdOnly,
                                                                                      defaultPayload: defaultPayload.toJsonString())),
                                                              appDisplayName: "\(InfoPlistReader.main.bundleDisplayName) (iOS)",
                                                              deviceDisplayName: UIDevice.current.name,
                                                              profileTag: pusherProfileTag(),
                                                              lang: Bundle.app.preferredLocalizations.first ?? "en")
            try await clientProxy.setPusher(with: configuration)
            MXLog.info("[NotificationManager] set pusher succeeded")
            return true
        } catch {
            MXLog.error("[NotificationManager] set pusher failed: \(error)")
            return false
        }
    }

    private func pusherProfileTag() -> String {
        if let currentTag = appSettings.pusherProfileTag {
            return currentTag
        }
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        let newTag = (0..<16).map { _ in
            let offset = Int.random(in: 0..<chars.count)
            return String(chars[chars.index(chars.startIndex, offsetBy: offset)])
        }.joined()

        appSettings.pusherProfileTag = newTag
        return newTag
    }
    
    private func enableNotifications(_ enable: Bool) {
        guard notificationsEnabled != enable else { return }
        notificationsEnabled = enable
        MXLog.info("[NotificationManager] app setting 'enableNotifications' changed to '\(enable)'")
        if enable {
            requestAuthorization()
        } else {
            delegate?.unregisterForRemoteNotifications()
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        guard appSettings.enableInAppNotifications else {
            return []
        }
        guard let delegate else {
            return [.badge, .sound, .list, .banner]
        }

        guard delegate.shouldDisplayInAppNotification(content: notification.request.content) else {
            return []
        }

        return [.badge, .sound, .list, .banner]
    }

    @MainActor
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        switch response.actionIdentifier {
        case NotificationConstants.Action.inlineReply:
            guard let response = response as? UNTextInputNotificationResponse else {
                return
            }
            await delegate?.handleInlineReply(self,
                                              content: response.notification.request.content,
                                              replyText: response.userText)
        case UNNotificationDefaultActionIdentifier:
            await delegate?.notificationTapped(content: response.notification.request.content)
        default:
            break
        }
    }
}

extension UNUserNotificationCenter: UserNotificationCenterProtocol { }
