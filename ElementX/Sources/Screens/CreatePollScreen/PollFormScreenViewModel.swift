//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias PollFormScreenViewModelType = StateStoreViewModel<PollFormScreenViewState, PollFormScreenViewAction>

class PollFormScreenViewModel: PollFormScreenViewModelType, PollFormScreenViewModelProtocol {
    private var actionsSubject: PassthroughSubject<PollFormScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<PollFormScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(mode: PollFormMode) {
        super.init(initialViewState: .init(mode: mode))
    }
    
    // MARK: - Public
    
    override func process(viewAction: PollFormScreenViewAction) {
        switch viewAction {
        case .submit:
            actionsSubject.send(.submit(question: state.bindings.question,
                                        options: state.bindings.options.map(\.text),
                                        pollKind: state.bindings.isUndisclosed ? .undisclosed : .disclosed))
        case .delete:
            state.bindings.alertInfo = .init(id: .init(),
                                             title: L10n.screenEditPollDeleteConfirmationTitle,
                                             message: L10n.screenEditPollDeleteConfirmation,
                                             primaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil),
                                             secondaryButton: .init(title: L10n.actionOk, action: { self.actionsSubject.send(.delete) }))
        case .cancel:
            if state.formContentHasChanged {
                state.bindings.alertInfo = .init(id: .init(),
                                                 title: L10n.screenCreatePollCancelConfirmationTitleIos,
                                                 message: L10n.screenCreatePollCancelConfirmationContentIos,
                                                 primaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil),
                                                 secondaryButton: .init(title: L10n.actionOk, action: { self.actionsSubject.send(.cancel) }))
            } else {
                actionsSubject.send(.cancel)
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
}
