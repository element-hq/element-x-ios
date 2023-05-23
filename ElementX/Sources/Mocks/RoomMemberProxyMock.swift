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
    var displayName: String
    var avatarURL: URL?
    var membership: MembershipState
    var isNameAmbiguous = false
    var powerLevel: Int
    var normalizedPowerLevel: Int
    var isAccountOwner = false
    var isIgnored = false
    var canInviteUsers = false
}

extension RoomMemberProxyMock {
    convenience init(with configuration: RoomMemberProxyMockConfiguration) {
        self.init()
        userID = configuration.userID
        displayName = configuration.displayName
        avatarURL = configuration.avatarURL
        membership = configuration.membership
        isNameAmbiguous = configuration.isNameAmbiguous
        powerLevel = configuration.powerLevel
        normalizedPowerLevel = configuration.normalizedPowerLevel
        isAccountOwner = configuration.isAccountOwner
        isIgnored = configuration.isIgnored
        canInviteUsers = configuration.canInviteUsers
        canSendStateEventTypeClosure = { _ in true }
    }

    // Mocks
    static var mockAlice: RoomMemberProxyMock {
        RoomMemberProxyMock(with: .init(userID: "@alice:matrix.org",
                                        displayName: "Alice",
                                        avatarURL: nil,
                                        membership: .join,
                                        powerLevel: 50,
                                        normalizedPowerLevel: 50))
    }
    
    static var mockInvitedAlice: RoomMemberProxyMock {
        RoomMemberProxyMock(with: .init(userID: "@alice:matrix.org",
                                        displayName: "Alice",
                                        avatarURL: nil,
                                        membership: .invite,
                                        powerLevel: 50,
                                        normalizedPowerLevel: 50))
    }

    static var mockBob: RoomMemberProxyMock {
        RoomMemberProxyMock(with: .init(userID: "@bob:matrix.org",
                                        displayName: "Bob",
                                        avatarURL: nil,
                                        membership: .join,
                                        powerLevel: 50,
                                        normalizedPowerLevel: 50))
    }

    static var mockCharlie: RoomMemberProxyMock {
        RoomMemberProxyMock(with: .init(userID: "@charlie:matrix.org",
                                        displayName: "Charlie",
                                        avatarURL: nil,
                                        membership: .join,
                                        powerLevel: 50,
                                        normalizedPowerLevel: 50))
    }

    static var mockDan: RoomMemberProxyMock {
        RoomMemberProxyMock(with: .init(userID: "@dan:matrix.org",
                                        displayName: "Dan",
                                        avatarURL: URL.picturesDirectory,
                                        membership: .join,
                                        powerLevel: 50,
                                        normalizedPowerLevel: 50))
    }

    static var mockMe: RoomMemberProxyMock {
        RoomMemberProxyMock(with: .init(userID: "@me:matrix.org",
                                        displayName: "Me",
                                        avatarURL: URL.picturesDirectory,
                                        membership: .join,
                                        powerLevel: 50,
                                        normalizedPowerLevel: 50,
                                        isAccountOwner: true,
                                        canInviteUsers: true))
    }

    static var mockIgnored: RoomMemberProxyMock {
        RoomMemberProxyMock(with: .init(userID: "@ignored:matrix.org",
                                        displayName: "Ignored",
                                        avatarURL: nil,
                                        membership: .join,
                                        powerLevel: 50,
                                        normalizedPowerLevel: 50,
                                        isIgnored: true))
    }
}
