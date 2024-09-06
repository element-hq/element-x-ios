//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import SwiftUI

struct RedactedRoomTimelineView: View {
    let timelineItem: RedactedRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            Label(timelineItem.body, icon: \.delete, iconSize: .small, relativeTo: .compound.bodyLG)
                .labelStyle(RoomTimelineViewLabelStyle())
                .imageScale(.small) // Smaller icon so that the bubble remains rounded on the outside.
        }
    }
}

struct RedactedRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        VStack(alignment: .leading, spacing: 20.0) {
            RedactedRoomTimelineView(timelineItem: itemWith(text: L10n.commonMessageRemoved,
                                                            timestamp: "Later",
                                                            senderId: "Anne"))
        }
        .environmentObject(viewModel.context)
    }
    
    private static func itemWith(text: String, timestamp: String, senderId: String) -> RedactedRoomTimelineItem {
        RedactedRoomTimelineItem(id: .random,
                                 body: text,
                                 timestamp: timestamp,
                                 isOutgoing: false,
                                 isEditable: false,
                                 canBeRepliedTo: false,
                                 sender: .init(id: senderId))
    }
}
