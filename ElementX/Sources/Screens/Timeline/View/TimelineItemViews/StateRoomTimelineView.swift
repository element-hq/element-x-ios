//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct StateRoomTimelineView: View {
    let timelineItem: StateRoomTimelineItem
    
    var body: some View {
        Text(timelineItem.body)
            .font(.compound.bodySM)
            .multilineTextAlignment(.center)
            .foregroundColor(.compound.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 36.0)
            .padding(.vertical, 8.0)
    }
}

struct StateRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        body
    }
    
    static var body: some View {
        StateRoomTimelineView(timelineItem: item)
    }
    
    static let item = StateRoomTimelineItem(id: .random,
                                            body: "Alice joined",
                                            timestamp: "Now",
                                            isOutgoing: false,
                                            isEditable: false,
                                            canBeRepliedTo: true,
                                            sender: .init(id: ""))
}
