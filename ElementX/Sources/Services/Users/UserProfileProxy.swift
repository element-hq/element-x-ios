//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct UserProfileProxy: Equatable, Hashable {
    let userID: String
    let displayName: String?
    let avatarURL: URL?
    
    init(userID: String, displayName: String? = nil, avatarURL: URL? = nil) {
        self.userID = userID
        self.displayName = displayName
        self.avatarURL = avatarURL
    }
    
    init(member: RoomMemberDetails) {
        userID = member.id
        displayName = member.isBanned ? nil : member.name
        avatarURL = member.isBanned ? nil : member.avatarURL
    }
    
    init(sdkUserProfile: MatrixRustSDK.UserProfile) {
        userID = sdkUserProfile.userId
        displayName = sdkUserProfile.displayName
        avatarURL = sdkUserProfile.avatarUrl.flatMap(URL.init(string:))
    }
    
    init(sdkRoomHero: MatrixRustSDK.RoomHero) {
        userID = sdkRoomHero.userId
        displayName = sdkRoomHero.displayName
        avatarURL = sdkRoomHero.avatarUrl.flatMap(URL.init(string:))
    }
    
    /// A user is meant to be "verified" when the GET profile returns back either the display name or the avatar
    /// If isn't we aren't sure that the related matrix id really exists.
    var isVerified: Bool {
        displayName != nil || avatarURL != nil
    }
}

struct SearchUsersResultsProxy {
    let results: [UserProfileProxy]
    let limited: Bool
}

extension SearchUsersResultsProxy {
    init(sdkResults: MatrixRustSDK.SearchUsersResults) {
        results = sdkResults.results.map(UserProfileProxy.init)
        limited = sdkResults.limited
    }
}
