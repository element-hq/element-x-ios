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

enum TimelineStyle: String, CaseIterable {
    case plain
    case bubbles

    /// List row insets for a timeline
    var rowInsets: EdgeInsets {
        switch self {
        case .plain:
            return EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20)
        case .bubbles:
            return EdgeInsets(top: 1, leading: 8, bottom: 1, trailing: 8)
        }
    }
}

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

private struct TimelineStyleKey: EnvironmentKey {
    static let defaultValue = TimelineStyle.bubbles
}

private struct TimelineGroupStyleKey: EnvironmentKey {
    static let defaultValue = TimelineGroupStyle.single
}

extension EnvironmentValues {
    var timelineStyle: TimelineStyle {
        get { self[TimelineStyleKey.self] }
        set { self[TimelineStyleKey.self] = newValue }
    }
    
    var timelineGroupStyle: TimelineGroupStyle {
        get { self[TimelineGroupStyleKey.self] }
        set { self[TimelineGroupStyleKey.self] = newValue }
    }
}

extension View {
    func timelineStyle(_ style: TimelineStyle) -> some View {
        environment(\.timelineStyle, style)
    }
    
    func timelineGroupStyle(_ groupStyle: TimelineGroupStyle) -> some View {
        environment(\.timelineGroupStyle, groupStyle)
    }
}
