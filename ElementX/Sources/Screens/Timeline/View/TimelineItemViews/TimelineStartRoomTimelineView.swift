//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct TimelineStartRoomTimelineView: View {
    let timelineItem: TimelineStartRoomTimelineItem
    
    var body: some View {
        Text(title)
            .font(.compound.bodySM)
            .foregroundColor(.compound.textSecondary)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
    }
    
    var title: String {
        var text = L10n.screenRoomTimelineBeginningOfRoomNoName
        if let name = timelineItem.name {
            text = L10n.screenRoomTimelineBeginningOfRoom(name)
        }
        return text
    }
}

struct TimelineStartRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        let item = TimelineStartRoomTimelineItem(name: "Alice and Bob")
        TimelineStartRoomTimelineView(timelineItem: item)
    }
}
