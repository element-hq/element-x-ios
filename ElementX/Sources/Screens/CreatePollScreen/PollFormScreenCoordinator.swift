//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct PollFormScreenCoordinatorParameters {
    let mode: PollFormMode
    /// The max number of allowed options, if no value provided the default value of the view model will be used.
    var maxNumberOfOptions: Int?
}

enum PollFormScreenCoordinatorAction {
    case cancel
    case delete
    case submit(question: String, options: [String], pollKind: Poll.Kind)
}

final class PollFormScreenCoordinator: CoordinatorProtocol {
    private var viewModel: PollFormScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<PollFormScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<PollFormScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: PollFormScreenCoordinatorParameters) {
        viewModel = PollFormScreenViewModel(mode: parameters.mode, maxNumberOfOptions: parameters.maxNumberOfOptions)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .cancel:
                self.actionsSubject.send(.cancel)
            case .delete:
                self.actionsSubject.send(.delete)
            case let .submit(question, options, pollKind):
                self.actionsSubject.send(.submit(question: question, options: options, pollKind: pollKind))
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(PollFormScreen(context: viewModel.context))
    }
}
