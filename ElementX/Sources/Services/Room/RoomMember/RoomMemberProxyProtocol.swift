//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
