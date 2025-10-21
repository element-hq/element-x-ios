//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

struct FrequentlyUsedEmoji: Codable, Hashable {
    let count: UInt
    let key: String
    
    static func == (lhs: FrequentlyUsedEmoji, rhs: FrequentlyUsedEmoji) -> Bool {
        lhs.key == rhs.key
    }
}
