//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

protocol BaseRoomInfoProxyProtocol {
    var id: String { get }
    var displayName: String? { get }
    var avatar: RoomAvatar { get }
    var topic: String? { get }
    var canonicalAlias: String? { get }
    var avatarURL: URL? { get }
    var activeMembersCount: Int { get }
}

struct RoomInfoProxy: BaseRoomInfoProxyProtocol {
    let roomInfo: RoomInfo
    let roomAvatarCached: String?
    
    var id: String { roomInfo.id }
    var creator: String? { roomInfo.creator }
    var displayName: String? { roomInfo.displayName }
    var rawName: String? { roomInfo.rawName }
    var topic: String? { roomInfo.topic }
    /// The room's avatar URL. Use this for editing and favour ``avatar`` for display.
    var avatarURL: URL? {
        // roomInfo.avatarUrl.flatMap(URL.init)
        roomAvatarCached.flatMap(URL.init) ?? roomInfo.avatarUrl.flatMap(URL.init)
    }
    /// The room's avatar info for use in a ``RoomAvatarImage``.
    var avatar: RoomAvatar {
        if isDirect, avatarURL == nil {
            if heroes.count == 1 {
                return .heroes(heroes.map(UserProfileProxy.init))
            }
        }
        
        return .room(id: id, name: displayName, avatarURL: avatarURL)
    }

    var isDirect: Bool { roomInfo.isDirect }
    var isPublic: Bool { roomInfo.isPublic }
    var isSpace: Bool { roomInfo.isSpace }
    var isTombstoned: Bool { roomInfo.isTombstoned }
    var isFavourite: Bool { roomInfo.isFavourite }
    var canonicalAlias: String? { roomInfo.canonicalAlias }
    var alternativeAliases: [String] { roomInfo.alternativeAliases }
    var membership: Membership { roomInfo.membership }
    var inviter: RoomMemberProxy? { roomInfo.inviter.map(RoomMemberProxy.init) }
    var heroes: [RoomHero] { roomInfo.heroes }
    var activeMembersCount: Int { Int(roomInfo.activeMembersCount) }
    var invitedMembersCount: Int { Int(roomInfo.invitedMembersCount) }
    var joinedMembersCount: Int { Int(roomInfo.joinedMembersCount) }
    var userPowerLevels: [String: Int] { roomInfo.userPowerLevels.mapValues(Int.init) }
    var highlightCount: Int { Int(roomInfo.highlightCount) }
    var notificationCount: Int { Int(roomInfo.notificationCount) }
    var cachedUserDefinedNotificationMode: RoomNotificationMode? { roomInfo.cachedUserDefinedNotificationMode }
    var hasRoomCall: Bool { roomInfo.hasRoomCall }
    var activeRoomCallParticipants: [String] { roomInfo.activeRoomCallParticipants }
    var isMarkedUnread: Bool { roomInfo.isMarkedUnread }
    var unreadMessagesCount: UInt { UInt(roomInfo.numUnreadMessages) }
    var unreadNotificationsCount: UInt { UInt(roomInfo.numUnreadNotifications) }
    var unreadMentionsCount: UInt { UInt(roomInfo.numUnreadMentions) }
    var pinnedEventIDs: Set<String> { Set(roomInfo.pinnedEventIds) }
}

struct RoomPreviewInfoProxy: BaseRoomInfoProxyProtocol {
    let roomPreviewInfo: RoomPreviewInfo
    let roomAvatarCached: String?
    
    var id: String { roomPreviewInfo.roomId }
    var displayName: String? { roomPreviewInfo.name }
    var avatar: RoomAvatar {
        .room(id: id, name: displayName, avatarURL: avatarURL)
    }

    var topic: String? { roomPreviewInfo.topic }
    var canonicalAlias: String? { roomPreviewInfo.canonicalAlias }
    var avatarURL: URL? {
        //roomPreviewInfo.avatarUrl.flatMap(URL.init)
        roomAvatarCached.flatMap(URL.init) ?? roomPreviewInfo.avatarUrl.flatMap(URL.init)
    }
    var activeMembersCount: Int { Int(roomPreviewInfo.numJoinedMembers) }
}
