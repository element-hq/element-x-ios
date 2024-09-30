//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct ServerConfirmationScreenCoordinatorParameters {
    let authenticationService: AuthenticationServiceProtocol
    let authenticationFlow: AuthenticationFlow
}

enum ServerConfirmationScreenCoordinatorAction {
    case `continue`(UIWindow?)
    case changeServer
}

final class ServerConfirmationScreenCoordinator: CoordinatorProtocol {
    private var viewModel: ServerConfirmationScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<ServerConfirmationScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<ServerConfirmationScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: ServerConfirmationScreenCoordinatorParameters) {
        viewModel = ServerConfirmationScreenViewModel(authenticationService: parameters.authenticationService,
                                                      authenticationFlow: parameters.authenticationFlow)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .confirm:
                self.actionsSubject.send(.continue(viewModel.context.viewState.window))
            case .changeServer:
                self.actionsSubject.send(.changeServer)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(ServerConfirmationScreen(context: viewModel.context))
    }
}
