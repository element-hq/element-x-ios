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

// sourcery: AutoMockable
protocol RoomMemberProxyProtocol: AnyObject {
    var userID: String { get }
    var displayName: String? { get }
    var avatarURL: URL? { get }
    
    var membership: MembershipState { get }
    var isIgnored: Bool { get }
    
    var powerLevel: Int { get }
    var role: RoomMemberRole { get }
}

extension RoomMemberProxyProtocol {
    /// The member is active in the room (joined or invited).
    var isActive: Bool {
        membership == .join || membership == .invite
    }
    
    var permalink: URL? {
        try? URL(string: matrixToUserPermalink(userId: userID))
    }
    
    /// The name used for sorting the member alphabetically. This will be the displayname if,
    /// it exists otherwise it will be the userID with the leading `@` removed.
    var sortingName: String {
        // If there isn't a displayname we sort by the userID without the @.
        (displayName ?? String(userID.dropFirst())).lowercased()
    }
}

extension [RoomMemberProxyProtocol] {
    /// The members, sorted first by power-level, and then alphabetically within each power-level.
    func sorted() -> Self {
        sorted { lhs, rhs in
            if lhs.powerLevel != rhs.powerLevel {
                lhs.powerLevel > rhs.powerLevel
            } else {
                lhs.sortingName.localizedStandardCompare(rhs.sortingName) == .orderedAscending
            }
        }
    }
}
