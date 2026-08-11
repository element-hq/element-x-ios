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
    /// How many of the room's newest items the peek renders. Doubles as the
    /// backfill target when the event cache can't fill the viewport.
    private static let maxItemCount = 40

    @ObservedObject var timelineContext: TimelineViewModel.Context
    @State private var contentHeight: CGFloat = 0

    /// Deliberately a bounded slice in a NON-lazy stack: a bottom-anchored
    /// lazy stack layout-loops when appearing items fetch their reply details
    /// and change height, re-crossing the lazy horizon forever (main thread
    /// spun at 96% cpu until the watchdog killed the app, 2026-08-12).
    private var itemViewStates: [RoomTimelineItemViewState] {
        Array(timelineContext.viewState.timelineState.itemViewStates.suffix(Self.maxItemCount))
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if itemViewStates.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        ForEach(itemViewStates) { viewState in
                            RoomTimelineItemView(viewState: viewState)
                                .allowsHitTesting(false)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { contentHeight = $0 }
                // Bottom-align partial histories that don't fill the viewport.
                .frame(minHeight: geometry.size.height, alignment: .bottom)
            }
            .defaultScrollAnchor(.bottom)
            .onChange(of: contentHeight, initial: true) {
                paginateToFillIfNeeded(viewportHeight: geometry.size.height)
            }
            .onChange(of: timelineContext.viewState.timelineState.paginationState.backward) {
                paginateToFillIfNeeded(viewportHeight: geometry.size.height)
            }
        }
        .environmentObject(timelineContext)
        .environment(\.timelineContext, timelineContext)
        .environment(\.shouldAutomaticallyLoadImages, !timelineContext.viewState.hideTimelineMedia)
    }

    /// Backfills the timeline while the peek's viewport isn't filled, e.g. for
    /// rooms whose event cache only holds a couple of events. Pagination never
    /// sends receipts so this is peek-safe.
    private func paginateToFillIfNeeded(viewportHeight: CGFloat) {
        guard contentHeight < viewportHeight,
              itemViewStates.count < Self.maxItemCount,
              timelineContext.viewState.timelineState.paginationState.backward == .idle else { return }

        timelineContext.send(viewAction: .paginateBackwards)
    }
}
