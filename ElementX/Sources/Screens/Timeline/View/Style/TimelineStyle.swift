//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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

private struct TimelineGroupStyleKey: EnvironmentKey {
    static let defaultValue = TimelineGroupStyle.single
}

extension EnvironmentValues {
    var timelineGroupStyle: TimelineGroupStyle {
        get { self[TimelineGroupStyleKey.self] }
        set { self[TimelineGroupStyleKey.self] = newValue }
    }
}
