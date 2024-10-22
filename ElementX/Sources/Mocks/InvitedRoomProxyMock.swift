//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation

@MainActor
struct InvitedRoomProxyMockConfiguration {
    var id = UUID().uuidString
    var name: String?
    var avatarURL: URL?
    var members: [RoomMemberProxyMock] = .allMembers
    var inviter: RoomMemberProxyMock = .mockAlice
}

extension InvitedRoomProxyMock {
    @MainActor
    convenience init(_ configuration: InvitedRoomProxyMockConfiguration) {
        self.init()
        id = configuration.id
        name = configuration.name
        avatarURL = configuration.avatarURL
        avatar = .room(id: configuration.id, name: configuration.name, avatarURL: configuration.avatarURL) // Note: This doesn't replicate the real proxy logic.
        underlyingInviter = configuration.inviter
        activeMembersCount = configuration.members.filter { $0.membership == .join || $0.membership == .invite }.count
    }
}
