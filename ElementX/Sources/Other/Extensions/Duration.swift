//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

extension Duration {
    /// Use this to to convert `Duration` in seconds as a `Double`.
    /// `components.seconds` is not reliable because its type is `Int64`.
    var seconds: Double {
        Double(components.seconds) + Double(components.attoseconds) * 1e-18
    }
}
