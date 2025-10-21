//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias PollFormScreenViewModelType = StateStoreViewModelV2<PollFormScreenViewState, PollFormScreenViewAction>

class PollFormScreenViewModel: PollFormScreenViewModelType, PollFormScreenViewModelProtocol {
    private let timelineController: TimelineControllerProtocol
    private let analytics: AnalyticsService
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var actionsSubject: PassthroughSubject<PollFormScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<PollFormScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(mode: PollFormMode,
         maxNumberOfOptions: Int? = nil,
         timelineController: TimelineControllerProtocol,
         analytics: AnalyticsService,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.timelineController = timelineController
        self.analytics = analytics
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: .init(mode: mode, maxNumberOfOptions: maxNumberOfOptions ?? 20))
    }
    
    // MARK: - Public
    
    override func process(viewAction: PollFormScreenViewAction) {
        switch viewAction {
        case .submit:
            let question = state.bindings.question
            let options = state.bindings.options.map(\.text)
            let pollKind = state.bindings.isUndisclosed ? Poll.Kind.undisclosed : .disclosed
            
            Task {
                switch state.mode {
                case .new:
                    await createPoll(question: question, options: options, pollKind: pollKind)
                case .edit(let eventID, _):
                    await editPoll(pollStartID: eventID, question: question, options: options, pollKind: pollKind)
                }
            }
        case .delete:
            state.bindings.alertInfo = .init(id: .init(),
                                             title: L10n.screenEditPollDeleteConfirmationTitle,
                                             message: L10n.screenEditPollDeleteConfirmation,
                                             primaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil),
                                             secondaryButton: .init(title: L10n.actionOk) { Task { await self.deletePoll() } })
        case .cancel:
            if state.formContentHasChanged {
                state.bindings.alertInfo = .init(id: .init(),
                                                 title: L10n.screenCreatePollCancelConfirmationTitleIos,
                                                 message: L10n.screenCreatePollCancelConfirmationContentIos,
                                                 primaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil),
                                                 secondaryButton: .init(title: L10n.actionOk) { self.actionsSubject.send(.close) })
            } else {
                actionsSubject.send(.close)
            }
        case .deleteOption(let index):
            // fixes a crash that caused an index out of range when an option with the keyboard focus was deleted
            Task {
                try await Task.sleep(for: .milliseconds(100))
                guard state.bindings.options.indices.contains(index) else {
                    return
                }
                state.bindings.options.remove(at: index)
            }
        case .addOption:
            guard state.bindings.options.count < state.maxNumberOfOptions else {
                return
            }
            state.bindings.options.append(.init())
        }
    }
    
    // MARK: - Private
    
    private func createPoll(question: String, options: [String], pollKind: Poll.Kind) async {
        guard case .success = await timelineController.createPoll(question: question, answers: options, pollKind: pollKind) else {
            userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
            return
        }
        
        actionsSubject.send(.close)
        
        analytics.trackComposer(inThread: false,
                                isEditing: false,
                                isReply: false,
                                messageType: .Poll,
                                startsThread: nil)
        
        analytics.trackPollCreated(isUndisclosed: pollKind == .undisclosed, numberOfAnswers: options.count)
    }
    
    private func editPoll(pollStartID: String, question: String, options: [String], pollKind: Poll.Kind) async {
        switch await timelineController.editPoll(original: pollStartID, question: question, answers: options, pollKind: pollKind) {
        case .success:
            actionsSubject.send(.close)
        case .failure:
            userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
        }
    }
    
    private func deletePoll() async {
        // There aren't any local echoes for redactions, so dismiss the screen early
        // until we have them: https://github.com/matrix-org/matrix-rust-sdk/issues/4162
        actionsSubject.send(.close)
        
        guard case .edit(let pollStartID, _) = state.mode else {
            userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
            return
        }
        
        await timelineController.redact(.eventID(pollStartID))
    }
}
