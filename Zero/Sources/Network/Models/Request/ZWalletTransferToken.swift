//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

public struct ZWalletTransferToken: Encodable {
    public let to: String
    public let amount: String
    public let tokenAddress: String
    public let chainId: Int
    
    init(recipientWalletAddress: String, amount: String, tokenAddress: String, chainId: Int) {
        self.to = recipientWalletAddress
        self.amount = amount
        self.tokenAddress = tokenAddress
        self.chainId = chainId
    }
}
