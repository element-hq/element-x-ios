//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct RoomInfoProxy: RoomInfoProxyProtocol {
    let roomInfo: RoomInfo
    
    var id: String {
        roomInfo.id
    }

    var creators: [String] {
        roomInfo.creators ?? []
    }

    var displayName: String? {
        roomInfo.displayName
    }

    var rawName: String? {
        roomInfo.rawName
    }

    var topic: String? {
        roomInfo.topic
    }

    /// The room's avatar URL. Use this for editing and favour ``avatar`` for display.
    var avatarURL: URL? {
        roomInfo.avatarUrl.flatMap(URL.init)
    }

    /// Here we're assuming unknown rooms are unencrypted.
    /// Fortunately https://github.com/matrix-org/matrix-rust-sdk/pull/4778 makes that very much of an edge case and we
    /// also automatically start a `latestEncryptionState` fetch if needed.
    /// In the worst case, even if we are to assume a room is unencrypted, the SDK will still determine the correct
    /// state before any message is sent.
    var isEncrypted: Bool {
        roomInfo.encryptionState == .encrypted
    }
    
    var isDirect: Bool {
        roomInfo.isDirect
    }

    var isSpace: Bool {
        roomInfo.isSpace
    }
    
    var successor: SuccessorRoom? {
        roomInfo.successorRoom
    }

    var isFavourite: Bool {
        roomInfo.isFavourite
    }

    var canonicalAlias: String? {
        roomInfo.canonicalAlias
    }

    var alternativeAliases: [String] {
        roomInfo.alternativeAliases
    }

    var membership: Membership {
        roomInfo.membership
    }

    var inviter: RoomMemberProxyProtocol? {
        roomInfo.inviter.map(RoomMemberProxy.init)
    }

    var heroes: [RoomHero] {
        roomInfo.heroes
    }

    var activeMembersCount: Int {
        Int(roomInfo.activeMembersCount)
    }

    var invitedMembersCount: Int {
        Int(roomInfo.invitedMembersCount)
    }

    var joinedMembersCount: Int {
        Int(roomInfo.joinedMembersCount)
    }

    var highlightCount: Int {
        Int(roomInfo.highlightCount)
    }

    var notificationCount: Int {
        Int(roomInfo.notificationCount)
    }

    var cachedUserDefinedNotificationMode: RoomNotificationMode? {
        roomInfo.cachedUserDefinedNotificationMode
    }

    var hasRoomCall: Bool {
        roomInfo.hasRoomCall
    }

    var activeRoomCallParticipants: [String] {
        roomInfo.activeRoomCallParticipants
    }

    var isMarkedUnread: Bool {
        roomInfo.isMarkedUnread
    }

    var unreadMessagesCount: UInt {
        UInt(roomInfo.numUnreadMessages)
    }

    var unreadNotificationsCount: UInt {
        UInt(roomInfo.numUnreadNotifications)
    }

    var unreadMentionsCount: UInt {
        UInt(roomInfo.numUnreadMentions)
    }

    var pinnedEventIDs: Set<String> {
        Set(roomInfo.pinnedEventIds)
    }

    var joinRule: JoinRule? {
        roomInfo.joinRule.map(JoinRule.init)
    }

    var historyVisibility: RoomHistoryVisibility {
        roomInfo.historyVisibility
    }
    
    var powerLevels: RoomPowerLevelsProxyProtocol? {
        RoomPowerLevelsProxy(roomInfo.powerLevels)
    }
}

struct RoomPreviewInfoProxy: BaseRoomInfoProxyProtocol {
    let roomPreviewInfo: RoomPreviewInfo
    
    let successor: SuccessorRoom? = nil
    
    var id: String {
        roomPreviewInfo.roomId
    }

    var displayName: String? {
        roomPreviewInfo.name
    }

    var heroes: [RoomHero] {
        roomPreviewInfo.heroes ?? []
    }

    var topic: String? {
        roomPreviewInfo.topic
    }

    var canonicalAlias: String? {
        roomPreviewInfo.canonicalAlias
    }

    var avatarURL: URL? {
        roomPreviewInfo.avatarUrl.flatMap(URL.init)
    }

    var isDirect: Bool {
        roomPreviewInfo.isDirect ?? false
    }

    var isSpace: Bool {
        roomPreviewInfo.roomType == .space
    }

    var activeMembersCount: Int {
        Int(roomPreviewInfo.numActiveMembers ?? roomPreviewInfo.numJoinedMembers)
    }

    var joinedMembersCount: Int {
        Int(roomPreviewInfo.numJoinedMembers)
    }
    
    var joinRule: JoinRule? {
        roomPreviewInfo.joinRule.map(JoinRule.init)
    }

    var membership: Membership? {
        roomPreviewInfo.membership
    }
}
