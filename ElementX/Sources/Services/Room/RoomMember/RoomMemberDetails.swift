//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    
    enum Role { case administrator, moderator, user }
    let role: Role
    
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
        
        isInvited = proxy.membership == .invite
        isIgnored = proxy.isIgnored
        isBanned = proxy.membership == .ban
        role = .init(proxy.role)
    }
}

extension RoomMemberDetails.Role {
    init(_ role: RoomMemberRole) {
        self = switch role {
        case .administrator: .administrator
        case .moderator: .moderator
        case .user: .user
        }
    }
}
