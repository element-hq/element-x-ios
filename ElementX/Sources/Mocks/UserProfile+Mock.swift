//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension UserProfile {
    /// Mocks
    static var mockAlice: UserProfile {
        .init(userID: "@alice:matrix.org", displayName: "Alice", avatarURL: "mxc://matrix.org/UcCimidcvpFvWkPzvjXMQPHA")
    }
    
    static var mockBob: UserProfile {
        .init(userID: "@bob:matrix.org", displayName: "Bob", avatarURL: nil)
    }
    
    static var mockBobby: UserProfile {
        .init(userID: "@bobby:matrix.org", displayName: "Bobby", avatarURL: nil)
    }
    
    static var mockCharlie: UserProfile {
        .init(userID: "@charlie:matrix.org", displayName: "Charlie", avatarURL: nil)
    }
    
    static var mockDan: UserProfile {
        .init(userID: "@dan:matrix.org", displayName: "Dan", avatarURL: .mockMXCUserAvatar)
    }
    
    static var mockVerbose: UserProfile {
        .init(userID: "@charlie:matrix.org", displayName: "Charlie is the best display name", avatarURL: nil)
    }
}
