//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

public struct ZPostMeowAmount: Encodable {
    public let amount: String
    
    init(amount: Int) {
        let actualAmount = (Int64(amount) * 1_000_000_000_000_000_000)
        self.amount = String(actualAmount)
    }
}
