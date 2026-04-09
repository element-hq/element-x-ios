//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct UserToInvite: Identifiable {
    /// The profile of the user being invited.
    var user: UserProfileProxy
    
    /// The ID of the user being invited.
    var id: String {
        user.id
    }
    
    /// Whether we have the cryptographic identity of this user cached locally.
    var isUnknown: Bool
    
    /// The display name of the user being invited
    var displayName: String? {
        user.displayName
    }
    
    /// The avatar URL of the user's profile, if available.
    var avatarURL: URL? {
        user.avatarURL
    }
}
