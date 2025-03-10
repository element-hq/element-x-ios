//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct ZNewPostUnsignedMessage: Codable {
    let createdAt: String
    let text: String
    let walletAddress: String
    let zid: String

    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case text
        case walletAddress = "wallet_address"
        case zid
    }

    init(text: String, walletAddress: String, zid: String) {
        self.createdAt = String(Int(Date().timeIntervalSince1970 * 1000)) // Current time in milliseconds
        self.text = text
        self.walletAddress = walletAddress
        self.zid = zid
    }
}
