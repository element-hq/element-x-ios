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

    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            VStack(alignment: .leading, spacing: 16) {
                questionView

                ForEach(poll.options, id: \.id) { option in
                    Button { } label: {
                        PollOptionView(pollOption: option)
                    }
                }

                summaryView
            }
            .frame(maxWidth: 450)
        }
    }

    // MARK: - Private

    private var poll: Poll {
        timelineItem.poll
    }

    private var questionView: some View {
        HStack(spacing: 4) {
            Image(Asset.Images.equalizer.name)

            Text(poll.question)
                .font(.compound.bodyLGSemibold)
        }
    }

    @ViewBuilder
    private var summaryView: some View {
        if let allVotes = poll.options.first?.allVotes {
            Text(L10n.commonPollTotalVotes(allVotes))
                .font(.compound.bodySM)
                .foregroundColor(.compound.textSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

struct PollRoomTimelineView_Previews: PreviewProvider {
    static let viewModel = RoomScreenViewModel.mock

    static var previews: some View {
        PollRoomTimelineView(timelineItem: .init(id: .random,
                                                 poll: .mock,
                                                 body: "Foo",
                                                 timestamp: "Now",
                                                 isOutgoing: false,
                                                 isEditable: false,
                                                 sender: .init(id: "Bob"),
                                                 properties: .init()))
            .environment(\.timelineStyle, .bubbles)
            .environmentObject(viewModel.context)
            .previewDisplayName("Poll bubble style")

        PollRoomTimelineView(timelineItem: .init(id: .random,
                                                 poll: .mock,
                                                 body: "Foo",
                                                 timestamp: "Now",
                                                 isOutgoing: false,
                                                 isEditable: false,
                                                 sender: .init(id: "Bob"),
                                                 properties: .init()))
            .environment(\.timelineStyle, .plain)
            .environmentObject(viewModel.context)
            .previewDisplayName("Poll plain style")
    }
}

private extension Poll {
    static let mock: Self = .init(question: "Do you like polls?",
                                  pollKind: .disclosed,
                                  maxSelections: 1,
                                  options: [.init(id: "1", text: "Yes", votes: 1, allVotes: 3, isSelected: true), .init(id: "2", text: "No", votes: 2, allVotes: 3, isSelected: false)],
                                  votes: [:],
                                  endDate: nil)
}
