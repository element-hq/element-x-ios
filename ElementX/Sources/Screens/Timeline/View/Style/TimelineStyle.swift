//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
