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

typealias ServerConfirmationScreenViewModelType = StateStoreViewModel<ServerConfirmationScreenViewState, ServerConfirmationScreenViewAction>

class ServerConfirmationScreenViewModel: ServerConfirmationScreenViewModelType, ServerConfirmationScreenViewModelProtocol {
    private var actionsSubject: PassthroughSubject<ServerConfirmationScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<ServerConfirmationScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(authenticationService: AuthenticationServiceProxyProtocol, authenticationFlow: AuthenticationFlow) {
        super.init(initialViewState: ServerConfirmationScreenViewState(homeserverAddress: authenticationService.homeserver.value.address,
                                                                       authenticationFlow: authenticationFlow))
        
        authenticationService.homeserver
            .receive(on: DispatchQueue.main)
            .sink { [weak self] homeserver in
                guard let self else { return }
                state.homeserverAddress = homeserver.address
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: ServerConfirmationScreenViewAction) {
        switch viewAction {
        case .updateWindow(let window):
            guard state.window != window else { return }
            Task { state.window = window }
        case .confirm:
            actionsSubject.send(.confirm)
        case .changeServer:
            actionsSubject.send(.changeServer)
        }
    }
}
