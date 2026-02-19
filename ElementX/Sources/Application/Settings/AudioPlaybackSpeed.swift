//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

enum AudioPlaybackSpeed: Float, CaseIterable, Codable {
    case `default` = 1.0
    case fast = 1.5
    case fastest = 2.0
    case slow = 0.5
    
    var label: String {
        switch self {
        case .default, .fastest:
            rawValue.formatted(.number.precision(.fractionLength(0))) + "×"
        case .fast, .slow:
            rawValue.formatted(.number.precision(.fractionLength(1))) + "×"
        }
    }
    
    var placeholder: String {
        0.0.formatted(.number.precision(.fractionLength(1))) + "×"
    }
    
    var next: Self {
        guard let index = Self.allCases.firstIndex(of: self) else {
            return .default
        }
        return Self.allCases[(index + 1) % Self.allCases.count]
    }
}
