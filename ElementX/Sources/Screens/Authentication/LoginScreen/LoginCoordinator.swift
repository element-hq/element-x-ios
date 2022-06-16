//
// Copyright 2021 New Vector Ltd
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
import MatrixRustSDK

struct LoginCoordinatorParameters {
    let navigationRouter: NavigationRouterType
    /// The homeserver to be shown initially.
    let homeserver: LoginHomeserver
}

enum LoginCoordinatorAction: CustomStringConvertible {
    /// Login with the associated username and password.
    case login(username: String, password: String)
    /// Continue using OIDC.
    case continueWithOIDC
    
    /// A string representation of the action, ignoring any associated values that could leak PII.
    var description: String {
        switch self {
        case .login:
            return "login"
        case .continueWithOIDC:
            return "continueWithOIDC"
        }
    }
}

final class LoginCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: LoginCoordinatorParameters
    private let loginHostingController: UIViewController
    private var loginViewModel: LoginViewModelProtocol
    
    private var currentTask: Task<Void, Error>? {
        willSet {
            currentTask?.cancel()
        }
    }
    
    private var navigationRouter: NavigationRouterType { parameters.navigationRouter }
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var activityIndicator: UserIndicator?
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: (@MainActor (LoginCoordinatorAction) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: LoginCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = LoginViewModel(homeserver: parameters.homeserver)
        loginViewModel = viewModel
        
        let view = LoginScreen(viewModel: viewModel.context)
        loginHostingController = UIHostingController(rootView: view)
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: loginHostingController)
    }
    
    // MARK: - Public
    func start() {
        MXLog.debug("[LoginCoordinator] did start.")
        
        loginViewModel.callback = { [weak self] action in
            guard let self = self else { return }
            MXLog.debug("[LoginCoordinator] LoginViewModel did callback with result: \(action).")
            
            switch action {
            case .selectServer:
                self.presentServerSelectionScreen()
            case .parseUsername(let username):
                self.parseUsername(username)
            case .forgotPassword:
                self.showForgotPasswordScreen()
            case .login(let username, let password):
                self.login(username: username, password: password)
            case .continueWithOIDC:
                self.callback?(.continueWithOIDC)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        loginHostingController
    }
    
    // MARK: - Private
    
    /// Show a blocking activity indicator whilst saving.
    private func startLoading(isInteractionBlocking: Bool) {
        activityIndicator = indicatorPresenter.present(.loading(label: ElementL10n.loading, isInteractionBlocking: isInteractionBlocking))
        
        if !isInteractionBlocking {
            loginViewModel.update(isLoading: true)
        }
    }
    
    /// Show a non-blocking indicator that an operation was successful.
    private func indicateSuccess() {
        activityIndicator = indicatorPresenter.present(.success(label: ElementL10n.dialogTitleSuccess))
    }
    
    /// Show a non-blocking indicator that an operation failed.
    private func indicateFailure() {
        activityIndicator = indicatorPresenter.present(.error(label: ElementL10n.dialogTitleError))
    }
    
    /// Hide the currently displayed activity indicator.
    private func stopLoading() {
        loginViewModel.update(isLoading: false)
        activityIndicator = nil
    }
    
    /// Processes an error to either update the flow or display it to the user.
    private func handleError(_ error: Error) {
        loginViewModel.displayError(.alert(error.localizedDescription))
    }
    
    /// Requests the authentication coordinator to log in using the specified credentials.
    private func login(username: String, password: String) {
        var username = loginViewModel.context.username
        
        if !isMXID(username: username) {
            let homeserver = loginViewModel.context.viewState.homeserver
            username = "@\(username):\(homeserver.address)"
        }
        
        callback?(.login(username: username, password: password))
    }
    
    /// Parses the specified username and looks up the homeserver when a Matrix ID is entered.
    private func parseUsername(_ username: String) {
        guard isMXID(username: username) else { return }
        
        let domain = String(username.split(separator: ":")[1])
        
        let homeserver = LoginHomeserver(address: domain)
        updateViewModel(homeserver: homeserver)
        indicateSuccess()
    }
    
    /// Checks whether the specified username is a Matrix ID or not.
    private func isMXID(username: String) -> Bool {
        let range = NSRange(location: 0, length: username.count)
        
        let detector = try? NSRegularExpression(pattern: MatrixEntityRegex.userId.rawValue, options: .caseInsensitive)
        return detector?.numberOfMatches(in: username, range: range) ?? 0 > 0
    }
    
    /// Updates the view model with a different homeserver.
    private func updateViewModel(homeserver: LoginHomeserver) {
        loginViewModel.update(homeserver: homeserver)
        indicateSuccess()
    }
    
    /// Presents the server selection screen as a modal.
    private func presentServerSelectionScreen() {
        loginViewModel.displayError(.alert("Not implemented. Enter a full Matrix ID such as @user:server.com"))
    }

    /// Shows the forgot password screen.
    private func showForgotPasswordScreen() {
        loginViewModel.displayError(.alert("Not implemented."))
    }
}
