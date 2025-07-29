//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

struct PowerLevelProxy: Hashable, Comparable {
    static func < (lhs: PowerLevelProxy, rhs: PowerLevelProxy) -> Bool {
        switch (lhs.rustPowerLevel, rhs.rustPowerLevel) {
        case (.value(let lhsValue), .value(let rhsValue)):
            return lhsValue < rhsValue
        case (.infinite, _):
            return false
        case (_, .infinite):
            return true
        }
    }
    
    let rustPowerLevel: PowerLevel
}

extension PowerLevelProxy {
    init(value: Int) {
        rustPowerLevel = .value(value: Int64(value))
    }
    
    init(value: Int64) {
        rustPowerLevel = .value(value: value)
    }
    
    static let infinite: PowerLevelProxy = .init(rustPowerLevel: .infinite)
}
