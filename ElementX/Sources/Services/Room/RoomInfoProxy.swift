//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
    var isDirect: Bool { get }
    var isSpace: Bool { get }
}

struct RoomInfoProxy: BaseRoomInfoProxyProtocol {
    let roomInfo: RoomInfo
    
    var id: String { roomInfo.id }
    var creator: String? { roomInfo.creator }
    var displayName: String? { roomInfo.displayName }
    var rawName: String? { roomInfo.rawName }
    var topic: String? { roomInfo.topic }
    /// The room's avatar URL. Use this for editing and favour ``avatar`` for display.
    var avatarURL: URL? { roomInfo.avatarUrl.flatMap(URL.init) }
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
    var joinRule: JoinRule? { roomInfo.joinRule }
    var historyVisibility: RoomHistoryVisibility { roomInfo.historyVisibility }
    
    /// Find the first alias that matches the given homeserver
    /// - Parameters:
    ///   - serverName: the homserver in question
    ///   - useFallback: whether to return any alias if none match
    func firstAliasMatching(serverName: String?, useFallback: Bool) -> String? {
        guard let serverName else { return nil }
        
        // Check if the canonical alias matches the homeserver
        if let canonicalAlias = roomInfo.canonicalAlias,
           canonicalAlias.range(of: serverName) != nil {
            return canonicalAlias
        }
        
        // Otherwise check the alternative aliases and return the first one that matches
        if let matchingAlternativeAlias = roomInfo.alternativeAliases.filter({ $0.range(of: serverName) != nil }).first {
            return matchingAlternativeAlias
        }
        
        guard useFallback else {
            return nil
        }
        
        // Or just return the canonical alias if any
        if let canonicalAlias = roomInfo.canonicalAlias {
            return canonicalAlias
        }
        
        // And finally return whatever the first alternative alias is
        return roomInfo.alternativeAliases.first
    }
}

struct RoomPreviewInfoProxy: BaseRoomInfoProxyProtocol {
    let roomPreviewInfo: RoomPreviewInfo
    
    var id: String { roomPreviewInfo.roomId }
    var displayName: String? { roomPreviewInfo.name }
    var heroes: [RoomHero] { roomPreviewInfo.heroes ?? [] }
    var topic: String? { roomPreviewInfo.topic }
    var canonicalAlias: String? { roomPreviewInfo.canonicalAlias }
    var avatarURL: URL? { roomPreviewInfo.avatarUrl.flatMap(URL.init) }
    var isDirect: Bool { roomPreviewInfo.isDirect ?? false }
    var isSpace: Bool { roomPreviewInfo.roomType == .space }
    var activeMembersCount: Int { Int(roomPreviewInfo.numActiveMembers ?? roomPreviewInfo.numJoinedMembers) }
    
    /// The room's avatar info for use in a ``RoomAvatarImage``.
    var avatar: RoomAvatar {
        if isDirect, avatarURL == nil {
            if heroes.count == 1 {
                return .heroes(heroes.map(UserProfileProxy.init))
            }
        }
        
        return .room(id: id, name: displayName, avatarURL: avatarURL)
    }
}
