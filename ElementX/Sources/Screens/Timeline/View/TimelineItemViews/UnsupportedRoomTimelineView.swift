//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct UnsupportedRoomTimelineView: View {
    let timelineItem: UnsupportedRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            Label {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(timelineItem.body): \(timelineItem.eventType)")
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(timelineItem.error)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.compound.bodySM)
                }
            } icon: {
                CompoundIcon(\.warning, size: .small, relativeTo: .compound.bodyLG)
            }
            .labelStyle(RoomTimelineViewLabelStyle())
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
            UnsupportedRoomTimelineView(timelineItem: itemWith(text: "Text",
                                                               timestamp: "Now",
                                                               isOutgoing: false,
                                                               senderId: "Bob"))
            
            UnsupportedRoomTimelineView(timelineItem: itemWith(text: "Some other text",
                                                               timestamp: "Later",
                                                               isOutgoing: true,
                                                               senderId: "Anne"))
        }
    }
    
    private static func itemWith(text: String, timestamp: String, isOutgoing: Bool, senderId: String) -> UnsupportedRoomTimelineItem {
        UnsupportedRoomTimelineItem(id: .random,
                                    body: text,
                                    eventType: "Some Event Type",
                                    error: "Something went wrong",
                                    timestamp: timestamp,
                                    isOutgoing: isOutgoing,
                                    isEditable: false,
                                    canBeRepliedTo: true,
                                    sender: .init(id: senderId))
    }
}
