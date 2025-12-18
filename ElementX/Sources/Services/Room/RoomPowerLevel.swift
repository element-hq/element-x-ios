//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

enum RoomPowerLevel: Hashable, Comparable {
    case value(Int)
    case infinite
    
    init(rustPowerLevel: PowerLevel) {
        self = rustPowerLevel.toRoomPowerLevel
    }
    
    init(value: Int) {
        self = .value(value)
    }
    
    init(value: Int64) {
        self = .value(Int(value))
    }
    
    var rustPowerLevel: PowerLevel {
        switch self {
        case .infinite: .infinite
        case .value(let value): .value(value: Int64(value))
        }
    }
    
    var role: RoomRole {
        RoomRole(powerLevel: self)
    }
}

extension PowerLevel {
    var toRoomPowerLevel: RoomPowerLevel {
        switch self {
        case .infinite: .infinite
        case .value(let value): .value(Int(value))
        }
    }
}
