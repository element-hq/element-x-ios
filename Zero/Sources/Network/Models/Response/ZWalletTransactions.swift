//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct ZWalletTransactions: Codable {
    let transactions: [WalletTransaction]
    let nextPageParams: TransactionNextPageParams?
}

struct WalletTransaction: Codable {
    let hash: String
    let from: String
    let to: String
    let action: String
    let token: TransactionToken
    let amount: String
    let timestamp: String
}

struct TransactionToken: Codable {
    let symbol: String
    let name: String
    let logo: String
    let decimals: Int
}

struct TransactionNextPageParams: Codable {
    let blockNumber: Int
    let index: Int

    enum CodingKeys: String, CodingKey {
        case blockNumber = "block_number"
        case index
    }
}
