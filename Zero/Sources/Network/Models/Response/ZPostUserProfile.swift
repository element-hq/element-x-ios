//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct ZPostUserProfile: Codable, Hashable {
    let userId: String
    let createdAt: String?
    let primaryZid: String?
    var firstName: String
    var profileImage: String?
    let publicAddress: String?
    let followersCount: String?
    let followingCount: String?
    
    init(userId: String,
         createdAt: String? = nil,
         firstName: String,
         profileImage: String?,
         primaryZid: String?,
         publicAddress: String?,
         followersCount: String?,
         followingCount: String?
    ) {
        self.userId = userId
        self.createdAt = createdAt
        self.primaryZid = primaryZid
        self.firstName = firstName
        self.profileImage = profileImage
        self.publicAddress = publicAddress
        self.followersCount = followersCount
        self.followingCount = followingCount
    }
}

extension ZPostUserProfile {
    var primaryZIdOrAddress: String? {
        primaryZid ?? publicAddress
    }
    
    var zIdOrPublicAddressDisplayText: String? {
        if let id = primaryZid ?? publicAddress {
            if id.hasPrefix(ZeroContants.ZERO_WALLET_ADDRESS_PREFIX) {
                return displayFormattedAddress(id)
            } else {
                return id
            }
        }
        return nil
    }
    
    func withFallbackValues(_ fallbackProfile: ZPostUserProfile) -> ZPostUserProfile {
        var mUserProfile = self
        if mUserProfile.firstName.isEmpty {
            mUserProfile.firstName = fallbackProfile.firstName
        }
        if mUserProfile.profileImage == nil {
            mUserProfile.profileImage = fallbackProfile.profileImage
        }
        return mUserProfile
    }
}

struct ZPostUserFollowingStatus: Codable {
    let isFollowing: Bool
}

struct ZPostUserFollowResponse: Codable {
    let follow: FollowPostUser
}

struct FollowPostUser: Codable {
    let id: String
    let followerId: String
    let followingId: String
    let createdAt: String
    let updatedAt: String
}
