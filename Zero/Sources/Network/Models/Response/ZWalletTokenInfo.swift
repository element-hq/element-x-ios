//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct ZWalletTokenInfo: Codable {
    public let name: String
    public let symbol: String
    public let decimals: Int
    public let address: String
}
