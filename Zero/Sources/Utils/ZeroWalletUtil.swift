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
    
    func meowPriceFormatted(tokenAmount: String?, refPrice: ZeroCurrency?) -> String {
        if let amount = Double(tokenAmount ?? "0"), amount > 0,
           let currency = refPrice, let price = currency.price {
            return "$\((amount * price).formatToSuffix(maxFracDigits: 4))"
        } else {
            return "-"
        }
    }
}
