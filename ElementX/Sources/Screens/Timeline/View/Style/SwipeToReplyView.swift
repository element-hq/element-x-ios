//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
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
    static let timelineItem = TextRoomTimelineItem(id: .randomEvent,
                                                   timestamp: .mock,
                                                   isOutgoing: true,
                                                   isEditable: true,
                                                   canBeRepliedTo: true,
                                                   sender: .init(id: ""),
                                                   content: .init(body: ""))
    
    static var previews: some View {
        SwipeToReplyView(timelineItem: timelineItem)
    }
}
