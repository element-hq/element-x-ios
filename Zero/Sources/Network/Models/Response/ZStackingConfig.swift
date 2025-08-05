//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct ZStackingConfig: Codable {
    let timestamp: String
    let rewardsPerPeriod: String
    let periodLength: String
    let minimumLockTime: String
    let minimumRewardsMultiplier: String
    let maximumRewardsMultiplier: String
    let canExit: Bool
}
