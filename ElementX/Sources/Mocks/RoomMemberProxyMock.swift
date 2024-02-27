//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import MatrixRustSDK

struct RoomMemberProxyMockConfiguration {
    var userID: String
    var displayName: String?
    var avatarURL: URL?
    var membership: MembershipState
    var isAccountOwner = false
    var isIgnored = false
    var powerLevel = 0
    var role = RoomMemberRole.user
    var canInviteUsers = false
    var canKickUsers = false
    var canBanUsers = false
    var canSendStateEvent: (StateEventType) -> Bool = { _ in true }
}

extension RoomMemberProxyMock {
    convenience init(with configuration: RoomMemberProxyMockConfiguration) {
        self.init()
        userID = configuration.userID
        displayName = configuration.displayName
        avatarURL = configuration.avatarURL
        membership = configuration.membership
        isAccountOwner = configuration.isAccountOwner
        isIgnored = configuration.isIgnored
        powerLevel = configuration.powerLevel
        role = configuration.role
        canInviteUsers = configuration.canInviteUsers
        canKickUsers = configuration.canKickUsers
        canBanUsers = configuration.canBanUsers
        canSendStateEventTypeClosure = configuration.canSendStateEvent
    }

    // Mocks
    static var mockMe: RoomMemberProxyMock {
        RoomMemberProxyMock(with: .init(userID: "@me:matrix.org",
                                        displayName: "Me",
                                        avatarURL: URL.picturesDirectory,
                                        membership: .join,
                                        isAccountOwner: true,
                                        canInviteUsers: true))
    }
    
    static var mockMeAdmin: RoomMemberProxyMock {
        RoomMemberProxyMock(with: .init(userID: "@me:matrix.org",
                                        displayName: "Me admin",
                                        avatarURL: URL.picturesDirectory,
                                        membership: .join,
                                        isAccountOwner: true,
                                        powerLevel: 100,
                                        role: .administrator,
                                        canInviteUsers: true,
                                        canKickUsers: true,
                                        canBanUsers: true))
    }
    
    static var mockAlice: RoomMemberProxyMock {
        RoomMemberProxyMock(with: .init(userID: "@alice:matrix.org",
                                        displayName: "Alice",
                                        membership: .join))
    }
    
    static var mockInvitedAlice: RoomMemberProxyMock {
        RoomMemberProxyMock(with: .init(userID: "@alice:matrix.org",
                                        displayName: "Alice",
                                        membership: .invite))
    }

    static var mockBob: RoomMemberProxyMock {
        RoomMemberProxyMock(with: .init(userID: "@bob:matrix.org",
                                        displayName: "Bob",
                                        membership: .join))
    }

    static var mockCharlie: RoomMemberProxyMock {
        RoomMemberProxyMock(with: .init(userID: "@charlie:matrix.org",
                                        displayName: "Charlie",
                                        membership: .join))
    }

    static var mockDan: RoomMemberProxyMock {
        RoomMemberProxyMock(with: .init(userID: "@dan:matrix.org",
                                        displayName: "Dan",
                                        avatarURL: URL.picturesDirectory,
                                        membership: .join))
    }
    
    static var mockInvited: RoomMemberProxyMock {
        RoomMemberProxyMock(with: .init(userID: "@invited:matrix.org",
                                        displayName: "Invited",
                                        membership: .invite,
                                        isIgnored: true))
    }

    static var mockIgnored: RoomMemberProxyMock {
        RoomMemberProxyMock(with: .init(userID: "@ignored:matrix.org",
                                        displayName: "Ignored",
                                        membership: .join,
                                        isIgnored: true))
    }
    
    static func mockOwner(allowedStateEvents: [StateEventType], canInviteUsers: Bool = true) -> RoomMemberProxyMock {
        RoomMemberProxyMock(with: .init(userID: "@foo:some.org",
                                        displayName: "User owner",
                                        membership: .join,
                                        isAccountOwner: true,
                                        canInviteUsers: canInviteUsers,
                                        canSendStateEvent: { allowedStateEvents.contains($0) }))
    }
    
    static var mockAdmin: RoomMemberProxyMock {
        RoomMemberProxyMock(with: .init(userID: "@admin:matrix.org",
                                        displayName: "Arthur",
                                        membership: .join,
                                        powerLevel: 100,
                                        role: .administrator))
    }
    
    static var mockModerator: RoomMemberProxyMock {
        RoomMemberProxyMock(with: .init(userID: "@mod:matrix.org",
                                        displayName: "Merlin",
                                        membership: .join,
                                        powerLevel: 50,
                                        role: .moderator))
    }
    
    static var mockBanned: [RoomMemberProxyMock] {
        [
            RoomMemberProxyMock(with: .init(userID: "@mischief:matrix.org",
                                            membership: .ban)),
            RoomMemberProxyMock(with: .init(userID: "@spam:matrix.org",
                                            membership: .ban)),
            RoomMemberProxyMock(with: .init(userID: "@angry:matrix.org",
                                            membership: .ban)),
            RoomMemberProxyMock(with: .init(userID: "@fake:matrix.org",
                                            displayName: "The President",
                                            membership: .ban))
        ]
    }
}

extension Array where Element == RoomMemberProxyMock {
    static let allMembers: [RoomMemberProxyMock] = [
        .mockMe,
        .mockAlice,
        .mockBob,
        .mockCharlie,
        .mockDan,
        .mockInvited,
        .mockIgnored
    ]
    
    static let allMembersAsAdmin: [RoomMemberProxyMock] = [
        .mockMeAdmin,
        .mockAlice,
        .mockBob,
        .mockCharlie,
        .mockDan,
        .mockInvited,
        .mockIgnored,
        .mockAdmin,
        .mockModerator
    ]
}
