//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

nonisolated struct RoomInfoProxy: RoomInfoProxyProtocol {
    let roomInfo: RoomInfo
    
    var id: String {
        roomInfo.id
    }
    
    // periphery:ignore - might be useful to have
    
    var creators: [String] {
        roomInfo.creators ?? []
    }
    
    var displayName: String? {
        roomInfo.displayName
    }
    
    // periphery:ignore - might be useful to have
    
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
    
    var isDM: Bool {
        roomInfo.isDm
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
    
    // periphery:ignore - might be useful to have
    
    var inviter: RoomMemberProxyProtocol? {
        roomInfo.inviter.map(RoomMemberProxy.init)
    }
    
    var heroes: [RoomHero] {
        roomInfo.heroes
    }
    
    var activeMembersCount: Int {
        Int(roomInfo.activeMembersCount)
    }
    
    // periphery:ignore - might be useful to have
    
    var invitedMembersCount: Int {
        Int(roomInfo.invitedMembersCount)
    }
    
    var joinedMembersCount: Int {
        Int(roomInfo.joinedMembersCount)
    }
    
    // periphery:ignore - might be useful to have
    
    var highlightCount: Int {
        Int(roomInfo.highlightCount)
    }
    
    // periphery:ignore - might be useful to have
    
    var notificationCount: Int {
        Int(roomInfo.notificationCount)
    }
    
    // periphery:ignore - might be useful to have
    
    var cachedUserDefinedNotificationMode: RoomNotificationMode? {
        roomInfo.cachedUserDefinedNotificationMode
    }
    
    var hasRoomCall: Bool {
        roomInfo.hasRoomCall
    }
    
    var activeRoomCallIntent: CallIntent? {
        switch roomInfo.activeRoomCallConsensusIntent {
        case .full(let intent):
            return .init(rustCallIntent: intent)
        case .partial(intent: let intent, _, _):
            return .init(rustCallIntent: intent)
        case .none:
            return nil
        }
    }
    
    var activeRoomCallParticipants: [String] {
        roomInfo.activeRoomCallParticipants
    }
    
    // periphery:ignore - might be useful to have
    
    var isMarkedUnread: Bool {
        roomInfo.isMarkedUnread
    }
    
    // periphery:ignore - might be useful to have
    
    var unreadMessagesCount: UInt {
        UInt(roomInfo.numUnreadMessages)
    }
    
    // periphery:ignore - might be useful to have
    
    var unreadNotificationsCount: UInt {
        UInt(roomInfo.numUnreadNotifications)
    }
    
    // periphery:ignore - might be useful to have
    
    var unreadMentionsCount: UInt {
        UInt(roomInfo.numUnreadMentions)
    }
    
    var fullyReadEventID: String? {
        roomInfo.fullyReadEventId
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

nonisolated struct RoomPreviewInfoProxy: BaseRoomInfoProxyProtocol {
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
