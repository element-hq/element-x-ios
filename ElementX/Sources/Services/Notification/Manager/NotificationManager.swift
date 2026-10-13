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

/// Handles the app's notifications: the APNs token, the permission, the system notification delegate and the app badge.
/// Each account's pusher and delivered notifications are handled by its ``NotificationService``.
final class NotificationManager: NSObject, NotificationManagerProtocol {
    private let notificationCenter: UserNotificationCenterProtocol
    private let appSettings: AppSettings
    private let sessionsPublisher: CurrentValuePublisher<[UserSessionProtocol], Never>
    
    /// The APNs token, kept for the accounts that go live after it arrived.
    private var deviceToken: Data?
    /// Keyed by service so that a session replaced after clearing the cache registers again.
    private var services: [ObjectIdentifier: NotificationServiceProtocol] = [:]
    private var serviceCancellables: [ObjectIdentifier: Set<AnyCancellable>] = [:]
    /// Each account's unread count, summed for the app badge.
    private var badgeCounts: [ObjectIdentifier: Int] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    private var isAnyAccountEnabled: Bool {
        services.values.contains { $0.isEnabledPublisher.value }
    }
    
    init(notificationCenter: UserNotificationCenterProtocol,
         appSettings: AppSettings,
         sessionsPublisher: CurrentValuePublisher<[UserSessionProtocol], Never>) {
        self.notificationCenter = notificationCenter
        self.appSettings = appSettings
        self.sessionsPublisher = sessionsPublisher
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
        
        sessionsPublisher
            .sink { [weak self] userSessions in
                self?.updateServices(userSessions.map(\.notificationService))
            }
            .store(in: &cancellables)
        
        Task {
            let settings = await notificationCenter.notificationSettings()
            MXLog.info("Notification sound enabled: \(settings.soundSetting == .enabled)")
        }
    }
    
    func requestAuthorization() {
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
    
    // MARK: - Private
    
    private func updateServices(_ notificationServices: [NotificationServiceProtocol]) {
        let newServices = Dictionary(notificationServices.map { (ObjectIdentifier($0), $0) }) { first, _ in first }
        let removedIDs = services.keys.filter { newServices[$0] == nil }
        let addedServices = newServices.filter { services[$0.key] == nil }
        services = newServices
        
        // Signing out of the last account unregisters from APNs, so the next account registers again.
        if services.isEmpty {
            deviceToken = nil
        }
        
        for id in removedIDs {
            serviceCancellables[id] = nil
            badgeCounts[id] = nil
        }
        if !removedIDs.isEmpty {
            updateAppBadgeCount()
        }
        
        for (id, service) in addedServices {
            observe(service, id: id)
        }
    }
    
    private func observe(_ service: NotificationServiceProtocol, id: ObjectIdentifier) {
        var cancellables = Set<AnyCancellable>()
        
        service.badgeCountPublisher
            .sink { [weak self] badgeCount in
                self?.badgeCounts[id] = badgeCount
                self?.updateAppBadgeCount()
            }
            .store(in: &cancellables)
        
        // Only turning notifications on asks for permission, the saved value doesn't.
        service.isEnabledPublisher
            .dropFirst()
            .filter { $0 }
            .sink { [weak self] _ in
                self?.requestAuthorization()
            }
            .store(in: &cancellables)
        
        serviceCancellables[id] = cancellables
        
        if let deviceToken {
            Task { await service.register(deviceToken: deviceToken) }
        } else {
            registerForRemoteNotificationsIfAuthorized()
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
        
        let badgeCount = badgeCounts.values.reduce(0, +)
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
