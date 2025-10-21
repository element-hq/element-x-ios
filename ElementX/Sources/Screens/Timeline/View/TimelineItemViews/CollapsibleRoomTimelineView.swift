//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct CollapsibleRoomTimelineView: View {
    enum AccessibilityFocus {
        case disclosure
        case events
    }
    
    private let timelineItem: CollapsibleTimelineItem
    private let groupedViewStates: [RoomTimelineItemViewState]
    
    @State private var isExpanded = false
    @AccessibilityFocusState private var accessibilityFocusState: AccessibilityFocus?
    
    init(timelineItem: CollapsibleTimelineItem) {
        self.timelineItem = timelineItem
        groupedViewStates = timelineItem.items.map { .init(item: $0, groupStyle: .single) }
    }
    
    var body: some View {
        VStack(spacing: 0.0) {
            Button {
                if !UIAccessibility.isVoiceOverRunning {
                    withElementAnimation {
                        isExpanded.toggle()
                    }
                } else {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .center, spacing: 8) {
                    Text(L10n.screenRoomTimelineStateChanges(timelineItem.items.count))
                    Text(Image(systemName: "chevron.forward"))
                        .accessibilityLabel(isExpanded ? L10n.screenRoomGroupedStateEventsReduce : L10n.screenRoomGroupedStateEventsExpand)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.elementDefault, value: isExpanded)
                }
                .font(.compound.bodySM)
                .foregroundColor(.compound.textSecondary)
                .padding(.horizontal, 36.0)
                .padding(.vertical, 12.0)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .padding(.top, 8.0)
            .accessibilityFocused($accessibilityFocusState, equals: .disclosure)
            
            if isExpanded {
                VStack(spacing: 0.0) {
                    ForEach(groupedViewStates) { viewState in
                        RoomTimelineItemView(viewState: viewState)
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityFocused($accessibilityFocusState, equals: .events)
            }
        }
        .onChange(of: isExpanded) { _, newValue in
            accessibilityFocusState = newValue ? .events : .disclosure
        }
    }
}

struct CollapsibleRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let item = CollapsibleTimelineItem(items: [
        SeparatorRoomTimelineItem(id: .virtual(uniqueID: .init("First separator")), timestamp: .mock),
        SeparatorRoomTimelineItem(id: .virtual(uniqueID: .init("Second separator")), timestamp: .mock)
    ])
    
    static var previews: some View {
        CollapsibleRoomTimelineView(timelineItem: item)
    }
}
