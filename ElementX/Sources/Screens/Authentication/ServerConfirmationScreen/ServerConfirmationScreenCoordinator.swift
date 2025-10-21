//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct ServerConfirmationScreenCoordinatorParameters {
    let authenticationService: AuthenticationServiceProtocol
    let authenticationFlow: AuthenticationFlow
    let appSettings: AppSettings
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum ServerConfirmationScreenCoordinatorAction {
    case continueWithOIDC(data: OIDCAuthorizationDataProxy, window: UIWindow)
    case continueWithPassword
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
        let mode = if parameters.appSettings.allowOtherAccountProviders {
            ServerConfirmationScreenMode.confirmation(parameters.authenticationService.homeserver.value.address)
        } else {
            ServerConfirmationScreenMode.picker(parameters.appSettings.accountProviders)
        }
        
        viewModel = ServerConfirmationScreenViewModel(authenticationService: parameters.authenticationService,
                                                      mode: mode,
                                                      authenticationFlow: parameters.authenticationFlow,
                                                      appSettings: parameters.appSettings,
                                                      userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .continueWithOIDC(let oidcData, let window):
                actionsSubject.send(.continueWithOIDC(data: oidcData, window: window))
            case .continueWithPassword:
                actionsSubject.send(.continueWithPassword)
            case .changeServer:
                actionsSubject.send(.changeServer)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(ServerConfirmationScreen(context: viewModel.context))
    }
}
