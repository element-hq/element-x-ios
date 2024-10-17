//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct LoginScreenCoordinatorParameters {
    /// The service used to authenticate the user.
    let authenticationService: AuthenticationServiceProtocol
    let slidingSyncLearnMoreURL: URL
    let userIndicatorController: UserIndicatorControllerProtocol
    let analytics: AnalyticsService
}

enum LoginScreenCoordinatorAction {
    /// The homeserver was updated to one that supports OIDC.
    case configuredForOIDC
    /// Login was successful.
    case signedIn(UserSessionProtocol)
}

// Note: This code was brought over from Riot, we should move the authentication service logic into the view model.
final class LoginScreenCoordinator: CoordinatorProtocol {
    private let parameters: LoginScreenCoordinatorParameters
    private var viewModel: LoginScreenViewModelProtocol
        
    private var authenticationService: AuthenticationServiceProtocol { parameters.authenticationService }

    private let actionsSubject: PassthroughSubject<LoginScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<LoginScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Setup
    
    init(parameters: LoginScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = LoginScreenViewModel(authenticationService: parameters.authenticationService,
                                         slidingSyncLearnMoreURL: parameters.slidingSyncLearnMoreURL,
                                         userIndicatorController: parameters.userIndicatorController,
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
