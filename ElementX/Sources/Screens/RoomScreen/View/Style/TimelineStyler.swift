//
//  TimelineStyler.swift
//  ElementX
//
//  Created by Ismail on 24.06.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - TimelineStyler

class TimelineStyler: ObservableObject, Identifiable {
    var style: TimelineStyle

    fileprivate init(style: TimelineStyle) {
        self.style = style
    }

    static let plain = TimelineStyler(style: .plain)
    static let bubbled = TimelineStyler(style: .bubbled)

    var shortDescription: String {
        style.shortDescription
    }

    @ViewBuilder
    /// Builds a styled view fron given timeline item and content. Can add a sender info if configured.
    /// - Parameters:
    ///   - timelineItem: timeline item
    ///   - content: content
    /// - Returns: Styled content view
    func styled<Content: View>(timelineItem: EventBasedTimelineItemProtocol,
                               @ViewBuilder content: @escaping () -> Content) -> some View {
        switch style {
        case .plain:
            TimelineItemPlainStylerView(timelineItem: timelineItem, content: content)
        case .bubbled:
            TimelineItemBubbledStylerView(timelineItem: timelineItem, content: content)
        }
    }

    /// List row insets for a timeline
    var listRowInsets: EdgeInsets {
        switch style {
        case .plain:
            return EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20)
        case .bubbled:
            return EdgeInsets(top: 1, leading: 8, bottom: 1, trailing: 8)
        }
    }
}

extension TimelineStyler: CustomStringConvertible {
    var description: String {
        style.description
    }
}

extension TimelineStyler: CaseIterable {
    static var allCases: [TimelineStyler] {
        TimelineStyle.allCases.map { TimelineStyler(style: $0) }
    }
}

// MARK: - Environment

private struct TimelineStylerKey: EnvironmentKey {
    static let defaultValue = TimelineStyler(style: ElementSettings.shared.timelineStyle)
}

extension EnvironmentValues {
    var timelineStyler: TimelineStyler {
        get { self[TimelineStylerKey.self] }
        set { self[TimelineStylerKey.self] = newValue }
    }
}

extension View {
    func timelineStyler(_ styler: TimelineStyler) -> some View {
        environment(\.timelineStyler, styler)
    }
}
