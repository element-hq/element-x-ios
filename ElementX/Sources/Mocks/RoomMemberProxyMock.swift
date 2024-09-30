//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct RoomMemberProxyMockConfiguration {
    var userID: String
    var displayName: String?
    var avatarURL: URL?
    
    var membership: MembershipState
    var isIgnored = false
    
    var powerLevel = 0
    var role = RoomMemberRole.user
}

extension RoomMemberProxyMock {
    convenience init(with configuration: RoomMemberProxyMockConfiguration) {
        self.init()
        userID = configuration.userID
        displayName = configuration.displayName
        avatarURL = configuration.avatarURL
        
        membership = configuration.membership
        isIgnored = configuration.isIgnored
        
        powerLevel = configuration.powerLevel
        role = configuration.role
    }

    // Mocks
    static var mockMe: RoomMemberProxyMock {
        RoomMemberProxyMock(with: .init(userID: "@me:matrix.org",
                                        displayName: "Me",
                                        avatarURL: URL.picturesDirectory,
                                        membership: .join))
    }
    
    static var mockMeAdmin: RoomMemberProxyMock {
        RoomMemberProxyMock(with: .init(userID: "@me:matrix.org",
                                        displayName: "Me",
                                        avatarURL: URL.picturesDirectory,
                                        membership: .join,
                                        powerLevel: 100,
                                        role: .administrator))
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
    
    static var mockVerbose: RoomMemberProxyMock {
        RoomMemberProxyMock(with: .init(userID: "@charliev:matrix.org",
                                        displayName: "Charlie is the best display name",
                                        membership: .join))
    }
    
    static var mockNoName: RoomMemberProxyMock {
        RoomMemberProxyMock(with: .init(userID: "@anonymous:matrix.org",
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
