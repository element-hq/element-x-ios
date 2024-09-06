//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct PollRoomTimelineView: View {
    let timelineItem: PollRoomTimelineItem
    @EnvironmentObject private var context: TimelineViewModel.Context
    
    private var state: PollViewState {
        if context.viewState.isPinnedEventsTimeline {
            return .preview
        } else {
            return .full(isEditable: timelineItem.isEditable)
        }
    }
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            PollView(poll: poll,
                     state: state) { action in
                switch action {
                case .selectOption(let optionID):
                    guard let eventID, let option = poll.options.first(where: { $0.id == optionID }), !option.isSelected else { return }
                    context.send(viewAction: .handlePollAction(.selectOption(pollStartID: eventID, optionID: option.id)))
                case .edit:
                    guard let eventID else { return }
                    context.send(viewAction: .handlePollAction(.edit(pollStartID: eventID, poll: poll)))
                case .end:
                    guard let eventID else { return }
                    context.send(viewAction: .handlePollAction(.end(pollStartID: eventID)))
                }
            }
        }
    }
    
    // MARK: - Private
    
    private var poll: Poll {
        timelineItem.poll
    }
    
    private var eventID: String? {
        timelineItem.id.eventID
    }
}

struct PollRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    static let pinnedEventsTimelineViewModel = TimelineViewModel.pinnedEventsTimelineMock

    static var previews: some View {
        PollRoomTimelineView(timelineItem: .mock(poll: .disclosed(), isOutgoing: false))
            .environmentObject(viewModel.context)
            .previewDisplayName("Disclosed, Bubble")

        PollRoomTimelineView(timelineItem: .mock(poll: .undisclosed(), isOutgoing: false))
            .environmentObject(viewModel.context)
            .previewDisplayName("Undisclosed, Bubble")

        PollRoomTimelineView(timelineItem: .mock(poll: .endedDisclosed))
            .environmentObject(viewModel.context)
            .previewDisplayName("Ended, Disclosed, Bubble")

        PollRoomTimelineView(timelineItem: .mock(poll: .endedUndisclosed))
            .environmentObject(viewModel.context)
            .previewDisplayName("Ended, Undisclosed, Bubble")

        PollRoomTimelineView(timelineItem: .mock(poll: .disclosed(createdByAccountOwner: true)))
            .environmentObject(viewModel.context)
            .previewDisplayName("Creator, disclosed, Bubble")
        
        PollRoomTimelineView(timelineItem: .mock(poll: .emptyDisclosed, isEditable: true))
            .environmentObject(viewModel.context)
            .previewDisplayName("Creator, no votes, Bubble")
        
        PollRoomTimelineView(timelineItem: .mock(poll: .disclosed(), isEditable: true))
            .environmentObject(pinnedEventsTimelineViewModel.context)
            .previewDisplayName("Preview")
    }
}
