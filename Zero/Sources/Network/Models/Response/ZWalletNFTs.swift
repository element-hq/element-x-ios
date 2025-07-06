//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct ZWalletNFTs: Codable {
    let nfts: [NFT]
    let nextPageParams: NextPageParams?
}

struct NFT: Codable {
    let animationUrl: String?
    let collectionAddress: String
    let collectionName: String?
    let id: String
    let imageUrl: String?
    let isUnique: Bool
    let metadata: NFTMetadata
}

struct NFTMetadata: Codable {
    let attributes: [NFTAttribute]
    let name: String?
    let description: String?
}

struct NFTAttribute: Codable {
    let traitType: String
    let value: String

    enum CodingKeys: String, CodingKey {
        case traitType = "traitType"
        case value
    }
}
