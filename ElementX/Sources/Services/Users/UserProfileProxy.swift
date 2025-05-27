//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct UserProfileProxy: Equatable, Hashable {
    let userID: String
    let displayName: String?
    let avatarURL: URL?
    var primaryZeroId: String?
    
    init(userID: String, displayName: String? = nil, avatarURL: URL? = nil) {
        self.userID = userID
        self.displayName = displayName
        self.avatarURL = avatarURL
        primaryZeroId = nil
    }
    
    init(member: RoomMemberDetails) {
        userID = member.id
        displayName = member.isBanned ? nil : member.name
        avatarURL = member.isBanned ? nil : member.avatarURL
        primaryZeroId = member.primaryZeroId
    }
    
    init(sender: TimelineItemSender) {
        userID = sender.id
        displayName = sender.displayName
        avatarURL = sender.avatarURL
    }
    
    init(sdkUserProfile: MatrixRustSDK.UserProfile) {
        userID = sdkUserProfile.userId
        displayName = sdkUserProfile.displayName
        avatarURL = sdkUserProfile.avatarUrl.flatMap(URL.init(string:))
        primaryZeroId = nil
    }
    
    init(sdkRoomHero: MatrixRustSDK.RoomHero) {
        userID = sdkRoomHero.userId
        displayName = sdkRoomHero.displayName
        avatarURL = sdkRoomHero.avatarUrl.flatMap(URL.init(string:))
        primaryZeroId = nil
    }
    
    init(zeroSearchedUser: ZMatrixSearchedUser, avatarUrl: String?) {
        userID = zeroSearchedUser.matrixId
        displayName = zeroSearchedUser.name
        avatarURL = avatarUrl.flatMap(URL.init(string:))
        primaryZeroId = zeroSearchedUser.primaryZID
    }
    
    init(sdkUserProfile: MatrixRustSDK.UserProfile, zeroUserProfile: ZMatrixSearchedUser?) {
        userID = sdkUserProfile.userId
        displayName = sdkUserProfile.displayName
        avatarURL = sdkUserProfile.avatarUrl.flatMap(URL.init(string:))
        primaryZeroId = zeroUserProfile?.primaryZID
    }
    
    init(zeroUserProfile: ZMatrixUser?, sdkUserProfile: MatrixRustSDK.UserProfile) {
        userID = sdkUserProfile.userId
        displayName = sdkUserProfile.displayName
        avatarURL = sdkUserProfile.avatarUrl.flatMap(URL.init(string:))
        primaryZeroId = zeroUserProfile?.primaryZID
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
    
    init(zeroSearchResults: [ZMatrixSearchedUser], mappedMatrixUsers: [UserProfile]) {
        results = zeroSearchResults.map { user in
            let avatarUrl = mappedMatrixUsers.first(where: { $0.userId == user.matrixId })?.avatarUrl
            return UserProfileProxy(zeroSearchedUser: user, avatarUrl: avatarUrl)
        }
        limited = true
    }
}

extension UserProfileProxy: Identifiable {
    var id: String { userID }
}

extension UserProfileProxy {
    func toZeroFeedProfile() -> ZPostUserProfile {
        .init(userId: userID.matrixIdToCleanHex(), createdAt: nil, primaryZid: primaryZeroId ?? "",
              firstName: displayName ?? "", profileImage: avatarURL?.absoluteString,
              publicAddress: nil, followersCount: nil, followingCount: nil)
    }
}
