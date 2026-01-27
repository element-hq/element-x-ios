//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct LoginScreenCoordinatorParameters {
    /// The service used to authenticate the user.
    let authenticationService: AuthenticationServiceProtocol
    /// An optional hint that can be used to pre-fill the form.
    let loginHint: String?
    let userIndicatorController: UserIndicatorControllerProtocol
    let appSettings: AppSettings
    let analytics: AnalyticsService
}

enum LoginScreenCoordinatorAction {
    /// The homeserver was updated to one that supports OIDC.
    case configuredForOIDC
    /// Login was successful.
    case signedIn(UserSessionProtocol)
}

/// Note: This code was brought over from Riot, we should move the authentication service logic into the view model.
final class LoginScreenCoordinator: CoordinatorProtocol {
    private let parameters: LoginScreenCoordinatorParameters
    private var viewModel: LoginScreenViewModelProtocol
        
    private var authenticationService: AuthenticationServiceProtocol {
        parameters.authenticationService
    }

    private let actionsSubject: PassthroughSubject<LoginScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<LoginScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Setup
    
    init(parameters: LoginScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = LoginScreenViewModel(authenticationService: parameters.authenticationService,
                                         loginHint: parameters.loginHint,
                                         userIndicatorController: parameters.userIndicatorController,
                                         appSettings: parameters.appSettings,
                                         analytics: parameters.analytics)
    }
    
    // MARK: - Public

    func start() {
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .configuredForOIDC:
                    actionsSubject.send(.configuredForOIDC)
                case .signedIn(let userSession):
                    actionsSubject.send(.signedIn(userSession))
                }
            }
            .store(in: &cancellables)
    }

    func stop() {
        viewModel.stopLoading()
    }
    
    func toPresentable() -> AnyView {
        AnyView(LoginScreen(context: viewModel.context))
    }
}
