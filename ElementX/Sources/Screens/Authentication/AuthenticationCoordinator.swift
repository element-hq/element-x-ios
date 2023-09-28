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

@MainActor
protocol AuthenticationCoordinatorDelegate: AnyObject {
    func authenticationCoordinator(_ authenticationCoordinator: AuthenticationCoordinator,
                                   didLoginWithSession userSession: UserSessionProtocol)
}

class AuthenticationCoordinator: CoordinatorProtocol {
    private let authenticationService: AuthenticationServiceProxyProtocol
    private let navigationStackCoordinator: NavigationStackCoordinator
    private let appSettings: AppSettings
    private let analytics: AnalyticsService
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    private var oidcPresenter: OIDCAuthenticationPresenter?
    
    weak var delegate: AuthenticationCoordinatorDelegate?
    
    init(authenticationService: AuthenticationServiceProxyProtocol,
         navigationStackCoordinator: NavigationStackCoordinator,
         appSettings: AppSettings,
         analytics: AnalyticsService,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.authenticationService = authenticationService
        self.navigationStackCoordinator = navigationStackCoordinator
        self.appSettings = appSettings
        self.analytics = analytics
        self.userIndicatorController = userIndicatorController
    }
    
    func start() {
        showOnboarding()
    }
    
    func stop() {
        stopLoading()
    }
    
    func handleOIDCRedirectURL(_ url: URL) {
        guard let oidcPresenter else {
            MXLog.error("Failed to find an OIDC request in progress.")
            return
        }
        
        oidcPresenter.handleUniversalLinkCallback(url)
    }
        
    // MARK: - Private
    
    private func showOnboarding() {
        let coordinator = OnboardingScreenCoordinator()
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .login:
                    Task { await self.startAuthentication() }
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.setRootCoordinator(coordinator)
    }
    
    private func startAuthentication() async {
        startLoading()
        
        switch await authenticationService.configure(for: appSettings.defaultHomeserverAddress) {
        case .success:
            stopLoading()
            showServerConfirmationScreen()
        case .failure:
            stopLoading()
            showServerSelectionScreen(isModallyPresented: false)
        }
    }
    
