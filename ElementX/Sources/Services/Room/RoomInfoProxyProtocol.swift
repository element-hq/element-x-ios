//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

protocol BaseRoomInfoProxyProtocol {
    var id: String { get }
    var displayName: String? { get }
    var topic: String? { get }
    var canonicalAlias: String? { get }
    var avatarURL: URL? { get }
    var activeMembersCount: Int { get }
    var joinedMembersCount: Int { get }
    var isDirect: Bool { get }
    var isSpace: Bool { get }
    
    var successor: SuccessorRoom? { get }
    var heroes: [RoomHero] { get }
}

// sourcery: AutoMockable
protocol RoomInfoProxyProtocol: BaseRoomInfoProxyProtocol {
    var id: String { get }
    var creators: [String] { get }
    var displayName: String? { get }
    var rawName: String? { get }
    var topic: String? { get }
    /// The room's avatar URL. Use this for editing and favour ``avatar`` for display.
    var avatarURL: URL? { get }

    var isEncrypted: Bool { get }
    var isDirect: Bool { get }
    var isSpace: Bool { get }
    var isFavourite: Bool { get }
    
    var canonicalAlias: String? { get }
    var alternativeAliases: [String] { get }
    var membership: Membership { get }
    var inviter: RoomMemberProxyProtocol? { get }
    
    var activeMembersCount: Int { get }
    var invitedMembersCount: Int { get }
    var joinedMembersCount: Int { get }
    var highlightCount: Int { get }
    var notificationCount: Int { get }
    var cachedUserDefinedNotificationMode: RoomNotificationMode? { get }
    var hasRoomCall: Bool { get }
    var activeRoomCallParticipants: [String] { get }
    var isMarkedUnread: Bool { get }
    var unreadMessagesCount: UInt { get }
    var unreadNotificationsCount: UInt { get }
    var unreadMentionsCount: UInt { get }
    var pinnedEventIDs: Set<String> { get }
    var joinRule: JoinRule? { get }
    var historyVisibility: RoomHistoryVisibility { get }
    
    var powerLevels: RoomPowerLevelsProxyProtocol? { get }
}

extension BaseRoomInfoProxyProtocol {
    /// The room's avatar info for use in a ``RoomAvatarImage``.
    var avatar: RoomAvatar {
        guard successor == nil else {
            return .tombstoned
        }
        
        if isSpace {
            return .space(id: id, name: displayName, avatarURL: avatarURL)
        }
        
        if isDirect, avatarURL == nil, heroes.count == 1 {
            return .heroes(heroes.map(UserProfileProxy.init))
        }
        
        return .room(id: id, name: displayName, avatarURL: avatarURL)
    }
}

extension RoomInfoProxyProtocol {
    /// A room might be non public but also not private given the fact that the join rule might be missing or unsupported.
    var isPrivate: Bool? {
        guard let joinRule else {
            return nil
        }
        
        return switch joinRule {
        case .invite, .knock, .restricted, .knockRestricted:
            true
        case .public:
            false
        case .custom: // We don't know how to handle this
            nil
        }
    }
    
    /// Checks if the other person left the room in a direct chat
    var isUserAloneInDirectRoom: Bool {
        isDirect && activeMembersCount == 1
    }
    
    /// Find the first alias that matches the given homeserver
    /// - Parameters:
    ///   - serverName: the homserver in question
    ///   - useFallback: whether to return any alias if none match
    func firstAliasMatching(serverName: String?, useFallback: Bool) -> String? {
        guard let serverName else { return nil }
        
        // Check if the canonical alias matches the homeserver
        if let canonicalAlias,
           canonicalAlias.range(of: serverName) != nil {
            return canonicalAlias
        }
        
        // Otherwise check the alternative aliases and return the first one that matches
        if let matchingAlternativeAlias = alternativeAliases.filter({ $0.range(of: serverName) != nil }).first {
            return matchingAlternativeAlias
        }
        
        guard useFallback else {
            return nil
        }
        
        // Or just return the canonical alias if any
        if let canonicalAlias {
            return canonicalAlias
        }
        
        // And finally return whatever the first alternative alias is
        return alternativeAliases.first
    }
    
    /// If present, the state of history sharing in this room. This *does not* consider the `enableKeyShareOnInvite`
    /// feature flag, so consumers should be careful to check the flag is true before utilising this property.
    var historySharingState: RoomHistorySharingState? {
        guard isEncrypted else {
            return nil
        }
        return switch historyVisibility {
        case .shared:
            .shared
        case .worldReadable:
            .worldReadable
        default:
            nil
        }
    }
}
