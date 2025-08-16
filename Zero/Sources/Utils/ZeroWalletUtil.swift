//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class ZeroWalletUtil {
    static let shared = ZeroWalletUtil()
    
    private init() { }
    
    func meowPrice(tokenAmount: String?, refPrice: ZeroCurrency?) -> Double {
        if let amount = Double(tokenAmount ?? "0"), amount > 0,
           let currency = refPrice, let price = currency.price {
            return amount * price
        } else {
            return 0
        }
    }
    
    func meowPrice(tokenAmount: Double, refPrice: ZeroCurrency?) -> Double {
        if let currency = refPrice, let price = currency.price {
            return tokenAmount * price
        } else {
            return 0
        }
    }
    
    func meowPriceFormatted(tokenAmount: String?, refPrice: ZeroCurrency?) -> String {
        return meowPrice(tokenAmount: tokenAmount, refPrice: refPrice).formatToThousandSeparatedString()
    }
}
