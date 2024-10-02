//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import UserNotifications

extension UNNotificationRequest {
    var roomID: String? {
        content.userInfo[NotificationConstants.UserInfoKey.roomIdentifier] as? String
    }

    var eventID: String? {
        content.userInfo[NotificationConstants.UserInfoKey.eventIdentifier] as? String
    }

    var unreadCount: Int? {
        content.userInfo[NotificationConstants.UserInfoKey.unreadCount] as? Int
    }

    var pusherNotificationClientIdentifier: String? {
        content.userInfo[NotificationConstants.UserInfoKey.pusherNotificationClientIdentifier] as? String
    }
}
