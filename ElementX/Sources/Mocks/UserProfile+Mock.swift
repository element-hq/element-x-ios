//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

extension UserProfileProxy {
    // Mocks
    static var mockAlice: UserProfileProxy {
        .init(userID: "@alice:matrix.org", displayName: "Alice", avatarURL: "mxc://matrix.org/UcCimidcvpFvWkPzvjXMQPHA")
    }

    static var mockBob: UserProfileProxy {
        .init(userID: "@bob:matrix.org", displayName: "Bob", avatarURL: nil)
    }

    static var mockBobby: UserProfileProxy {
        .init(userID: "@bobby:matrix.org", displayName: "Bobby", avatarURL: nil)
    }

    static var mockCharlie: UserProfileProxy {
        .init(userID: "@charlie:matrix.org", displayName: "Charlie", avatarURL: nil)
    }
    
    static var mockVerbose: UserProfileProxy {
        .init(userID: "@charlie:matrix.org", displayName: "Charlie is the best display name", avatarURL: nil)
    }
}
