//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

private struct TimelineItemAccessibilityModifier: ViewModifier {
    let timelineItem: RoomTimelineItemProtocol
    let action: () -> Void
    
    func body(content: Content) -> some View {
        switch timelineItem {
        case is PollRoomTimelineItem:
            content
                .accessibilityActions {
                    Button(L10n.commonMessageActions) {
                        action()
                    }
                }
        // A gallery is a container so that each of its attachments can be focussed on its own.
        // Everything that isn't an attachment is announced when entering it, as the caption and
        // the send info are hidden where they're shown to avoid being read twice.
        case let timelineItem as GalleryRoomTimelineItem:
            content
                .accessibilityElement(children: .contain)
                .accessibilityLabel { _ in
                    Text(timelineItem.sender.displayName ?? timelineItem.sender.id)
                    if let caption = timelineItem.content.caption, !caption.isBlank {
                        Text(caption)
                    }
                    Text(timelineItem.localizedSendInfo)
                }
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
