//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import UserNotifications

/// What an account's service asks of the `NotificationManager`, which owns the notification center.
enum NotificationServiceAction {
    /// Removes the account's delivered notifications that match.
    case removeDeliveredNotifications(where: (UNNotification) -> Bool)
    case requestAuthorization
}

// sourcery: AutoMockable
protocol NotificationServiceProtocol: AnyObject {
    var userID: String { get }
    var actionsPublisher: AnyPublisher<NotificationServiceAction, Never> { get }
    
    /// Whether this account's notifications are on, see `AccountSettings.enableNotifications`.
    var isEnabled: Bool { get }
    /// This account's unread notification count.
    var badgeCountPublisher: CurrentValuePublisher<Int, Never> { get }
    
    /// Sets the pusher when notifications are on, otherwise deletes it. The pusher follows the switch from then on.
    func register(deviceToken: Data) async
    func requestAuthorization()
    func removeDeliveredMessageNotifications(for roomID: String)
    /// Deletes the pusher and this account's delivered notifications, before signing out.
    func tearDown() async
}
