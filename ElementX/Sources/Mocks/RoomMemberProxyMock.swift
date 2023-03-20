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
    var userId: String
    var displayName: String
    var avatarUrl: String?
    var membership: MembershipState
    var isNameAmbiguous: Bool
    var powerLevel: Int64
    var normalizedPowerLevel: Int64
}

extension RoomMemberProxyMock {
    convenience init(with configuration: RoomMemberProxyMockConfiguration) {
        self.init()
        userId = configuration.userId
        displayName = configuration.displayName
        membership = configuration.membership
        isNameAmbiguous = configuration.isNameAmbiguous
        powerLevel = configuration.powerLevel
        normalizedPowerLevel = configuration.normalizedPowerLevel
    }

    // Mocks
    static var mockAlice: RoomMemberProxyMock {
        RoomMemberProxyMock(with: .init(userId: "alice@matrix.org",
                                        displayName: "Alice",
                                        avatarUrl: nil,
                                        membership: .join,
                                        isNameAmbiguous: false,
                                        powerLevel: 50,
                                        normalizedPowerLevel: 50))
    }

    static var mockBob: RoomMemberProxyMock {
        RoomMemberProxyMock(with: .init(userId: "bob@matrix.org",
                                        displayName: "Bob",
                                        avatarUrl: nil,
                                        membership: .join,
                                        isNameAmbiguous: false,
                                        powerLevel: 50,
                                        normalizedPowerLevel: 50))
    }

    static var mockCharlie: RoomMemberProxyMock {
        RoomMemberProxyMock(with: .init(userId: "charlie@matrix.org",
                                        displayName: "Charlie",
                                        avatarUrl: nil,
                                        membership: .join,
                                        isNameAmbiguous: false,
                                        powerLevel: 50,
                                        normalizedPowerLevel: 50))
    }
}
