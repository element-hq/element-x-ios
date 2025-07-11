//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

public struct ZWalletTransferNFT: Encodable {
    public let to: String
    public let tokenId: String
    public let nftAddress: String
    
    init(recipientWalletAddress: String, tokenId: String, nftAddress: String) {
        self.to = recipientWalletAddress
        self.tokenId = tokenId
        self.nftAddress = nftAddress
    }
}
