//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias ServerConfirmationScreenViewModelType = StateStoreViewModel<ServerConfirmationScreenViewState, ServerConfirmationScreenViewAction>

class ServerConfirmationScreenViewModel: ServerConfirmationScreenViewModelType, ServerConfirmationScreenViewModelProtocol {
    private var actionsSubject: PassthroughSubject<ServerConfirmationScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<ServerConfirmationScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(authenticationService: AuthenticationServiceProtocol, authenticationFlow: AuthenticationFlow) {
        super.init(initialViewState: ServerConfirmationScreenViewState(homeserverAddress: authenticationService.homeserver.value.address,
                                                                       authenticationFlow: authenticationFlow))
        
        authenticationService.homeserver
            .receive(on: DispatchQueue.main)
            .sink { [weak self] homeserver in
                guard let self else { return }
                state.homeserverAddress = homeserver.address
                state.homeserverSupportsRegistration = homeserver.loginMode == .oidc || (homeserver.address == "matrix.org" && homeserver.registrationHelperURL != nil)
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
