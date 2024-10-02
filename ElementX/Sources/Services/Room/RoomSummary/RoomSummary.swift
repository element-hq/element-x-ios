//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct RoomSummary {
    let roomListItem: RoomListItem
    
    let id: String
    
    let isInvite: Bool
    let inviter: RoomMemberProxyProtocol?
    
    let name: String
    let isDirect: Bool
    let avatarURL: URL?
    let heroes: [UserProfileProxy]
    let lastMessage: AttributedString?
    let lastMessageFormattedTimestamp: String?
    let unreadMessagesCount: UInt
    let unreadMentionsCount: UInt
    let unreadNotificationsCount: UInt
    let notificationMode: RoomNotificationModeProxy?
    let canonicalAlias: String?
    
    let hasOngoingCall: Bool
    
    let isMarkedUnread: Bool
    let isFavourite: Bool
    
    var hasUnreadMessages: Bool { unreadMessagesCount > 0 }
    var hasUnreadMentions: Bool { unreadMentionsCount > 0 }
    var hasUnreadNotifications: Bool { unreadNotificationsCount > 0 }
    var isMuted: Bool { notificationMode == .mute }
}

extension RoomSummary: CustomStringConvertible {
    var description: String { """
    RoomSummary: - id: \(id) \
    - isDirect: \(isDirect) \
    - unreadMessagesCount: \(unreadMessagesCount) \
    - unreadMentionsCount: \(unreadMentionsCount) \
    - unreadNotificationsCount: \(unreadNotificationsCount) \
    - notificationMode: \(notificationMode?.rawValue ?? "nil")
    """
    }
}

extension RoomSummary {
    init(roomListItem: RoomListItem, id: String, settingsMode: RoomNotificationModeProxy, hasUnreadMessages: Bool, hasUnreadMentions: Bool, hasUnreadNotifications: Bool) {
        self.roomListItem = roomListItem
        self.id = id
        let string = "\(settingsMode) - messages: \(hasUnreadMessages) - mentions: \(hasUnreadMentions) - notifications: \(hasUnreadNotifications)"
        name = string
        isDirect = true
        avatarURL = nil
        heroes = []
        lastMessage = AttributedString(string)
        lastMessageFormattedTimestamp = "Now"
        unreadMessagesCount = hasUnreadMessages ? 1 : 0
        unreadMentionsCount = hasUnreadMentions ? 1 : 0
        unreadNotificationsCount = hasUnreadNotifications ? 1 : 0
        notificationMode = settingsMode
        canonicalAlias = nil
        inviter = nil
        hasOngoingCall = false
        
        isInvite = false
        isMarkedUnread = false
        isFavourite = false
    }
    
    var avatar: RoomAvatar {
        if isDirect, avatarURL == nil, heroes.count == 1 {
            .heroes(heroes)
        } else {
            .room(id: id, name: name, avatarURL: avatarURL)
        }
    }
}
