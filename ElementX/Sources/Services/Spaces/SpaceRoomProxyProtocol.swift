//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum SpaceRoomProxyVisibility: Equatable {
    case `public`
    case `private`
    case restricted(parentName: String)
    // We can add the external case in here eventually.
}

// sourcery: AutoMockable
protocol SpaceRoomProxyProtocol {
    var id: String { get }
    var name: String? { get }
    var avatarURL: URL? { get }
    
    var isSpace: Bool { get }
    var isDirect: Bool? { get }
    /// A temporary property until we get the `AllowRule`s from the server.
    var parent: SpaceRoomProxyProtocol? { get }
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
        } else if isDirect == true, avatarURL == nil, heroes.count == 1 {
            .heroes(heroes)
        } else {
            .room(id: id, name: name, avatarURL: avatarURL)
        }
    }
    
    var computedName: String {
        if !isSpace, isDirect == true, name == nil, heroes.count == 1, let dmRecipient = heroes.first {
            dmRecipient.displayName ?? dmRecipient.id
        } else {
            name ?? canonicalAlias ?? id
        }
    }
    
    var visibility: SpaceRoomProxyVisibility? {
        switch joinRule {
        case .public:
            .public
        case .restricted, .knockRestricted:
            // Temporary solution until the server includes the `AllowRule` values (they're always empty right now).
            if let parent {
                .restricted(parentName: parent.computedName)
            } else {
                .private
            }
        case .invite, .knock, .private, .custom:
            .private
        case .none:
            .none
        }
    }
}
