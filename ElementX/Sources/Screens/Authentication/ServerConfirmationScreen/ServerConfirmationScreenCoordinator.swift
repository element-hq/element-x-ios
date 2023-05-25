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

struct ServerConfirmationScreenCoordinatorParameters {
    let authenticationService: AuthenticationServiceProxyProtocol
    let authenticationFlow: AuthenticationFlow
}

enum ServerConfirmationScreenCoordinatorAction {
    case confirm
    case changeServer
}

final class ServerConfirmationScreenCoordinator: CoordinatorProtocol {
    private let parameters: ServerConfirmationScreenCoordinatorParameters
    private var viewModel: ServerConfirmationScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<ServerConfirmationScreenCoordinatorAction, Never> = .init()
    private var cancellables: Set<AnyCancellable> = .init()
    
    var actions: AnyPublisher<ServerConfirmationScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: ServerConfirmationScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = ServerConfirmationScreenViewModel(authenticationService: parameters.authenticationService,
                                                      authenticationFlow: parameters.authenticationFlow)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .confirm:
                self.actionsSubject.send(.confirm)
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
