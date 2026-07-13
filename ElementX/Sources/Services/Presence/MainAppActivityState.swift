//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

nonisolated enum MainAppActivityState: String, Codable, Sendable {
    case foregroundActive
    case inactive
    case background
    case terminated
}

nonisolated struct MainAppActivityStateSnapshot: Codable, Equatable, Sendable {
    static let `default` = MainAppActivityStateSnapshot(state: .terminated, lastUpdatedSystemUptime: nil)
    
    let state: MainAppActivityState
    let lastUpdatedSystemUptime: TimeInterval?
}
