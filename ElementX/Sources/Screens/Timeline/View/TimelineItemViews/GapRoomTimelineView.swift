//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// A small inline spinner marking a gap in the timeline; asks for the gap to
/// be resolved whenever it's visible.
struct GapRoomTimelineView: View {
    @Environment(\.timelineContext) var context
    let timelineItem: GapRoomTimelineItem
    
    var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .task {
                // Re-request periodically while visible: a resolution killed by
                // backgrounding or a network error would otherwise never retry.
                // The SDK deduplicates in-flight resolutions, so this is cheap.
                while !Task.isCancelled {
                    context?.send(viewAction: .resolveGap(prevToken: timelineItem.prevToken))
                    try? await Task.sleep(for: .seconds(2))
                }
            }
    }
}

struct GapRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        GapRoomTimelineView(timelineItem: .init(id: .virtual(uniqueID: .init("gap")), prevToken: "token"))
    }
}
