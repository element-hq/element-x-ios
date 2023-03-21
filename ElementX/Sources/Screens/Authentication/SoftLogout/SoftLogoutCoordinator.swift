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

import AppAuth
import SwiftUI

struct SoftLogoutCoordinatorParameters {
    let authenticationService: AuthenticationServiceProxyProtocol
    let credentials: SoftLogoutCredentials
    let keyBackupNeeded: Bool
}

enum SoftLogoutCoordinatorResult: CustomStringConvertible {
    /// Login was successful.
    case signedIn(UserSessionProtocol)
    /// Clear all user data
    case clearAllData
    
    /// A string representation of the result, ignoring any associated values that could leak PII.
    var description: String {
        switch self {
        case .signedIn:
            return "signedIn"
        case .clearAllData:
            return "clearAllData"
        }
    }
}

final class SoftLogoutCoordinator: CoordinatorProtocol {
    private let parameters: SoftLogoutCoordinatorParameters
    private var viewModel: SoftLogoutViewModelProtocol
    private let hostingController: UIViewController
    /// Passed to the OIDC service to provide a view controller from which to present the authentication session.
    private let oidcUserAgent: OIDExternalUserAgentIOS?
    
    /// The wizard used to handle the registration flow.
    private var authenticationService: AuthenticationServiceProxyProtocol { parameters.authenticationService }

    var callback: (@MainActor (SoftLogoutCoordinatorResult) -> Void)?
    
    @MainActor init(parameters: SoftLogoutCoordinatorParameters) {
        self.parameters = parameters

        let homeserver = parameters.authenticationService.homeserver
        
        viewModel = SoftLogoutViewModel(credentials: parameters.credentials,
                                        homeserver: homeserver,
                                        keyBackupNeeded: parameters.keyBackupNeeded)
        
        hostingController = UIHostingController(rootView: SoftLogoutScreen(context: viewModel.context))
        oidcUserAgent = OIDExternalUserAgentIOS(presenting: hostingController)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.callback = { [weak self] result in
            guard let self else { return }
            MXLog.info("[SoftLogoutCoordinator] SoftLogoutViewModel did complete with result: \(result).")

            switch result {
            case .login(let password):
                self.login(withPassword: password)
            case .forgotPassword:
                self.showForgotPasswordScreen()
            case .clearAllData:
                self.callback?(.clearAllData)
            case .continueWithOIDC:
                self.loginWithOIDC()
            }
        }
    }
    
    func stop() {
        stopLoading()
    }
    
    func toPresentable() -> AnyView {
        AnyView(SoftLogoutScreen(context: viewModel.context))
    }
    
    // MARK: - Private
    
    static let loadingIndicatorIdentifier = "SoftLogoutLoading"
    
    /// Show an activity indicator whilst loading.
    @MainActor private func startLoading() {
        ServiceLocator.shared.userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                                                    type: .modal,
                                                                                    title: L10n.commonLoading,
                                                                                    persistent: true))
    }
    
    /// Hide the currently displayed activity indicator.
    @MainActor private func stopLoading() {
        ServiceLocator.shared.userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }

    /// Shows the forgot password screen.
    @MainActor private func showForgotPasswordScreen() {
        viewModel.displayError(.alert("Not implemented."))
    }

    /// Login with the supplied username and password.
    @MainActor private func login(withPassword password: String) {
        let username = parameters.credentials.userId

        startLoading()

        Task {
            switch await authenticationService.login(username: username,
                                                     password: password,
                                                     initialDeviceName: UIDevice.current.initialDeviceName,
                                                     deviceId: parameters.credentials.deviceId) {
            case .success(let userSession):
                callback?(.signedIn(userSession))
                stopLoading()
            case .failure(let error):
                stopLoading()
                handleError(error)
            }
        }
    }

    private func loginWithOIDC() {
        guard let oidcUserAgent else {
            handleError(AuthenticationServiceError.oidcError(.notSupported))
            return
        }

        startLoading()

        Task {
            switch await authenticationService.loginWithOIDC(userAgent: oidcUserAgent) {
            case .success(let userSession):
                callback?(.signedIn(userSession))
                stopLoading()
            case .failure(let error):
                stopLoading()
                handleError(error)
            }
        }
    }

    /// Processes an error to either update the flow or display it to the user.
    private func handleError(_ error: AuthenticationServiceError) {
        switch error {
        case .invalidCredentials:
            viewModel.displayError(.alert(L10n.loginErrorInvalidCredentials))
        case .accountDeactivated:
            viewModel.displayError(.alert(L10n.loginErrorDeactivatedAccount))
        default:
            viewModel.displayError(.alert(L10n.errorUnknown))
        }
    }
}
