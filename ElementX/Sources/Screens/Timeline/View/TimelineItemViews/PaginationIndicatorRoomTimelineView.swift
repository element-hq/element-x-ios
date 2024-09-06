//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct PaginationIndicatorRoomTimelineView: View {
    let timelineItem: PaginationIndicatorRoomTimelineItem
    
    var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity)
            .padding(.top, 12) // Bottom spacing comes from the next item (date separator).
    }
}

struct PaginationIndicatorRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        let item = PaginationIndicatorRoomTimelineItem(position: .start)
        PaginationIndicatorRoomTimelineView(timelineItem: item)
    }
}
