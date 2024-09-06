//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct SeparatorRoomTimelineView: View {
    let timelineItem: SeparatorRoomTimelineItem
    
    var body: some View {
        Text(timelineItem.text)
            .font(.compound.bodySMSemibold)
            .foregroundColor(.compound.textPrimary)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 36.0)
            .padding(.vertical, 8.0)
    }
}

struct SeparatorRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        let item = SeparatorRoomTimelineItem(id: .init(timelineID: "Separator"), text: "This is a separator")
        SeparatorRoomTimelineView(timelineItem: item)
    }
}
