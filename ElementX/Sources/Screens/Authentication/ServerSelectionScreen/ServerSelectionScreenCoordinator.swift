//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct ServerSelectionScreenCoordinatorParameters {
    /// The service used to authenticate the user.
    let authenticationService: AuthenticationServiceProtocol
    let authenticationFlow: AuthenticationFlow
    let appSettings: AppSettings
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum ServerSelectionScreenCoordinatorAction {
    case continueWithOAuth(data: OAuthAuthorizationDataProxy, window: UIWindow)
    case continueWithPassword
    case dismiss
}

/// Note: This code was brought over from Riot, we should move the authentication service logic into the view model.
final class ServerSelectionScreenCoordinator: CoordinatorProtocol {
    private let parameters: ServerSelectionScreenCoordinatorParameters
    private var viewModel: ServerSelectionScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<ServerSelectionScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<ServerSelectionScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: ServerSelectionScreenCoordinatorParameters) {
        self.parameters = parameters
        
        let mode: ServerSelectionScreenMode = if parameters.appSettings.allowOtherAccountProviders {
            .confirmation(parameters.authenticationService.homeserver.value.address)
        } else {
            .picker(parameters.appSettings.accountProviders)
        }
        
        viewModel = ServerSelectionScreenViewModel(authenticationService: parameters.authenticationService,
                                                   mode: mode,
                                                   authenticationFlow: parameters.authenticationFlow,
                                                   appSettings: parameters.appSettings,
                                                   userIndicatorController: parameters.userIndicatorController)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .continueWithOAuth(let oAuthData, let window):
                    actionsSubject.send(.continueWithOAuth(data: oAuthData, window: window))
                case .continueWithPassword:
                    actionsSubject.send(.continueWithPassword)
                case .dismiss:
                    actionsSubject.send(.dismiss)
                }
            }
            .store(in: &cancellables)
    }
    
    func stop() {
        parameters.userIndicatorController.retractAllIndicators()
    }
    
    func toPresentable() -> AnyView {
        AnyView(ServerSelectionScreen(context: viewModel.context))
    }
}
