//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct PollFormScreenCoordinatorParameters {
    let mode: PollFormMode
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
        viewModel = PollFormScreenViewModel(mode: parameters.mode)
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
