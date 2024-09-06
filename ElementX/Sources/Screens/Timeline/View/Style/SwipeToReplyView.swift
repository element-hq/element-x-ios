//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct SwipeToReplyView: View {
    let timelineItem: RoomTimelineItemProtocol
    
    var body: some View {
        CompoundIcon(\.reply)
            .foregroundColor(.compound.iconPrimary)
            .accessibilityHidden(true)
    }
}

struct SwipeToReplyView_Previews: PreviewProvider, TestablePreview {
    static let timelineItem = TextRoomTimelineItem(id: .init(timelineID: ""),
                                                   timestamp: "",
                                                   isOutgoing: true,
                                                   isEditable: true,
                                                   canBeRepliedTo: true,
                                                   isThreaded: false,
                                                   sender: .init(id: ""),
                                                   content: .init(body: ""))
    
    static var previews: some View {
        SwipeToReplyView(timelineItem: timelineItem)
    }
}
