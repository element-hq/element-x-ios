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
    let amount: String?
    let timestamp: String
    let tokenId: String?
    let type: String
}

extension WalletTransaction {
    var formattedAmount: String {
        if let amount = amount, let doubleAmount = Double(amount), doubleAmount > 0 {
//            return String(format: "%.2f", doubleAmount)
            return doubleAmount.formatToThousandSeparatedString()
        } else {
            return amount ?? "0"
        }
    }
    
    func meowPriceFormatted(ref: ZeroCurrency?) -> String {
        return ZeroWalletUtil.shared.meowPriceFormatted(tokenAmount: amount, refPrice: ref)
    }
    
    var isMeowTokenTransaction: Bool {
        return token.symbol.lowercased() == "MEOW".lowercased()
    }
    
    var isVMeowTokenTransaction: Bool {
        return token.symbol.lowercased() == "vMEOW".lowercased()
    }
    
    var isClaimableTokenTransaction: Bool {
        isMeowTokenTransaction || isVMeowTokenTransaction
    }
}

struct TransactionToken: Codable {
    let symbol: String
    let name: String
    let logo: String?
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
