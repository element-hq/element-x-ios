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
    private let navigationController: NavigationController
//    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var activityIndicator: UserIndicator?
    
    weak var delegate: AuthenticationCoordinatorDelegate?
    
    init(authenticationService: AuthenticationServiceProxyProtocol,
         navigationController: NavigationController) {
        self.authenticationService = authenticationService
        self.navigationController = navigationController
        
//        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: navigationRouter.toPresentable())
    }
    
    func start() {
        showSplashScreen()
    }
    
    func stop() {
        stopLoading()
    }
        
    // MARK: - Private
    
    /// Shows the splash screen as the root view in the navigation stack.
    private func showSplashScreen() {
        let coordinator = SplashScreenCoordinator()

        coordinator.callback = { [weak self] action in
            guard let self else { return }
            switch action {
            case .login:
                Task { await self.startAuthentication() }
            }
        }
        
        navigationController.setRootCoordinator(coordinator)
    }
    
    private func startAuthentication() async {
        startLoading()
        
        switch await authenticationService.configure(for: BuildSettings.defaultHomeserverAddress) {
        case .success:
            stopLoading()
            showLoginScreen()
        case .failure:
            stopLoading()
            showServerSelectionScreen()
        }
    }
    
    private func showServerSelectionScreen() {
        let parameters = ServerSelectionCoordinatorParameters(authenticationService: authenticationService,
                                                              isModallyPresented: false)
        let coordinator = ServerSelectionCoordinator(parameters: parameters)
        
        coordinator.callback = { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .updated:
                self.showLoginScreen()
            case .dismiss:
                MXLog.failure("ServerSelectionScreen is requesting dismiss when part of a stack.")
            }
        }
        
        navigationController.push(coordinator)
    }
    
    private func showLoginScreen() {
        let parameters = LoginCoordinatorParameters(authenticationService: authenticationService,
                                                    navigationController: navigationController)
        let coordinator = LoginCoordinator(parameters: parameters)

        coordinator.callback = { [weak self] action in
            guard let self else { return }

            switch action {
            case .signedIn(let userSession):
                self.delegate?.authenticationCoordinator(self, didLoginWithSession: userSession)
            }
        }

        navigationController.push(coordinator)
    }
    
    private func showAnalyticsPrompt(with userSession: UserSessionProtocol) {
        let parameters = AnalyticsPromptCoordinatorParameters(userSession: userSession)
        let coordinator = AnalyticsPromptCoordinator(parameters: parameters)
        
        coordinator.callback = { [weak self] in
            guard let self else { return }
            self.delegate?.authenticationCoordinator(self, didLoginWithSession: userSession)
        }
                
        navigationController.setRootCoordinator(coordinator)
    }
    
    /// Show a blocking activity indicator.
    private func startLoading() {
//        activityIndicator = indicatorPresenter.present(.loading(label: ElementL10n.loading, isInteractionBlocking: true))
    }
    
    /// Hide the currently displayed activity indicator.
    private func stopLoading() {
//        activityIndicator = nil
    }
}
