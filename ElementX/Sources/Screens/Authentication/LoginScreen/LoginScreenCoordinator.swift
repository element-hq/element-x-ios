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

struct LoginScreenCoordinatorParameters {
    /// The service used to authenticate the user.
    let authenticationService: AuthenticationServiceProxyProtocol
    
    let analytics: AnalyticsService
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum LoginScreenCoordinatorAction {
    /// The homeserver was updated to one that supports OIDC.
    case configuredForOIDC
    /// Login was successful.
    case signedIn(UserSessionProtocol)
    /// The user's request to login failed due to being on the proxy waitlist.
    case isOnWaitlist(WaitlistScreenCredentials)
}

final class LoginScreenCoordinator: CoordinatorProtocol {
    private let parameters: LoginScreenCoordinatorParameters
    private var viewModel: LoginScreenViewModelProtocol
    
    @CancellableTask private var currentTask: Task<Void, Error>?
    
    private var authenticationService: AuthenticationServiceProxyProtocol { parameters.authenticationService }

    var callback: (@MainActor (LoginScreenCoordinatorAction) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: LoginScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = LoginScreenViewModel(homeserver: parameters.authenticationService.homeserver.value,
                                         slidingSyncLearnMoreURL: ServiceLocator.shared.settings.slidingSyncLearnMoreURL)
    }
    
    // MARK: - Public

    func start() {
        viewModel.callback = { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .parseUsername(let username):
                parseUsername(username)
            case .forgotPassword:
                showForgotPasswordScreen()
            case .login(let username, let password):
                login(username: username, password: password)
            }
        }
    }

    func stop() {
        stopLoading()
    }
    
    func toPresentable() -> AnyView {
        AnyView(LoginScreen(context: viewModel.context))
    }
    
    // MARK: - Private
    
    private static let loadingIndicatorIdentifier = "LoginCoordinatorLoading"
    
    private func startLoading(isInteractionBlocking: Bool) {
        if isInteractionBlocking {
            parameters.userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                                             type: .modal,
                                                                             title: L10n.commonLoading,
                                                                             persistent: true))
        } else {
            viewModel.update(isLoading: true)
        }
    }
    
    private func stopLoading() {
        viewModel.update(isLoading: false)
        parameters.userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
    
    /// Processes an error to either update the flow or display it to the user.
    private func handleError(_ error: AuthenticationServiceError) {
        MXLog.info("Error occurred: \(error)")
        
        switch error {
        case .invalidCredentials:
            viewModel.displayError(.alert(L10n.screenLoginErrorInvalidCredentials))
        case .accountDeactivated:
            viewModel.displayError(.alert(L10n.screenLoginErrorDeactivatedAccount))
        case .slidingSyncNotAvailable:
            viewModel.displayError(.slidingSyncAlert)
        default:
            viewModel.displayError(.alert(L10n.errorUnknown))
        }
    }
    
    /// Requests the authentication coordinator to log in using the specified credentials.
    private func login(username: String, password: String) {
        MXLog.info("Starting login with password.")
        startLoading(isInteractionBlocking: true)
        
        Task {
            parameters.analytics.signpost.beginLogin()
            switch await authenticationService.login(username: username,
                                                     password: password,
                                                     initialDeviceName: UIDevice.current.initialDeviceName,
                                                     deviceID: nil) {
            case .success(let userSession):
                callback?(.signedIn(userSession))
                parameters.analytics.signpost.endLogin()
                stopLoading()
            case .failure(let error):
                stopLoading()
                parameters.analytics.signpost.endLogin()
                switch error {
                case .isOnWaitlist:
                    callback?(.isOnWaitlist(.init(username: username,
                                                  password: password,
                                                  initialDeviceName: UIDevice.current.initialDeviceName,
                                                  deviceID: nil,
                                                  homeserver: authenticationService.homeserver.value)))
                default:
                    handleError(error)
                }
            }
        }
    }
    
    /// Parses the specified username and looks up the homeserver when a Matrix ID is entered.
    private func parseUsername(_ username: String) {
        guard MatrixEntityRegex.isMatrixUserIdentifier(username) else { return }
        
        let homeserverDomain = String(username.split(separator: ":")[1])
        
        startLoading(isInteractionBlocking: false)
        
        Task {
            switch await authenticationService.configure(for: homeserverDomain) {
            case .success:
                stopLoading()
                if authenticationService.homeserver.value.loginMode == .oidc {
                    callback?(.configuredForOIDC)
                } else {
                    updateViewModel()
                }
            case .failure(let error):
                stopLoading()
                handleError(error)
            }
        }
    }
    
    /// Updates the view model with a different homeserver.
    private func updateViewModel() {
        viewModel.update(homeserver: authenticationService.homeserver.value)
    }
    
    /// Shows the forgot password screen.
    private func showForgotPasswordScreen() {
        viewModel.displayError(.alert("Not implemented."))
    }
}
