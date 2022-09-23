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

final class SoftLogoutCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: SoftLogoutCoordinatorParameters
    private let softLogoutHostingController: UIViewController
    private var softLogoutViewModel: SoftLogoutViewModelProtocol
    /// Passed to the OIDC service to provide a view controller from which to present the authentication session.
    private let oidcUserAgent: OIDExternalUserAgentIOS?
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    private var successIndicator: UserIndicator?
    
    /// The wizard used to handle the registration flow.
    private var authenticationService: AuthenticationServiceProxyProtocol { parameters.authenticationService }
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: (@MainActor (SoftLogoutCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    @MainActor init(parameters: SoftLogoutCoordinatorParameters) {
        self.parameters = parameters

        let homeserver = parameters.authenticationService.homeserver
        
        let viewModel = SoftLogoutViewModel(credentials: parameters.credentials,
                                            homeserver: homeserver,
                                            keyBackupNeeded: parameters.keyBackupNeeded)
        softLogoutViewModel = viewModel

        let view = SoftLogoutScreen(context: viewModel.context)
        softLogoutHostingController = UIHostingController(rootView: view)
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: softLogoutHostingController)
        oidcUserAgent = OIDExternalUserAgentIOS(presenting: softLogoutHostingController)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[SoftLogoutCoordinator] did start.")

        softLogoutViewModel.callback = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[SoftLogoutCoordinator] SoftLogoutViewModel did complete with result: \(result).")

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
    
    func toPresentable() -> UIViewController {
        softLogoutHostingController
    }

    func stop() {
        stopLoading()
    }
    
    // MARK: - Private
    
    /// Show an activity indicator whilst loading.
    @MainActor private func startLoading() {
        loadingIndicator = indicatorPresenter.present(.loading(label: ElementL10n.loading, isInteractionBlocking: true))
    }
    
    /// Hide the currently displayed activity indicator.
    @MainActor private func stopLoading() {
        loadingIndicator = nil
    }

    /// Shows the forgot password screen.
    @MainActor private func showForgotPasswordScreen() {
        MXLog.debug("[SoftLogoutCoordinator] showForgotPasswordScreen")

        softLogoutViewModel.displayError(.alert("Not implemented."))
    }

    /// Login with the supplied username and password.
    @MainActor private func login(withPassword password: String) {
        let username = parameters.credentials.userId

        startLoading()

        Task {
            switch await authenticationService.login(username: username,
                                                     password: password,
                                                     initialDeviceName: UIDevice.current.initialDisplayName,
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
        guard let oidcUserAgent = oidcUserAgent else {
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
            softLogoutViewModel.displayError(.alert(ElementL10n.authInvalidLoginParam))
        case .accountDeactivated:
            softLogoutViewModel.displayError(.alert(ElementL10n.authInvalidLoginDeactivatedAccount))
        default:
            softLogoutViewModel.displayError(.alert(ElementL10n.unknownError))
        }
    }
}