    private func showServerSelectionScreen(isModallyPresented: Bool) {
        let navigationCoordinator = NavigationStackCoordinator()
        let userIndicatorController: UserIndicatorControllerProtocol! = isModallyPresented ? UserIndicatorController(rootCoordinator: navigationCoordinator) : userIndicatorController
        
        let parameters = ServerSelectionScreenCoordinatorParameters(authenticationService: authenticationService,
                                                                    userIndicatorController: userIndicatorController,
                                                                    isModallyPresented: isModallyPresented)
        let coordinator = ServerSelectionScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .updated:
                    if isModallyPresented {
                        navigationStackCoordinator.setSheetCoordinator(nil)
                    } else {
                        // We are here because the default server failed to respond.
                        if authenticationService.homeserver.value.loginMode == .password {
                            // Add the password login screen directly to the flow, its fine.
                            showLoginScreen()
                        } else {
                            // OIDC is presented from the confirmation screen so replace the
                            // server selection screen which was inserted to handle the failure.
                            navigationStackCoordinator.pop()
                            showServerConfirmationScreen()
                        }
                    }
                case .dismiss:
                    navigationStackCoordinator.setSheetCoordinator(nil)
                }
            }
            .store(in: &cancellables)
        
        if isModallyPresented {
            navigationCoordinator.setRootCoordinator(coordinator)
            navigationStackCoordinator.setSheetCoordinator(userIndicatorController)
        } else {
            navigationStackCoordinator.push(coordinator)
        }
    }
    
    private func showServerConfirmationScreen() {
        let parameters = ServerConfirmationScreenCoordinatorParameters(authenticationService: authenticationService,
                                                                       authenticationFlow: .login)
        let coordinator = ServerConfirmationScreenCoordinator(parameters: parameters)
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .continue(let window):
                if authenticationService.homeserver.value.loginMode == .oidc, let window {
                    showOIDCAuthentication(presentationAnchor: window)
                } else {
                    showLoginScreen()
                }
            case .changeServer:
                showServerSelectionScreen(isModallyPresented: true)
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator)
    }
    
    private func showOIDCAuthentication(presentationAnchor: UIWindow) {
        startLoading()
        
        Task {
            switch await authenticationService.urlForOIDCLogin() {
            case .failure(let error):
                stopLoading()
                handleError(error)
            case .success(let oidcData):
                stopLoading()
                
                let presenter = OIDCAuthenticationPresenter(authenticationService: authenticationService,
                                                            oidcRedirectURL: appSettings.oidcRedirectURL,
                                                            presentationAnchor: presentationAnchor)
                self.oidcPresenter = presenter
                switch await presenter.authenticate(using: oidcData) {
                case .success(let userSession):
                    userHasSignedIn(userSession: userSession)
                case .failure(let error):
                    handleError(error)
                }
                oidcPresenter = nil
            }
        }
    }
    
    private func showLoginScreen() {
        let parameters = LoginScreenCoordinatorParameters(authenticationService: authenticationService,
                                                          analytics: analytics,
                                                          userIndicatorController: userIndicatorController)
        let coordinator = LoginScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }

                switch action {
                case .signedIn(let userSession):
                    userHasSignedIn(userSession: userSession)
                case .configuredForOIDC:
                    // Pop back to the confirmation screen for OIDC login to continue.
                    navigationStackCoordinator.pop(animated: false)
                case .isOnWaitlist(let credentials):
                    showWaitlistScreen(for: credentials)
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator)
    }
    
    private func showWaitlistScreen(for credentials: WaitlistScreenCredentials) {
        let parameters = WaitlistScreenCoordinatorParameters(credentials: credentials,
                                                             authenticationService: authenticationService)
        let coordinator = WaitlistScreenCoordinator(parameters: parameters)
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .signedIn(let userSession):
                userHasSignedIn(userSession: userSession)
            case .cancel:
                navigationStackCoordinator.pop()
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator)
    }
    
    private func userHasSignedIn(userSession: UserSessionProtocol) {
        appSettings.lastLoginDate = .now
        
        showAnalyticsPromptIfNeeded { [weak self] in
            guard let self else { return }
            self.delegate?.authenticationCoordinator(self, didLoginWithSession: userSession)
        }
    }

    private func showAnalyticsPromptIfNeeded(completion: @escaping () -> Void) {
        guard analytics.shouldShowAnalyticsPrompt else {
            completion()
            return
        }
        
        let coordinator = AnalyticsPromptScreenCoordinator(analytics: analytics, termsURL: appSettings.analyticsConfiguration.termsURL)
        
        coordinator.actions
            .sink { action in
                switch action {
                case .done:
                    completion()
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator)
    }
    
    private static let loadingIndicatorIdentifier = "AuthenticationCoordinatorLoading"
    
    private func startLoading() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                              type: .modal,
                                                              title: L10n.commonLoading,
                                                              persistent: true))
    }
    
    private func stopLoading() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
    
    /// Processes an error to either update the flow or display it to the user.
    private func handleError(_ error: AuthenticationServiceError) {
        MXLog.warning("Error occurred: \(error)")
        
        switch error {
        case .oidcError(.notSupported):
            // Temporary alert hijacking the use of .notSupported, can be removed when OIDC support is in the SDK.
            userIndicatorController.alertInfo = AlertInfo(id: UUID(),
                                                          title: L10n.commonError,
                                                          message: L10n.commonServerNotSupported)
        case .oidcError(.userCancellation):
            // No need to show an error, the user cancelled authentication.
            break
        default:
            userIndicatorController.alertInfo = AlertInfo(id: UUID())
        }
    }
}
