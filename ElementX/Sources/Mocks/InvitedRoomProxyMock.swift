//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

@MainActor
struct InvitedRoomProxyMockConfiguration {
    var id = UUID().uuidString
    var name: String?
    var avatarURL: URL?
    var isSpace = false
    var members: [RoomMemberProxyMock] = .allMembers
    var inviter: RoomMemberProxyMock = .mockAlice
}

extension InvitedRoomProxyMock {
    @MainActor
    convenience init(_ configuration: InvitedRoomProxyMockConfiguration) {
        self.init()
        id = configuration.id
        inviter = configuration.inviter
        info = RoomInfoProxyMock(configuration)
        
        rejectInvitationReturnValue = .success(())
    }
}

extension RoomInfoProxyMock {
    @MainActor convenience init(_ configuration: InvitedRoomProxyMockConfiguration) {
        self.init()
        
        id = configuration.id
        isEncrypted = false
        creators = []
        displayName = configuration.name
        rawName = nil
        topic = nil
        
        avatarURL = configuration.avatarURL
        
        isDirect = false
        isSpace = configuration.isSpace
        successor = nil
        isFavourite = false
        canonicalAlias = nil
        alternativeAliases = []
        membership = .knocked
        inviter = .init(configuration.inviter)
        heroes = []
        activeMembersCount = configuration.members.filter { $0.membership == .join || $0.membership == .invite }.count
        invitedMembersCount = configuration.members.filter { $0.membership == .invite }.count
        joinedMembersCount = configuration.members.filter { $0.membership == .join }.count
        highlightCount = 0
        notificationCount = 0
        cachedUserDefinedNotificationMode = nil
        hasRoomCall = false
        activeRoomCallParticipants = []
        isMarkedUnread = false
        unreadMessagesCount = 0
        unreadNotificationsCount = 0
        unreadMentionsCount = 0
        pinnedEventIDs = []
        joinRule = .invite
        historyVisibility = .shared
        
        powerLevels = RoomPowerLevelsProxyMock(configuration: .init())
    }
}

private extension RoomMember {
    init(_ proxy: RoomMemberProxyProtocol) {
        self.init(userId: proxy.userID,
                  displayName: proxy.displayName,
                  avatarUrl: proxy.avatarURL?.absoluteString,
                  membership: proxy.membership,
                  isNameAmbiguous: proxy.disambiguatedDisplayName != proxy.displayName,
                  powerLevel: proxy.powerLevel.rustPowerLevel,
                  isIgnored: proxy.isIgnored,
                  suggestedRoleForPowerLevel: proxy.role.rustRole,
                  membershipChangeReason: proxy.membershipChangeReason)
    }
}
