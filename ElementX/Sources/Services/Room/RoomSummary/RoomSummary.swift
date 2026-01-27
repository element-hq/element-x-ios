//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

/// A quick summary of a Room, useful to describe and give quick informations for the room list
struct RoomSummary {
    enum JoinRequestType {
        case invite(inviter: RoomMemberProxyProtocol?)
        case knock
        
        var isInvite: Bool {
            switch self {
            case .invite: true
            default: false
            }
        }
        
        var isKnock: Bool {
            switch self {
            case .knock: true
            default: false
            }
        }
    }
    
    enum LastMessageState { case sending, failed }

    let room: Room
    
    let id: String
    
    let joinRequestType: JoinRequestType?
    
    let name: String
    let isDirect: Bool
    let isSpace: Bool
    let avatarURL: URL?
    
    let heroes: [UserProfileProxy]
    let activeMembersCount: UInt
    
    let lastMessage: AttributedString?
    let lastMessageDate: Date?
    let lastMessageState: LastMessageState?
    let unreadMessagesCount: UInt
    let unreadMentionsCount: UInt
    let unreadNotificationsCount: UInt
    let notificationMode: RoomNotificationModeProxy?
    let canonicalAlias: String?
    let alternativeAliases: Set<String>
    
    let hasOngoingCall: Bool
    
    let isMarkedUnread: Bool
    let isFavourite: Bool
    let isTombstoned: Bool
    
    var hasUnreadMessages: Bool {
        unreadMessagesCount > 0
    }

    var hasUnreadMentions: Bool {
        unreadMentionsCount > 0
    }

    var hasUnreadNotifications: Bool {
        unreadNotificationsCount > 0
    }

    var isMuted: Bool {
        notificationMode == .mute
    }
}

extension RoomSummary: CustomStringConvertible {
    var description: String {
        """
        RoomSummary: - id: \(id) \
        - isDirect: \(isDirect) \
        - unreadMessagesCount: \(unreadMessagesCount) \
        - unreadMentionsCount: \(unreadMentionsCount) \
        - unreadNotificationsCount: \(unreadNotificationsCount) \
        - notificationMode: \(notificationMode?.rawValue ?? "nil")
        """
    }
    
    /// Used where summaries are shown in a list e.g. message forwarding,
    /// global search, share destination list etc.
    var roomListDescription: String {
        if isDirect {
            return canonicalAlias ?? ""
        }
        
        if let alias = canonicalAlias {
            return alias
        }
        
        guard heroes.count > 0 else {
            return ""
        }
        
        var heroComponents = heroes.compactMap(\.displayName)
        
        let othersCount = Int(activeMembersCount) - heroes.count
        if othersCount > 0 {
            heroComponents.append(L10n.commonManyMembers(othersCount))
        }
        
        return heroComponents.formatted(.list(type: .and))
    }
}

extension RoomSummary {
    init(room: Room, id: String, settingsMode: RoomNotificationModeProxy, hasUnreadMessages: Bool, hasUnreadMentions: Bool, hasUnreadNotifications: Bool) {
        self.room = room
        self.id = id
        let string = "\(settingsMode) - messages: \(hasUnreadMessages) - mentions: \(hasUnreadMentions) - notifications: \(hasUnreadNotifications)"
        name = string
        isDirect = true
        isSpace = false
        avatarURL = nil
        
        heroes = []
        activeMembersCount = 0
        
        lastMessage = AttributedString(string)
        lastMessageDate = .mock
        lastMessageState = nil
        unreadMessagesCount = hasUnreadMessages ? 1 : 0
        unreadMentionsCount = hasUnreadMentions ? 1 : 0
        unreadNotificationsCount = hasUnreadNotifications ? 1 : 0
        notificationMode = settingsMode
        canonicalAlias = nil
        alternativeAliases = []
        hasOngoingCall = false
        
        joinRequestType = nil
        isMarkedUnread = false
        isFavourite = false
        isTombstoned = false
    }
    
    /// This doesn't have to work properly for DM invites, the heroes are always empty
    var avatar: RoomAvatar {
        guard !isTombstoned else {
            return .tombstoned
        }
        
        if isSpace {
            return .space(id: id, name: name, avatarURL: avatarURL)
        } else if isDirect, avatarURL == nil, heroes.count == 1 {
            return .heroes(heroes)
        } else {
            return .room(id: id, name: name, avatarURL: avatarURL)
        }
    }
}
