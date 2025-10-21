//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
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

    let role: RoomRole
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
        role = proxy.role
        powerLevel = proxy.powerLevel
    }
}
