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
    /// The service used to authenticate the user.
    let authenticationService: AuthenticationServiceProtocol
    /// The navigation router used to present the server selection screen.
    let navigationRouter: NavigationRouterType
}

enum LoginCoordinatorAction {
    /// Login was successful.
    case signedIn(UserSessionProtocol)
    /// Continue using OIDC.
    case continueWithOIDC
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
    
    private var authenticationService: AuthenticationServiceProtocol { parameters.authenticationService }
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
        
        let viewModel = LoginViewModel(homeserver: parameters.authenticationService.homeserver)
        loginViewModel = viewModel
        
        let view = LoginScreen(context: viewModel.context)
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
    private func handleError(_ error: AuthenticationServiceError) {
        switch error {
        case .invalidCredentials:
            loginViewModel.displayError(.alert(ElementL10n.authInvalidLoginParam))
        case .accountDeactivated:
            loginViewModel.displayError(.alert(ElementL10n.authInvalidLoginDeactivatedAccount))
        default:
            loginViewModel.displayError(.alert(ElementL10n.unknownError))
        }
    }
    
    /// Requests the authentication coordinator to log in using the specified credentials.
    private func login(username: String, password: String) {
        startLoading(isInteractionBlocking: true)
        
        Task {
            switch await authenticationService.login(username: username, password: password) {
            case .success(let userSession):
                callback?(.signedIn(userSession))
                stopLoading()
            case .failure(let error):
                stopLoading()
                handleError(error)
            }
        }
    }
    
    /// Parses the specified username and looks up the homeserver when a Matrix ID is entered.
    private func parseUsername(_ username: String) {
        guard authenticationService.usernameIsMatrixID(username) else { return }
        
        let homeserverDomain = String(username.split(separator: ":")[1])
        
        startLoading(isInteractionBlocking: false)
        
        Task {
            switch await authenticationService.startLogin(for: homeserverDomain) {
            case .success:
                updateViewModel()
                stopLoading()
            case .failure(let error):
                stopLoading()
                handleError(error)
            }
        }
    }
    
    /// Updates the view model with a different homeserver.
    private func updateViewModel() {
        loginViewModel.update(homeserver: authenticationService.homeserver)
        indicateSuccess()
    }
    
    /// Presents the server selection screen as a modal.
    private func presentServerSelectionScreen() {
        MXLog.debug("[LoginCoordinator] presentServerSelectionScreen")
        let parameters = ServerSelectionCoordinatorParameters(authenticationService: authenticationService,
                                                              hasModalPresentation: true)
        let coordinator = ServerSelectionCoordinator(parameters: parameters)
        coordinator.callback = { [weak self, weak coordinator] action in
            guard let self = self, let coordinator = coordinator else { return }
            self.serverSelectionCoordinator(coordinator, didCompleteWith: action)
        }
        
        coordinator.start()
        add(childCoordinator: coordinator)
        
        let modalRouter = NavigationRouter(navigationController: ElementNavigationController())
        modalRouter.setRootModule(coordinator)
        
        navigationRouter.present(modalRouter, animated: true)
    }
    
    /// Handles the result from the server selection modal, dismissing it after updating the view.
    private func serverSelectionCoordinator(_ coordinator: ServerSelectionCoordinator,
                                            didCompleteWith action: ServerSelectionCoordinatorAction) {
        navigationRouter.dismissModule(animated: true) { [weak self] in
            if action == .updated {
                self?.updateViewModel()
            }

            self?.remove(childCoordinator: coordinator)
        }
    }

    /// Shows the forgot password screen.
    private func showForgotPasswordScreen() {
        loginViewModel.displayError(.alert("Not implemented."))
    }
}
