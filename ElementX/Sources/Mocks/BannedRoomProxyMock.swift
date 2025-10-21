//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

@MainActor
struct BannedRoomProxyMockConfiguration {
    var id = UUID().uuidString
    var name: String?
    var avatarURL: URL?
    var members: [RoomMemberProxyMock] = .allMembers
}

extension BannedRoomProxyMock {
    @MainActor
    convenience init(_ configuration: BannedRoomProxyMockConfiguration) {
        self.init()
        id = configuration.id
        info = RoomInfoProxyMock(configuration)
    }
}

extension RoomInfoProxyMock {
    @MainActor convenience init(_ configuration: BannedRoomProxyMockConfiguration) {
        self.init()
        
        id = configuration.id
        isEncrypted = false
        creators = []
        displayName = configuration.name
        rawName = nil
        topic = nil
        
        avatarURL = configuration.avatarURL
        
        isDirect = false
        isSpace = false
        successor = nil
        isFavourite = false
        canonicalAlias = nil
        alternativeAliases = []
        membership = .knocked
        inviter = nil
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
        joinRule = .knock
        historyVisibility = .shared
        
        powerLevels = RoomPowerLevelsProxyMock(configuration: .init())
    }
}
