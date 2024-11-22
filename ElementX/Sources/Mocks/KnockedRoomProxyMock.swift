//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

@MainActor
struct KnockedRoomProxyMockConfiguration {
    var id = UUID().uuidString
    var name: String?
    var avatarURL: URL?
    var members: [RoomMemberProxyMock] = .allMembers
}

extension KnockedRoomProxyMock {
    @MainActor
    convenience init(_ configuration: KnockedRoomProxyMockConfiguration) {
        self.init()
        id = configuration.id
        info = RoomInfoProxy(roomInfo: .init(configuration))
    }
}

extension RoomInfo {
    @MainActor init(_ configuration: KnockedRoomProxyMockConfiguration) {
        self.init(id: configuration.id,
                  creator: nil,
                  displayName: configuration.name,
                  rawName: nil,
                  topic: nil,
                  avatarUrl: configuration.avatarURL?.absoluteString,
                  isDirect: false,
                  isPublic: false,
                  isSpace: false,
                  isTombstoned: false,
                  isFavourite: false,
                  canonicalAlias: nil,
                  alternativeAliases: [],
                  membership: .knocked,
                  inviter: nil,
                  heroes: [],
                  activeMembersCount: UInt64(configuration.members.filter { $0.membership == .join || $0.membership == .invite }.count),
                  invitedMembersCount: UInt64(configuration.members.filter { $0.membership == .invite }.count),
                  joinedMembersCount: UInt64(configuration.members.filter { $0.membership == .join }.count),
                  userPowerLevels: [:],
                  highlightCount: 0,
                  notificationCount: 0,
                  cachedUserDefinedNotificationMode: nil,
                  hasRoomCall: false,
                  activeRoomCallParticipants: [],
                  isMarkedUnread: false,
                  numUnreadMessages: 0,
                  numUnreadNotifications: 0,
                  numUnreadMentions: 0,
                  pinnedEventIds: [],
                  joinRule: .knock)
    }
}
