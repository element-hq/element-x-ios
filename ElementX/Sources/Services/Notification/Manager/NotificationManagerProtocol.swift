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
    func register(with deviceToken: Data) async
    func registrationFailed(with error: Error)
    func showLocalNotification(with title: String, subtitle: String?) async
    
    /// Starts handling a live account's notifications, replacing the service it had before (e.g. after clearing the cache).
    func add(_ service: NotificationServiceProtocol)
    func remove(userID: String)
    /// Resets the app badge and stops receiving notifications, once no account is signed in.
    func reset()
}
