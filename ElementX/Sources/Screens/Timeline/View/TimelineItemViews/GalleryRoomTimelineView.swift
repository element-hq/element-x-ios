//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct GalleryRoomTimelineView: View {
    let timelineItem: GalleryRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            // Placeholder rendering — the grid/list media views land in a follow-up.
            FormattedBodyText(text: timelineItem.content.caption ?? timelineItem.content.body,
                              trailingReservedSize: timelineItem.trailingReservedSize,
                              boostFontSize: timelineItem.shouldBoost)
        }
    }
}
