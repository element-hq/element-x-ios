//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct DecideHomeServerScreenCoordinatorParameters {
    /// The service used to authenticate the user.
    let authenticationService: AuthenticationServiceProtocol
    /// The Authentication flow wanted:
    ///   - .login
    ///   - .register
    let authenticationFlow: AuthenticationFlow
    /// An optional hint that can be used to pre-fill the form.
    let loginHint: String?
    let userIndicatorController: UserIndicatorControllerProtocol
    let appSettings: AppSettings
    /// The Homeservers that can be queried to obtain the attachment Homeserver for a given email.
    let accountProviders: [AccountProvider]
}

enum DecideHomeServerScreenCoordinatorAction {
    /// The homeserver domain is obtained and the Authentication Service supports OAuth
    case authenticationServiceConfiguredForOAuth(OAuthAuthorizationDataProxy, UIWindow)
    // Tchap: allow passing a loginHint
    /// The homeserver domain is obtained and the Authentication Service is configured for login
//    case authenticationServiceConfiguredForLogin
    case authenticationServiceConfiguredForLogin(String?)
}

/// Note: This code was brought over from Riot, we should move the authentication service logic into the view model.
final class DecideHomeServerScreenCoordinator: CoordinatorProtocol {
    private let parameters: DecideHomeServerScreenCoordinatorParameters
    private var viewModel: DecideHomeServerScreenViewModelProtocol
        
    private var authenticationService: AuthenticationServiceProtocol {
        parameters.authenticationService
    }

    private let actionsSubject: PassthroughSubject<DecideHomeServerScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<DecideHomeServerScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Setup
    
    init(parameters: DecideHomeServerScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = DecideHomeServerScreenViewModel(authenticationService: parameters.authenticationService,
                                                    authenticationFlow: parameters.authenticationFlow,
                                                    loginHint: parameters.loginHint,
                                                    accountProviders: parameters.accountProviders,
                                                    userIndicatorController: parameters.userIndicatorController,
                                                    appSettings: parameters.appSettings)
    }
    
    // MARK: - Public

    func start() {
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .authenticationServiceConfiguredForLogin(let loginHint):
                    actionsSubject.send(.authenticationServiceConfiguredForLogin(loginHint))
                case .authenticationServiceConfiguredForOAuth(let data, let window):
                    actionsSubject.send(.authenticationServiceConfiguredForOAuth(data, window))
                }
            }
            .store(in: &cancellables)
    }

    func stop() {
        viewModel.stopLoading()
    }
    
    func resetLoadingState() {
        viewModel.resetLoadingState()
    }

    func toPresentable() -> AnyView {
        AnyView(DecideHomeServerScreen(context: viewModel.context))
    }
}
