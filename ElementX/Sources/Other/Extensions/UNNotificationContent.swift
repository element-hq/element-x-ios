//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UserNotifications

extension UNNotificationContent {
    @objc var receiverID: String? {
        userInfo[NotificationConstants.UserInfoKey.receiverIdentifier] as? String
    }

    @objc var roomID: String? {
        userInfo[NotificationConstants.UserInfoKey.roomIdentifier] as? String
    }
    
    @objc var eventID: String? {
        userInfo[NotificationConstants.UserInfoKey.eventIdentifier] as? String
    }

    @objc var pusherNotificationClientIdentifier: String? {
        userInfo[NotificationConstants.UserInfoKey.pusherNotificationClientIdentifier] as? String
    }
}

extension UNMutableNotificationContent {
    override var receiverID: String? {
        get {
            userInfo[NotificationConstants.UserInfoKey.receiverIdentifier] as? String
        }
        set {
            userInfo[NotificationConstants.UserInfoKey.receiverIdentifier] = newValue
        }
    }

    override var roomID: String? {
        get {
            userInfo[NotificationConstants.UserInfoKey.roomIdentifier] as? String
        }
        set {
            userInfo[NotificationConstants.UserInfoKey.roomIdentifier] = newValue
        }
    }
    
    override var eventID: String? {
        get {
            userInfo[NotificationConstants.UserInfoKey.eventIdentifier] as? String
        }
        set {
            userInfo[NotificationConstants.UserInfoKey.eventIdentifier] = newValue
        }
    }
    
    var unreadCount: Int? {
        userInfo[NotificationConstants.UserInfoKey.unreadCount] as? Int
    }
}
