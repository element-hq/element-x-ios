//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UserNotifications

protocol NotificationManagerDelegate: AnyObject {
    func shouldDisplayInAppNotification(content: UNNotificationContent) -> Bool
    /// - Parameter isNewestInRoom: Whether no other delivered notification for the same room is more recent.
    func notificationTapped(content: UNNotificationContent, isNewestInRoom: Bool) async
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
    
    func removeDeliveredNotificationsForFullyReadRooms(_ rooms: [RoomSummary]) async
    
    func updateAppBadgeCount() async
}
