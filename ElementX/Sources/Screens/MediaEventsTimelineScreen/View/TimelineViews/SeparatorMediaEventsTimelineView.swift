//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct SeparatorMediaEventsTimelineView: View {
    let group: MediaEventsTimelineGroup
    
    var body: some View {
        Text(group.title)
            .font(.compound.bodySMSemibold)
            .foregroundColor(.compound.textPrimary)
            .frame(alignment: .center)
            .padding(.vertical, 16)
    }
}

struct SeparatorMediaEventsTimelineView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        let item = SeparatorRoomTimelineItem(id: .virtual(uniqueID: .init(id: "Separator")),
                                             timestamp: .mock)
        
        SeparatorMediaEventsTimelineView(group: .init(id: item.id.uniqueID.id,
                                                      title: "Group",
                                                      items: []))
    }
}
