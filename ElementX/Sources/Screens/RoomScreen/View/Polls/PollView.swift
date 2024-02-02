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

import Compound
import SwiftUI

enum PollViewAction {
    case selectOption(optionID: String)
    case edit
    case end
}

struct PollView: View {
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    let poll: Poll
    let editable: Bool
    let actionHandler: (PollViewAction) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            questionView
            optionsView
            summaryView
            toolbarView
        }
        .frame(maxWidth: 450)
    }

    // MARK: - Private

    private var questionView: some View {
        HStack(alignment: .top, spacing: 12) {
            CompoundIcon(poll.hasEnded ? \.pollsEnd : \.polls,
                         size: .custom(22),
                         relativeTo: .compound.bodyLGSemibold)
                .accessibilityHidden(true)

            Text(poll.question)
                .multilineTextAlignment(.leading)
                .font(.compound.bodyLGSemibold)
        }
    }

    private var optionsView: some View {
        ForEach(poll.options, id: \.id) { option in
            Button {
                guard !option.isSelected else { return }
                actionHandler(.selectOption(optionID: option.id))
                feedbackGenerator.impactOccurred()
            } label: {
                PollOptionView(pollOption: option,
                               showVotes: showVotes,
                               isFinalResult: poll.hasEnded)
                    .foregroundColor(progressBarColor(for: option))
            }
            .disabled(poll.hasEnded)
        }
    }

    @ViewBuilder
    private var summaryView: some View {
        if let summaryText = poll.summaryText {
            Text(summaryText)
                .font(.compound.bodySM)
                .scaledPadding(.leading, showVotes ? 0 : 32)
                .foregroundColor(.compound.textSecondary)
                .frame(maxWidth: .infinity, alignment: showVotes ? .trailing : .leading)
        }
    }

    @ViewBuilder
    private var toolbarView: some View {
        if !poll.hasEnded, poll.createdByAccountOwner {
            Button {
                toolbarAction()
            } label: {
                Text(editable ? L10n.actionEditPoll : L10n.actionEndPoll)
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
    
    private func toolbarAction() {
        if editable {
            actionHandler(.edit)
        } else {
            actionHandler(.end)
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

struct PollView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        PollView(poll: .disclosed(), editable: false) { _ in }
            .padding()
            .previewDisplayName("Disclosed")

        PollView(poll: .undisclosed(), editable: false) { _ in }
            .padding()
            .previewDisplayName("Undisclosed")

        PollView(poll: .endedDisclosed, editable: false) { _ in }
            .padding()
            .previewDisplayName("Ended, Disclosed")

        PollView(poll: .endedUndisclosed, editable: false) { _ in }
            .padding()
            .previewDisplayName("Ended, Undisclosed")

        PollView(poll: .disclosed(createdByAccountOwner: true), editable: true) { _ in }
            .padding()
            .previewDisplayName("Creator, disclosed")
        
        PollView(poll: .emptyDisclosed, editable: true) { _ in }
            .padding()
            .previewDisplayName("Creator, no votes")
    }
}
