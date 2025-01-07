//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

enum TimelineGroupStyle: Hashable {
    case single
    case first
    case middle
    case last

    var shouldShowSenderDetails: Bool {
        switch self {
        case .single, .first:
            return true
        default:
            return false
        }
    }
}

// MARK: - Environment

extension EnvironmentValues {
    @Entry var timelineGroupStyle: TimelineGroupStyle = .single
}
