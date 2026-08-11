//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// A read-only preview of a room's timeline, shown above the room list's
/// context menu (like a conversation peek in other messengers). Peeking must
/// never send a read receipt: receipts originate in the timeline table
/// controller's visible-item tracking and in `RoomScreenViewModel`, so this
/// renders the timeline's item views directly without either of them.
struct RoomPeekView: View {
    let roomID: String
    let viewModelBuilder: ((String) async -> TimelineViewModelProtocol?)?

    @State private var timelineViewModel: TimelineViewModelProtocol?

    var body: some View {
        content
            // ponytail: fixed peek size, revisit if it looks cramped on iPad.
            .frame(width: 320, height: 480)
            .background(Color.compound.bgCanvasDefault)
            .task {
                timelineViewModel = await viewModelBuilder?(roomID)
            }
    }

    @ViewBuilder private var content: some View {
        if let context = timelineViewModel?.context {
            RoomPeekTimelineView(timelineContext: context)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct RoomPeekTimelineView: View {
    @ObservedObject var timelineContext: TimelineViewModel.Context

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(timelineContext.viewState.timelineState.itemViewStates) { viewState in
                    RoomTimelineItemView(viewState: viewState)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 8)
        }
        .defaultScrollAnchor(.bottom)
        .environmentObject(timelineContext)
        .environment(\.timelineContext, timelineContext)
        .environment(\.shouldAutomaticallyLoadImages, !timelineContext.viewState.hideTimelineMedia)
    }
}
