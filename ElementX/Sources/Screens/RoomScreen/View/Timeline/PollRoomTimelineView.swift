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
    @ScaledMetric private var iconSize = 22

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)

    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            VStack(alignment: .leading, spacing: 16) {
                questionView
                optionsView
                summaryView
                toolbarView
            }
            .frame(maxWidth: 450)
        }
    }

    // MARK: - Private

    private var poll: Poll {
        timelineItem.poll
    }

    private var eventID: String? {
        timelineItem.id.eventID
    }

    private var questionView: some View {
        HStack(alignment: .top, spacing: 12) {
            let asset = poll.hasEnded ? Asset.Images.timelineEndedPoll : Asset.Images.timelinePoll

            Image(asset.name)
                .resizable()
                .frame(width: iconSize, height: iconSize)

            Text(poll.question)
                .multilineTextAlignment(.leading)
                .font(.compound.bodyLGSemibold)
        }
    }

    private var optionsView: some View {
        ForEach(poll.options, id: \.id) { option in
            Button {
                guard let eventID, !option.isSelected else { return }
                context.send(viewAction: .selectedPollOption(pollStartID: eventID, optionID: option.id))
                feedbackGenerator.impactOccurred()
            } label: {
                PollOptionView(pollOption: option,
                               showVotes: showVotes,
                               isFinalResult: poll.hasEnded)
                    .foregroundColor(progressBarColor(for: option))
            }
            .disabled(poll.hasEnded || eventID == nil)
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

    @ViewBuilder
    private var toolbarView: some View {
        if !poll.hasEnded, poll.createdByAccountOwner, let eventID {
            Button {
                context.send(viewAction: .endPoll(pollStartID: eventID))
            } label: {
                Text(L10n.actionEndPoll)
                    .lineLimit(2, reservesSpace: false)
                    .font(.compound.bodyLGSemibold)
                    .foregroundColor(.compound.textOnSolidPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background {
                        Capsule()
                            .foregroundColor(.compound.bgActionPrimaryRest)
                    }
            }
            .padding(.top, 8)
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
                L10n.commonPollTotalVotes($0.allVotes)
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
    }
}
