//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct ZWalletTokenBalances: Codable {
    let tokens: [ZWalletToken]
    let nextPageParams: NextPageParams?
}

struct ZWalletToken: Codable {
    let tokenAddress: String
    let symbol: String
    let name: String
    let amount: String
    let logo: String?
    let decimals: Int
}

extension ZWalletToken {
    var formattedAmount: String {
        String(format: "%.2f", Double(amount) ?? 0)
    }
}

struct NextPageParams: Codable {
    let itemsCount: Int
    let tokenName: String?
    let tokenType: String?
    let value: Int

    enum CodingKeys: String, CodingKey {
        case itemsCount = "items_count"
        case tokenName = "token_name"
        case tokenType = "token_type"
        case value
    }
}
