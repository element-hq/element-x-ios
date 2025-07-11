//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct ZWalletTransactionReceipt: Codable {
    public let status: String
    public let blockExplorerUrl: String
    public let transactionHash: String
}
