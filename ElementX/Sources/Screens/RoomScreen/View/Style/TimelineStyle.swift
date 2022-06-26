//
//  TimelineStyle.swift
//  ElementX
//
//  Created by Ismail on 24.06.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import SwiftUI

enum TimelineStyle: String, CaseIterable {
    case plain
    case bubbled

    /// List row insets for a timeline
    var listRowInsets: EdgeInsets {
        switch self {
        case .plain:
            return EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20)
        case .bubbled:
            return EdgeInsets(top: 1, leading: 8, bottom: 1, trailing: 8)
        }
    }
}

extension TimelineStyle: CustomStringConvertible {
    var description: String {
        switch self {
        case .plain:
            return ElementL10n.roomTimelineStylePlainLongDescription
        case .bubbled:
            return ElementL10n.roomTimelineStyleBubbledLongDescription
        }
    }
}

// MARK: - Environment

private struct TimelineStyleKey: EnvironmentKey {
    static let defaultValue = BuildSettings.defaultRoomTimelineStyle
}

extension EnvironmentValues {
    var timelineStyle: TimelineStyle {
        get { self[TimelineStyleKey.self] }
        set { self[TimelineStyleKey.self] = newValue }
    }
}

extension View {
    func timelineStyle(_ style: TimelineStyle) -> some View {
        environment(\.timelineStyle, style)
    }
}
