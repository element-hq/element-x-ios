//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import UserNotifications

protocol NotificationManagerDelegate: AnyObject {
    func shouldDisplayInAppNotification(content: UNNotificationContent) -> Bool
    func notificationTapped(content: UNNotificationContent) async
    func handleInlineReply(_ service: NotificationManagerProtocol,
                           content: UNNotificationContent,
                           replyText: String) async
    func registerForRemoteNotifications()
    func unregisterForRemoteNotifications()
}

// MARK: - NotificationManagerProtocol

// sourcery: AutoMockable
protocol NotificationManagerProtocol: AnyObject {
    var delegate: NotificationManagerDelegate? { get set }

    func start()
    func register(with deviceToken: Data) async -> Bool
    func registrationFailed(with error: Error)
    func showLocalNotification(with title: String, subtitle: String?) async
    func setUserSession(_ userSession: UserSessionProtocol?)
    
    func requestAuthorization()
    
    func removeDeliveredMessageNotifications(for roomID: String) async
    func removeDeliveredInviteNotifications() async
}
