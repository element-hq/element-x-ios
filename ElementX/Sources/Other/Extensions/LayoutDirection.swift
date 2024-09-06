//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

extension LayoutDirection {
    var isolateLayoutUnicodeString: String {
        switch self {
        case .leftToRight:
            return "\u{2066}"
        case .rightToLeft:
            return "\u{2067}"
        default:
            return ""
        }
    }
}
