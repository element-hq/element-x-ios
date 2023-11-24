//
// Copyright 2022 New Vector Ltd
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
                                                 title: L10n.screenCreatePollCancelConfirmationIosTitle,
                                                 message: L10n.screenCreatePollCancelConfirmationIosContent,
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
