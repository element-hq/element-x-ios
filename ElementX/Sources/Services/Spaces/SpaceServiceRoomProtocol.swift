//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum SpaceServiceRoomVisibility: Equatable {
    case `public`
    case `private`
    case restricted
    // We can add the external case in here eventually.
}

// sourcery: AutoMockable
protocol SpaceServiceRoomProtocol {
    var id: String { get }
    var name: String { get }
    var rawName: String? { get }
    var avatarURL: URL? { get }
    
    var isSpace: Bool { get }
    var isDirect: Bool? { get }
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

extension SpaceServiceRoomProtocol {
    var avatar: RoomAvatar {
        if isSpace {
            .space(id: id, name: name, avatarURL: avatarURL)
        } else if isDirect == true, avatarURL == nil, heroes.count == 1 {
            .heroes(heroes)
        } else {
            .room(id: id, name: name, avatarURL: avatarURL)
        }
    }
    
    var visibility: SpaceServiceRoomVisibility? {
        switch joinRule {
        case .public:
            .public
        case .restricted, .knockRestricted:
            .restricted
        case .invite, .knock, .private, .custom:
            .private
        case .none:
            .none
        }
    }
}
