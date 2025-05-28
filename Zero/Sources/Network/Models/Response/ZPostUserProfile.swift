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
    let firstName: String
    let profileImage: String?
    let publicAddress: String?
    let followersCount: String?
    let followingCount: String?
}

extension ZPostUserProfile {
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
