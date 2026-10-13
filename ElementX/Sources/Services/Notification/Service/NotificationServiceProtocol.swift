//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

enum NotificationServiceError: Error {
    case failedUpdatingPusher
}

// sourcery: AutoMockable
protocol NotificationServiceProtocol: AnyObject {
    /// Whether this account's notifications are on, see `AccountSettings.enableNotifications`.
    var isEnabledPublisher: CurrentValuePublisher<Bool, Never> { get }
    /// This account's unread notification count, which the app badge sums across accounts.
    var badgeCountPublisher: CurrentValuePublisher<Int, Never> { get }
    
    /// Sets the pusher when notifications are on, otherwise deletes it.
    func register(deviceToken: Data) async
    /// Sets or deletes the pusher then saves the switch, which stays unchanged when the pusher can't be updated.
    func setEnabled(_ isEnabled: Bool) async -> Result<Void, NotificationServiceError>
    func removeDeliveredMessageNotifications(for roomID: String) async
    /// Deletes the pusher and this account's delivered notifications, before signing out.
    func tearDown() async
}
