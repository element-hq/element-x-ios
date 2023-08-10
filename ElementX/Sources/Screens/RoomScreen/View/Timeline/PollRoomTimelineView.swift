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
    @ScaledMetric private var summaryPadding = 32

    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            VStack(alignment: .leading, spacing: 16) {
                questionView

                ForEach(poll.options, id: \.id) { option in
                    Button {
                        context.send(viewAction: .selectedPollOption(poll: poll, optionID: option.id))
                    } label: {
                        PollOptionView(pollOption: option,
                                       showVotes: showVotes,
                                       isFinalResult: poll.hasEnded)
                            .foregroundColor(progressBarColor(for: option))
                    }
                    .disabled(poll.hasEnded)
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
        HStack(alignment: .top, spacing: 12) {
            Image(Asset.Images.timelinePoll.name)

            Text(poll.question)
                .multilineTextAlignment(.leading)
                .font(.compound.bodyLGSemibold)
        }
    }

    @ViewBuilder
    private var summaryView: some View {
        if let summaryText = poll.summaryText {
            Text(summaryText)
                .font(.compound.bodySM)
                .padding(.leading, showVotes ? 0 : summaryPadding)
                .foregroundColor(.compound.textSecondary)
                .frame(maxWidth: .infinity, alignment: showVotes ? .trailing : .leading)
        }
    }

    private func progressBarColor(for option: Poll.Option) -> Color {
        if poll.hasEnded {
            return option.isWinning ? .compound.textActionAccent : .compound.textDisabled
        } else {
            return .compound.textPrimary
        }
    }

    private var showVotes: Bool {
        poll.hasEnded || poll.kind == .disclosed
    }
}

private extension Poll {
    var summaryText: String? {
        guard !hasEnded else {
            return options.first.map {
                L10n.commonPollFinalVotes($0.allVotes)
            }
        }

        switch kind {
        case .disclosed:
            return options.first.map {
                L10n.commonPollTotalVotes($0.allVotes)
            }
        case .undisclosed:
            return L10n.commonPollUndisclosedText
        }
    }

    var hasEnded: Bool {
        endDate != nil
    }
}

struct PollRoomTimelineView_Previews: PreviewProvider {
    static let viewModel = RoomScreenViewModel.mock

    static var previews: some View {
        PollRoomTimelineView(timelineItem: .init(id: .random,
                                                 poll: .mock(),
                                                 body: "Foo",
                                                 timestamp: "Now",
                                                 isOutgoing: false,
                                                 isEditable: false,
                                                 sender: .init(id: "Bob"),
                                                 properties: .init()))
            .environment(\.timelineStyle, .bubbles)
            .environmentObject(viewModel.context)
            .previewDisplayName("Disclosed, Bubble")

        PollRoomTimelineView(timelineItem: .init(id: .random,
                                                 poll: .mock(pollKind: .undisclosed),
                                                 body: "Foo",
                                                 timestamp: "Now",
                                                 isOutgoing: false,
                                                 isEditable: false,
                                                 sender: .init(id: "Bob"),
                                                 properties: .init()))
            .environment(\.timelineStyle, .bubbles)
            .environmentObject(viewModel.context)
            .previewDisplayName("Undisclosed, Bubble")

        PollRoomTimelineView(timelineItem: .init(id: .random,
                                                 poll: .mock(ended: true),
                                                 body: "Foo",
                                                 timestamp: "Now",
                                                 isOutgoing: false,
                                                 isEditable: false,
                                                 sender: .init(id: "Bob"),
                                                 properties: .init()))
            .environment(\.timelineStyle, .bubbles)
            .environmentObject(viewModel.context)
            .previewDisplayName("Ended, Disclosed, Bubble")

        PollRoomTimelineView(timelineItem: .init(id: .random,
                                                 poll: .mock(pollKind: .undisclosed, ended: true),
                                                 body: "Foo",
                                                 timestamp: "Now",
                                                 isOutgoing: false,
                                                 isEditable: false,
                                                 sender: .init(id: "Bob"),
                                                 properties: .init()))
            .environment(\.timelineStyle, .bubbles)
            .environmentObject(viewModel.context)
            .previewDisplayName("Ended, Undisclosed, Bubble")

        PollRoomTimelineView(timelineItem: .init(id: .random,
                                                 poll: .mock(),
                                                 body: "Foo",
                                                 timestamp: "Now",
                                                 isOutgoing: false,
                                                 isEditable: false,
                                                 sender: .init(id: "Bob"),
                                                 properties: .init()))
            .environment(\.timelineStyle, .plain)
            .environmentObject(viewModel.context)
            .previewDisplayName("Disclosed, Plain")

        PollRoomTimelineView(timelineItem: .init(id: .random,
                                                 poll: .mock(pollKind: .undisclosed),
                                                 body: "Foo",
                                                 timestamp: "Now",
                                                 isOutgoing: false,
                                                 isEditable: false,
                                                 sender: .init(id: "Bob"),
                                                 properties: .init()))
            .environment(\.timelineStyle, .plain)
            .environmentObject(viewModel.context)
            .previewDisplayName("Undisclosed, Plain")

        PollRoomTimelineView(timelineItem: .init(id: .random,
                                                 poll: .mock(ended: true),
                                                 body: "Foo",
                                                 timestamp: "Now",
                                                 isOutgoing: false,
                                                 isEditable: false,
                                                 sender: .init(id: "Bob"),
                                                 properties: .init()))
            .environment(\.timelineStyle, .plain)
            .environmentObject(viewModel.context)
            .previewDisplayName("Ended, Disclosed, Plain")

        PollRoomTimelineView(timelineItem: .init(id: .random,
                                                 poll: .mock(pollKind: .undisclosed, ended: true),
                                                 body: "Foo",
                                                 timestamp: "Now",
                                                 isOutgoing: false,
                                                 isEditable: false,
                                                 sender: .init(id: "Bob"),
                                                 properties: .init()))
            .environment(\.timelineStyle, .plain)
            .environmentObject(viewModel.context)
            .previewDisplayName("Ended, Undisclosed, Plain")
    }
}

private extension Poll {
    static func mock(pollKind: Poll.Kind = .disclosed, ended: Bool = false) -> Self {
        .init(question: "Do you like polls?",
              kind: pollKind,
              maxSelections: 1,
              options: [
                  .init(id: "1", text: "Yes", votes: 1, allVotes: 3, isSelected: true, isWinning: false),
                  .init(id: "2", text: "No", votes: 2, allVotes: 3, isSelected: false, isWinning: true)
              ],
              votes: [:],
              endDate: ended ? Date() : nil)
    }
}
