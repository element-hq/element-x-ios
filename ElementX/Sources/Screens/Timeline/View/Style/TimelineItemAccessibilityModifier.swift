//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// How a timeline item takes part in an active multi-selection, for accessibility purposes.
enum TimelineItemAccessibilitySelection {
    /// No selection is active, the item offers its regular message actions.
    case none
    /// A selection is active, the item acts as a toggle when it can be selected.
    case selecting(isSelected: Bool)
}

private struct TimelineItemAccessibilityModifier: ViewModifier {
    let timelineItem: RoomTimelineItemProtocol
    let selection: TimelineItemAccessibilitySelection
    let action: () -> Void
    
    private var isSelecting: Bool {
        if case .selecting = selection {
            return true
        }
        return false
    }
    
    func body(content: Content) -> some View {
        switch timelineItem {
        case is PollRoomTimelineItem:
            // The answers stay traversable on their own, unless the whole poll acts as a selection toggle.
            if isSelecting {
                interactions(for: content.accessibilityElement(children: .combine))
            } else {
                interactions(for: content)
            }
        // A gallery is a container so that each of its attachments can be focussed on its own.
        // Everything that isn't an attachment is announced when entering it, as the caption and
        // the send info are hidden where they're shown to avoid being read twice.
        case let timelineItem as GalleryRoomTimelineItem:
            interactions(for: content
                .accessibilityElement(children: isSelecting ? .combine : .contain)
                .accessibilityLabel { _ in
                    Text(timelineItem.sender.displayName ?? timelineItem.sender.id)
                    if let caption = timelineItem.content.caption, !caption.isBlank {
                        Text(caption)
                    }
                    Text(timelineItem.localizedSendInfo)
                })
        case let timelineItem as EventBasedTimelineItemProtocol:
            interactions(for: content
                .accessibilityRepresentation {
                    VStack(spacing: 8) {
                        Text(timelineItem.sender.displayName ?? timelineItem.sender.id)
                        content
                    }
                }
                .accessibilityElement(children: .combine))
        default:
            content
                .accessibilityElement(children: .combine)
        }
    }
    
    /// Offers the message actions, or turns the item into a selection toggle while selecting.
    @ViewBuilder
    private func interactions(for view: some View) -> some View {
        switch selection {
        case .none:
            view
                .accessibilityActions {
                    Button(L10n.commonMessageActions) {
                        action()
                    }
                }
        case .selecting(let isSelected):
            if let item = timelineItem as? EventBasedTimelineItemProtocol, item.isBulkSelectable {
                view
                    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                    .accessibilityAction(.default, action)
            } else {
                // Items that can't be selected are inert while selecting.
                view
            }
        }
    }
}

extension View {
    func timelineItemAccessibility(_ timelineItem: RoomTimelineItemProtocol,
                                   selection: TimelineItemAccessibilitySelection = .none,
                                   action: @escaping () -> Void) -> some View {
        modifier(TimelineItemAccessibilityModifier(timelineItem: timelineItem, selection: selection, action: action))
    }
}
