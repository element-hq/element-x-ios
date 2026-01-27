//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

enum PollViewAction {
    case selectOption(optionID: String)
    case edit
    case end
}

enum PollViewState {
    case preview
    case full(isEditable: Bool)
    
    var isPreview: Bool {
        switch self {
        case .preview:
            return true
        case .full:
            return false
        }
    }
    
    var isEditable: Bool {
        switch self {
        case .preview:
            return false
        case .full(let isEditable):
            return isEditable
        }
    }
}

struct PollView: View {
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    let poll: Poll
    let state: PollViewState
    let sender: TimelineItemSender
    let actionHandler: (PollViewAction) -> Void
    
    var body: some View {
        if state.isPreview {
            accessibleQuestionView
        } else {
            VStack(alignment: .leading, spacing: 16) {
                accessibleQuestionView
                optionsView
                summaryView
                toolbarView
            }
            .frame(maxWidth: 450)
        }
    }

    // MARK: - Private
    
    private var senderString: String {
        poll.createdByAccountOwner ? L10n.commonYou : sender.disambiguatedDisplayName ?? sender.id
    }
    
    private var accessibleQuestionView: some View {
        questionView
            .accessibilityRepresentation {
                HStack(spacing: 0) {
                    Text(senderString)
                    questionView
                }
                .accessibilityElement(children: .combine)
            }
    }

    private var questionView: some View {
        HStack(alignment: .top, spacing: 12) {
            CompoundIcon(poll.hasEnded ? \.pollsEnd : \.polls,
                         size: .custom(22),
                         relativeTo: .compound.bodyLGSemibold)
                .accessibilityLabel(poll.hasEnded ? L10n.a11yPollEnd : L10n.a11yPoll)

            Text(poll.question)
                .multilineTextAlignment(.leading)
                .font(.compound.bodyLGSemibold)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var optionsView: some View {
        ForEach(poll.options, id: \.id) { option in
            pollOption(option: option)
                .accessibilityHint(L10n.a11yPollsWillRemoveSelection, isEnabled: isRemovePreviousSelectionHintEnabled(option: option))
        }
    }
    
    private func isRemovePreviousSelectionHintEnabled(option: Poll.Option) -> Bool {
        !poll.hasEnded && poll.hasMaxSelections && !option.isSelected
    }
    
    private func pollOption(option: Poll.Option) -> some View {
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
                Text(state.isEditable ? L10n.actionEditPoll : L10n.actionEndPoll)
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
        if state.isEditable {
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
        PollView(poll: .disclosed(), state: .full(isEditable: false), sender: .test) { _ in }
            .padding()
            .previewDisplayName("Disclosed")

        PollView(poll: .undisclosed(), state: .full(isEditable: false), sender: .test) { _ in }
            .padding()
            .previewDisplayName("Undisclosed")

        PollView(poll: .endedDisclosed, state: .full(isEditable: false), sender: .test) { _ in }
            .padding()
            .previewDisplayName("Ended, Disclosed")

        PollView(poll: .endedUndisclosed, state: .full(isEditable: false), sender: .test) { _ in }
            .padding()
            .previewDisplayName("Ended, Undisclosed")

        PollView(poll: .disclosed(createdByAccountOwner: true), state: .full(isEditable: true), sender: .test) { _ in }
            .padding()
            .previewDisplayName("Creator, disclosed")
        
        PollView(poll: .emptyDisclosed, state: .full(isEditable: true), sender: .test) { _ in }
            .padding()
            .previewDisplayName("Creator, no votes")
        
        PollView(poll: .emptyDisclosed, state: .preview, sender: .test) { _ in }
            .padding()
            .previewDisplayName("Preview")
    }
}
