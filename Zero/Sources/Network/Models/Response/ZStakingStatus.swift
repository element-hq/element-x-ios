//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct ZStakingStatus: Codable {
    let unlockedTimestamp: String
    let amountStaked: String
    let amountStakedLocked: String
    let owedRewards: String
    let owedRewardsLocked: String
    let lastTimestamp: String
    let lastTimestampLocked: String
}
