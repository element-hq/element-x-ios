//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

// sourcery: AutoMockable
protocol SpaceRoomProxyProtocol {
    var id: String { get }
    var name: String? { get }
    var avatarURL: URL? { get }
    
    var isSpace: Bool { get }
    var childrenCount: Int { get }
    
    var joinedMembersCount: Int { get }
    var heroes: [UserProfileProxy] { get }
    var topic: String? { get }
    var canonicalAlias: String? { get }
    
    var joinRule: JoinRule? { get }
    var worldReadable: Bool? { get }
    var guestCanJoin: Bool { get }
    var state: Membership? { get }
    var via: [String] { get }
}

extension SpaceRoomProxyProtocol {
    var avatar: RoomAvatar {
        if isSpace {
            .space(id: id, name: name, avatarURL: avatarURL)
        } else { // We don't need to check for heroes, we only do that for DMs.
            .room(id: id, name: name, avatarURL: avatarURL)
        }
    }
}
