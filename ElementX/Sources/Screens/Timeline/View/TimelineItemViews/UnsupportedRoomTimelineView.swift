//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct UnsupportedRoomTimelineView: View {
    let timelineItem: UnsupportedRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            Label("\(timelineItem.body) (\(timelineItem.eventType)): \(timelineItem.error)",
                  icon: \.warning,
                  iconSize: .small,
                  relativeTo: .compound.bodyLG)
                .labelStyle(RoomTimelineViewPlaceholderLabelStyle())
        }
    }
}

struct UnsupportedRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        body.environmentObject(viewModel.context)
    }
    
    static var body: some View {
        VStack(alignment: .leading, spacing: 20.0) {
            UnsupportedRoomTimelineView(timelineItem: itemWith(text: "Unsupported",
                                                               timestamp: .mock,
                                                               isOutgoing: false,
                                                               senderId: "Bob"))
            
            UnsupportedRoomTimelineView(timelineItem: itemWith(text: "Some other text",
                                                               timestamp: .mock,
                                                               isOutgoing: true,
                                                               senderId: "Anne"))
        }
    }
    
    private static func itemWith(text: String, timestamp: Date, isOutgoing: Bool, senderId: String) -> UnsupportedRoomTimelineItem {
        UnsupportedRoomTimelineItem(id: .randomEvent,
                                    body: text,
                                    eventType: "event.type",
                                    error: "something went wrong",
                                    timestamp: timestamp,
                                    isOutgoing: isOutgoing,
                                    isEditable: false,
                                    canBeRepliedTo: true,
                                    sender: .init(id: senderId))
    }
}
