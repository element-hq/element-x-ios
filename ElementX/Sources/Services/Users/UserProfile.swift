//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

nonisolated struct UserProfile: Hashable, Identifiable {
    let id: String
    let displayName: String?
    let avatarURL: URL?
    
    init(userID: String, displayName: String? = nil, avatarURL: URL? = nil) {
        id = userID
        self.displayName = displayName
        self.avatarURL = avatarURL
    }
    
    init(member: RoomMemberDetails) {
        id = member.id
        displayName = member.isBanned ? nil : member.name
        avatarURL = member.isBanned ? nil : member.avatarURL
    }
    
    init(sender: TimelineItemSender) {
        id = sender.id
        displayName = sender.displayName
        avatarURL = sender.avatarURL
    }
    
    init(sdkUserProfile: MatrixRustSDK.UserProfile) {
        id = sdkUserProfile.userId
        displayName = sdkUserProfile.displayName
        avatarURL = sdkUserProfile.avatarUrl.flatMap(URL.init(string:))
    }
    
    init(sdkRoomHero: MatrixRustSDK.RoomHero) {
        id = sdkRoomHero.userId
        displayName = sdkRoomHero.displayName
        avatarURL = sdkRoomHero.avatarUrl.flatMap(URL.init(string:))
    }
    
    init(member: RoomMemberProxyProtocol) {
        self.init(member: RoomMemberDetails(withProxy: member))
    }
    
    /// A user is meant to be "verified" when the GET profile returns back either the display name or the avatar
    /// If isn't we aren't sure that the related matrix id really exists.
    var isVerified: Bool {
        displayName != nil || avatarURL != nil
    }
}

struct SearchUsersResults {
    let results: [UserProfile]
    let limited: Bool
}

extension SearchUsersResults {
    init(sdkResults: MatrixRustSDK.SearchUsersResults) {
        results = sdkResults.results.map(UserProfile.init)
        limited = sdkResults.limited
    }
}
