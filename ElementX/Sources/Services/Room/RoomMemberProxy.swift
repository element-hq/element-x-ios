//
// Copyright 2022 New Vector Ltd
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

struct RoomMemberProxy {
    private let member: RoomMember

    init(with member: RoomMember) {
        self.member = member
    }

    var userId: String {
        member.userId
    }

    var displayName: String? {
        member.displayName
    }

    var avatarURL: URL? {
        member.avatarUrl.flatMap(URL.init(string:))
    }

    var membership: MembershipState {
        member.membership
    }

    var isNameAmbiguous: Bool {
        member.isNameAmbiguous
    }

    var powerLevel: Int64 {
        member.powerLevel
    }

    var normalizedPowerLevel: Int64 {
        member.normalizedPowerLevel
    }
}

extension RoomMemberProxy: Identifiable {
    var id: String {
        userId
    }
}

// Mocks
extension RoomMemberProxy {
    static var mockAlice: RoomMemberProxy {
        RoomMemberProxy(with: .init(userId: "alice@matrix.org",
                                    displayName: "Alice",
                                    avatarUrl: nil,
                                    membership: .join,
                                    isNameAmbiguous: false,
                                    powerLevel: 50,
                                    normalizedPowerLevel: 50))
    }
    
    static var mockBob: RoomMemberProxy {
        RoomMemberProxy(with: .init(userId: "bob@matrix.org",
                                    displayName: "Bob",
                                    avatarUrl: nil,
                                    membership: .join,
                                    isNameAmbiguous: false,
                                    powerLevel: 50,
                                    normalizedPowerLevel: 50))
    }
    
    static var mockCharlie: RoomMemberProxy {
        RoomMemberProxy(with: .init(userId: "charlie@matrix.org",
                                    displayName: "Charlie",
                                    avatarUrl: nil,
                                    membership: .join,
                                    isNameAmbiguous: false,
                                    powerLevel: 50,
                                    normalizedPowerLevel: 50))
    }
}
