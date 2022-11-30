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

    var avatarUrl: String? {
        member.avatarUrl
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
    static let mockA = RoomMemberProxy(with: .init(userId: "mockA@m.org",
                                                   displayName: "A Member",
                                                   avatarUrl: nil,
                                                   membership: .join,
                                                   isNameAmbiguous: false,
                                                   powerLevel: 50,
                                                   normalizedPowerLevel: 50))
    static let mockB = RoomMemberProxy(with: .init(userId: "mockB@m.org",
                                                   displayName: "B Member",
                                                   avatarUrl: nil,
                                                   membership: .join,
                                                   isNameAmbiguous: false,
                                                   powerLevel: 50,
                                                   normalizedPowerLevel: 50))
    static let mockC = RoomMemberProxy(with: .init(userId: "mockC@m.org",
                                                   displayName: "C Member",
                                                   avatarUrl: nil,
                                                   membership: .join,
                                                   isNameAmbiguous: false,
                                                   powerLevel: 50,
                                                   normalizedPowerLevel: 50))
}
