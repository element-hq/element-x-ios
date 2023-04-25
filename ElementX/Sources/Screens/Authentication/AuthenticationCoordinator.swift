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

import SwiftUI

@MainActor
protocol AuthenticationCoordinatorDelegate: AnyObject {
    func authenticationCoordinator(_ authenticationCoordinator: AuthenticationCoordinator,
                                   didLoginWithSession userSession: UserSessionProtocol)
}

class AuthenticationCoordinator: CoordinatorProtocol {
    private let authenticationService: AuthenticationServiceProxyProtocol
    private let navigationStackCoordinator: NavigationStackCoordinator
    
    weak var delegate: AuthenticationCoordinatorDelegate?
    
    init(authenticationService: AuthenticationServiceProxyProtocol,
         navigationStackCoordinator: NavigationStackCoordinator) {
        self.authenticationService = authenticationService
        self.navigationStackCoordinator = navigationStackCoordinator
    }
    
    func start() {
        showOnboarding()
    }
    
    func stop() {
        stopLoading()
    }
        
    // MARK: - Private
    
    private func showOnboarding() {
        let coordinator = OnboardingCoordinator()

        coordinator.callback = { [weak self] action in
            guard let self else { return }
            switch action {
            case .login:
                Task { await self.startAuthentication() }
            }
        }
        
        navigationStackCoordinator.setRootCoordinator(coordinator)
    }
    
    private func startAuthentication() async {
        startLoading()
        
        switch await authenticationService.configure(for: ServiceLocator.shared.settings.defaultHomeserverAddress) {
        case .success:
            stopLoading()
            showLoginScreen()
        case .failure:
            stopLoading()
            showServerSelectionScreen()
        }
    }
    
    private func showServerSelectionScreen() {
        let parameters = ServerSelectionScreenCoordinatorParameters(authenticationService: authenticationService,
                                                                    userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                                    isModallyPresented: false)
        let coordinator = ServerSelectionScreenCoordinator(parameters: parameters)
        
        coordinator.callback = { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .updated:
                self.showLoginScreen()
            case .dismiss:
                MXLog.failure("ServerSelectionScreen is requesting dismiss when part of a stack.")
            }
        }
        
        navigationStackCoordinator.push(coordinator)
    }
    
    private func showLoginScreen() {
        let parameters = LoginScreenCoordinatorParameters(authenticationService: authenticationService,
                                                          navigationStackCoordinator: navigationStackCoordinator)
        let coordinator = LoginScreenCoordinator(parameters: parameters)
        
        coordinator.callback = { [weak self] action in
            guard let self else { return }

            switch action {
            case .signedIn(let userSession):
                self.userHasSignedIn(userSession: userSession)
            }
        }

        navigationStackCoordinator.push(coordinator)
    }
    
    private func userHasSignedIn(userSession: UserSessionProtocol) {
        showAnalyticsPromptIfNeeded { [weak self] in
            guard let self else { return }
            self.delegate?.authenticationCoordinator(self, didLoginWithSession: userSession)
        }
    }

    private func showAnalyticsPromptIfNeeded(completion: @escaping () -> Void) {
        guard ServiceLocator.shared.analytics.shouldShowAnalyticsPrompt else {
            completion()
            return
        }
        let coordinator = AnalyticsPromptScreenCoordinator()
        coordinator.callback = {
            completion()
        }
        navigationStackCoordinator.push(coordinator)
    }
    
    static let loadingIndicatorIdentifier = "AuthenticationCoordinatorLoading"
    
    private func startLoading() {
        ServiceLocator.shared.userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                                                    type: .modal,
                                                                                    title: L10n.commonLoading,
                                                                                    persistent: true))
    }
    
    private func stopLoading() {
        ServiceLocator.shared.userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
}
