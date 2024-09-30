//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

private struct TimelineItemAccessibilityModifier: ViewModifier {
    let timelineItem: RoomTimelineItemProtocol
    let action: () -> Void
    
    @ViewBuilder
    func body(content: Content) -> some View {
        switch timelineItem {
        case is PollRoomTimelineItem, is VoiceMessageRoomTimelineItem:
            content
                .accessibilityActions {
                    Button(L10n.commonMessageActions) {
                        action()
                    }
                }
        case let timelineItem as EventBasedTimelineItemProtocol:
            content
                .accessibilityRepresentation {
                    VStack(spacing: 8) {
                        Text(timelineItem.sender.displayName ?? timelineItem.sender.id)
                        content
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityActions {
                    Button(L10n.commonMessageActions) {
                        action()
                    }
                }
        default:
            content
                .accessibilityElement(children: .combine)
        }
    }
}

extension View {
    func timelineItemAccessibility(_ timelineItem: RoomTimelineItemProtocol, action: @escaping () -> Void) -> some View {
        modifier(TimelineItemAccessibilityModifier(timelineItem: timelineItem, action: action))
    }
}
