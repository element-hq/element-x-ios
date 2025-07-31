//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct RoomMemberDetails: Identifiable, Hashable {
    let id: String
    let name: String?
    let avatarURL: URL?
    let permalink: URL?
    
    var isInvited: Bool
    var isIgnored: Bool
    var isBanned: Bool
    var isActive: Bool
        
    enum Role {
        /// Creator of the room, PL infinite
        case creator
        /// Same power of an admin, but they can also upgrade the room, PL 150 onwards
        case owner
        /// Able to edit room settings and perform any action aside from room upgrading PL 100...149
        case administrator
        /// Able to perform room moderation actions PL 50...99
        case moderator
        /// Default role PL 0...49
        case user
    }

    let role: Role
    let powerLevel: RoomPowerLevel
    
    func matches(searchQuery: String) -> Bool {
        guard !searchQuery.isEmpty else { return true }
        return id.localizedStandardContains(searchQuery) || name?.localizedStandardContains(searchQuery) == true
    }
}

extension RoomMemberDetails {
    init(withProxy proxy: RoomMemberProxyProtocol) {
        id = proxy.userID
        name = proxy.displayName
        avatarURL = proxy.avatarURL
        permalink = proxy.permalink
        isActive = proxy.isActive
        isInvited = proxy.membership == .invite
        isIgnored = proxy.isIgnored
        isBanned = proxy.membership == .ban
        role = .init(proxy.role, powerLevel: proxy.powerLevel)
        powerLevel = proxy.powerLevel
    }
}

extension RoomMemberDetails.Role {
    init(_ role: RoomMemberRole, powerLevel: RoomPowerLevel) {
        switch role {
        case .creator:
            self = .creator
        case .administrator:
            switch powerLevel {
            case .value(let value):
                self = value >= 150 ? .owner : .administrator
            default:
                fatalError("Impossible")
            }
        case .moderator:
            self = .moderator
        case .user:
            self = .user
        }
    }
        
    var isAdminOrHigher: Bool {
        switch self {
        case .administrator, .creator, .owner:
            return true
        case .moderator, .user:
            return false
        }
    }
    
    var isOwner: Bool {
        switch self {
        case .creator, .owner:
            return true
        case .administrator, .moderator, .user:
            return false
        }
    }
}

extension RoomMemberRole {
    var isAdminOrHigher: Bool {
        switch self {
        case .administrator, .creator:
            return true
        case .moderator, .user:
            return false
        }
    }
}
