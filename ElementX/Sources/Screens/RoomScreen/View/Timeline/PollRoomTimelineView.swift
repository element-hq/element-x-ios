//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI

struct PollRoomTimelineView: View {
    let timelineItem: PollRoomTimelineItem
    @Environment(\.timelineStyle) var timelineStyle
    @EnvironmentObject private var context: RoomScreenViewModel.Context
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            PollView(poll: poll, editable: timelineItem.isEditable) { action in
                switch action {
                case .selectOption(let optionID):
                    guard let eventID, let option = poll.options.first(where: { $0.id == optionID }), !option.isSelected else { return }
                    context.send(viewAction: .poll(.selectOption(pollStartID: eventID, optionID: option.id)))
                case .edit:
                    guard let eventID else { return }
                    context.send(viewAction: .poll(.edit(pollStartID: eventID, poll: poll)))
                case .end:
                    guard let eventID else { return }
                    context.send(viewAction: .poll(.end(pollStartID: eventID)))
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
    static let viewModel = RoomScreenViewModel.mock

    static var previews: some View {
        PollRoomTimelineView(timelineItem: .mock(poll: .disclosed(), isOutgoing: false))
            .environment(\.timelineStyle, .bubbles)
            .environmentObject(viewModel.context)
            .previewDisplayName("Disclosed, Bubble")

        PollRoomTimelineView(timelineItem: .mock(poll: .undisclosed(), isOutgoing: false))
            .environment(\.timelineStyle, .bubbles)
            .environmentObject(viewModel.context)
            .previewDisplayName("Undisclosed, Bubble")

        PollRoomTimelineView(timelineItem: .mock(poll: .endedDisclosed))
            .environment(\.timelineStyle, .bubbles)
            .environmentObject(viewModel.context)
            .previewDisplayName("Ended, Disclosed, Bubble")

        PollRoomTimelineView(timelineItem: .mock(poll: .endedUndisclosed))
            .environment(\.timelineStyle, .bubbles)
            .environmentObject(viewModel.context)
            .previewDisplayName("Ended, Undisclosed, Bubble")

        PollRoomTimelineView(timelineItem: .mock(poll: .disclosed(createdByAccountOwner: true)))
            .environment(\.timelineStyle, .bubbles)
            .environmentObject(viewModel.context)
            .previewDisplayName("Creator, disclosed, Bubble")

        PollRoomTimelineView(timelineItem: .mock(poll: .disclosed(), isOutgoing: false))
            .environment(\.timelineStyle, .plain)
            .environmentObject(viewModel.context)
            .previewDisplayName("Disclosed, Plain")

        PollRoomTimelineView(timelineItem: .mock(poll: .undisclosed(), isOutgoing: false))
            .environment(\.timelineStyle, .plain)
            .environmentObject(viewModel.context)
            .previewDisplayName("Undisclosed, Plain")

        PollRoomTimelineView(timelineItem: .mock(poll: .endedDisclosed))
            .environment(\.timelineStyle, .plain)
            .environmentObject(viewModel.context)
            .previewDisplayName("Ended, Disclosed, Plain")

        PollRoomTimelineView(timelineItem: .mock(poll: .endedUndisclosed))
            .environment(\.timelineStyle, .plain)
            .environmentObject(viewModel.context)
            .previewDisplayName("Ended, Undisclosed, Plain")

        PollRoomTimelineView(timelineItem: .mock(poll: .disclosed(createdByAccountOwner: true)))
            .environment(\.timelineStyle, .plain)
            .environmentObject(viewModel.context)
            .previewDisplayName("Creator, disclosed, Plain")
        
        PollRoomTimelineView(timelineItem: .mock(poll: .emptyDisclosed, isEditable: true))
            .environment(\.timelineStyle, .bubbles)
            .environmentObject(viewModel.context)
            .previewDisplayName("Creator, no votes, Bubble")
        
        PollRoomTimelineView(timelineItem: .mock(poll: .emptyDisclosed, isEditable: true))
            .environment(\.timelineStyle, .plain)
            .environmentObject(viewModel.context)
            .previewDisplayName("Creator, no votes, Plain")
    }
}
