//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum NotificationConstants {
    enum UserInfoKey {
        static let roomIdentifier = "room_id"
        static let eventIdentifier = "event_id"
        static let unreadCount = "unread_count"
        static let pusherNotificationClientIdentifier = "pusher_notification_client_identifier"
        static let receiverIdentifier = "receiver_id"
    }

    enum Category {
        static let message = "message"
        static let invite = "invite"
    }

    enum Action {
        static let inlineReply = "inline-reply"
    }
}
