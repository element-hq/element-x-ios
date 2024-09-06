//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

struct EmojiItem: Equatable, Identifiable {
    var id: String {
        label
    }

    let label: String
    let unicode: String
    let keywords: [String]
    let shortcodes: [String]
}
