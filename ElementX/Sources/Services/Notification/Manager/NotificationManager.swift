//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI
import UserNotifications

/// Handles the app's notifications: the notification center, the APNs token, the permission and the app badge.
/// Each live account's ``NotificationService`` decides what concerns its account and asks for it through actions.
final class NotificationManager: NSObject, NotificationManagerProtocol {
    private let notificationCenter: UserNotificationCenterProtocol
    private let appSettings: AppSettings
    
    /// The APNs token, kept for the accounts added after it arrived.
    private var deviceToken: Data?
    private var services: [String: NotificationServiceProtocol] = [:]
    private var serviceCancellables: [String: Set<AnyCancellable>] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    private var isAnyAccountEnabled: Bool {
        services.values.contains { $0.isEnabled }
    }
    
    init(notificationCenter: UserNotificationCenterProtocol, appSettings: AppSettings) {
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
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.removeReceivedWhileOfflineNotification()
            }
            .store(in: &cancellables)
        
        Task {
            let settings = await notificationCenter.notificationSettings()
            MXLog.info("Notification sound enabled: \(settings.soundSetting == .enabled)")
        }
    }
    
    func register(with deviceToken: Data) async {
        self.deviceToken = deviceToken
        for service in services.values {
            await service.register(deviceToken: deviceToken)
        }
    }
    
    func registrationFailed(with error: Error) {
        MXLog.error("Device token registration failed with error: \(error)")
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
            MXLog.info("Show local notification succeeded")
        } catch {
            MXLog.error("Show local notification failed: \(error)")
        }
    }
    
    func add(_ service: NotificationServiceProtocol) {
        let userID = service.userID
        services[userID] = service
        serviceCancellables[userID] = [
            service.actionsPublisher.sink { [weak self] action in
                self?.process(action, from: userID)
            },
            service.badgeCountPublisher.sink { [weak self] _ in
                self?.updateAppBadgeCount()
            }
        ]
        
        if let deviceToken {
            Task { await service.register(deviceToken: deviceToken) }
        } else {
            registerForRemoteNotificationsIfAuthorized()
        }
    }
    
    func remove(userID: String) {
        serviceCancellables[userID] = nil
        guard services.removeValue(forKey: userID) != nil else { return }
        
        if services.isEmpty {
            // Signing out of the last account unregisters from APNs, so the next account registers again.
            deviceToken = nil
        } else {
            updateAppBadgeCount()
        }
    }
    
    func reset() {
        appSettings.lastKnownBadgeCount = 0
        Task {
            do {
                try await notificationCenter.setBadgeCount(0)
            } catch {
                MXLog.error("Failed resetting the app badge count with error: \(error)")
            }
        }
        delegate?.unregisterForRemoteNotifications()
    }
    
    // MARK: - Private
    
    private func process(_ action: NotificationServiceAction, from userID: String) {
        switch action {
        case .removeDeliveredNotifications(let isIncluded):
            Task { await removeDeliveredNotifications(of: userID, where: isIncluded) }
        case .requestAuthorization:
            requestAuthorization()
        }
    }
    
    private func requestAuthorization() {
        guard isAnyAccountEnabled else { return }
        Task {
            do {
                let permissionGranted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
                MXLog.info("Permission granted: \(permissionGranted)")
                if permissionGranted {
                    delegate?.registerForRemoteNotifications()
                }
            } catch {
                MXLog.error("Request authorization failed: \(error)")
            }
        }
    }
    
    /// Registers again when permission was given before, otherwise the onboarding flow asks for it.
    /// Accounts that are turned off need the token too, to delete any pusher left on their homeserver.
    private func registerForRemoteNotificationsIfAuthorized() {
        Task {
            guard await notificationCenter.authorizationStatus() == .authorized else { return }
            delegate?.registerForRemoteNotifications()
        }
    }
    
    private func updateAppBadgeCount() {
        // Signing out of the last account resets the badge.
        guard !services.isEmpty else { return }
        
        let badgeCount = services.values.map(\.badgeCountPublisher.value).reduce(0, +)
        appSettings.lastKnownBadgeCount = badgeCount
        MXLog.debug("Updating app badge count to \(badgeCount)")
        
        Task {
            do {
                try await notificationCenter.setBadgeCount(badgeCount)
            } catch {
                MXLog.error("Failed updating the app badge count with error: \(error)")
            }
        }
    }
    
    private func removeDeliveredNotifications(of userID: String, where isIncluded: (UNNotification) -> Bool) async {
        let identifiers = await notificationCenter.deliveredNotifications()
            // A room can be shared by several accounts. Notifications without a receiver weren't processed by the extension, so any account may clear them.
            .filter { ($0.request.content.receiverID ?? userID) == userID }
            .filter(isIncluded)
            .map(\.request.identifier)
        guard !identifiers.isEmpty else { return }
        
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    private func removeReceivedWhileOfflineNotification() {
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [NotificationServiceExtensionActor.receivedWhileOfflineNotificationID])
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        guard let delegate else {
            return [.badge, .sound, .list, .banner]
        }
        
        guard delegate.shouldDisplayInAppNotification(content: notification.request.content) else {
            return []
        }
        
        return [.badge, .sound, .list, .banner]
    }
    
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
