//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ThreadTimelineScreen: View {
    @ObservedObject var context: ThreadTimelineScreenViewModel.Context
    @ObservedObject var timelineContext: TimelineViewModel.Context
        
    var body: some View {
        content
            .navigationTitle("Thread")
            .navigationBarTitleDisplayMode(.inline)
            .background(.compound.bgCanvasDefault)
            .interactiveDismissDisabled()
            .timelineMediaPreview(viewModel: $context.mediaPreviewViewModel)
            .sheet(item: $timelineContext.manageMemberViewModel) {
                ManageRoomMemberSheetView(context: $0.context)
            }
            .sheet(item: $timelineContext.debugInfo) { TimelineItemDebugView(info: $0) }
            .sheet(item: $timelineContext.actionMenuInfo) { info in
                let actions = TimelineItemMenuActionProvider(timelineItem: info.item,
                                                             canCurrentUserRedactSelf: timelineContext.viewState.canCurrentUserRedactSelf,
                                                             canCurrentUserRedactOthers: timelineContext.viewState.canCurrentUserRedactOthers,
                                                             canCurrentUserPin: timelineContext.viewState.canCurrentUserPin,
                                                             pinnedEventIDs: timelineContext.viewState.pinnedEventIDs,
                                                             isDM: timelineContext.viewState.isDirectOneToOneRoom,
                                                             isViewSourceEnabled: timelineContext.viewState.isViewSourceEnabled,
                                                             timelineKind: timelineContext.viewState.timelineKind,
                                                             emojiProvider: timelineContext.viewState.emojiProvider)
                    .makeActions()
                if let actions {
                    TimelineItemMenu(item: info.item, actions: actions)
                        .environmentObject(timelineContext)
                }
            }
    }
    
    @ViewBuilder
    private var content: some View {
        TimelineView()
            .id(timelineContext.viewState.roomID)
            .environmentObject(timelineContext)
            .environment(\.focussedEventID, timelineContext.viewState.timelineState.focussedEvent?.eventID)
    }
}
