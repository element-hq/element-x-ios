//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct SoftLogoutScreenCoordinatorParameters {
    let authenticationService: AuthenticationServiceProtocol
    let credentials: SoftLogoutScreenCredentials
    let keyBackupNeeded: Bool
    let appMediator: AppMediatorProtocol
    let appSettings: AppSettings
    let appHooks: AppHooks
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum SoftLogoutScreenCoordinatorResult: CustomStringConvertible {
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

/// Note: This code was brought over from Riot, we should move the authentication service logic into the view model.
final class SoftLogoutScreenCoordinator: CoordinatorProtocol {
    private let parameters: SoftLogoutScreenCoordinatorParameters
    private var viewModel: SoftLogoutScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<SoftLogoutScreenCoordinatorResult, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    private var authenticationService: AuthenticationServiceProtocol {
        parameters.authenticationService
    }
    
    private var oAuthPresenter: OAuthAuthenticationPresenter?
    
    var actions: AnyPublisher<SoftLogoutScreenCoordinatorResult, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    @MainActor init(parameters: SoftLogoutScreenCoordinatorParameters) {
        self.parameters = parameters
        
        let homeserver = parameters.authenticationService.homeserver
        viewModel = SoftLogoutScreenViewModel(credentials: parameters.credentials,
                                              homeserver: homeserver.value,
                                              keyBackupNeeded: parameters.keyBackupNeeded)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                MXLog.info("Did complete with result: \(action).")
                
                switch action {
                case .login(let password):
                    login(withPassword: password)
                case .forgotPassword:
                    showForgotPasswordScreen()
                case .clearAllData:
                    actionsSubject.send(.clearAllData)
                case .continueWithOAuth:
                    continueWithOAuth(presentationAnchor: viewModel.context.viewState.window)
                }
            }
            .store(in: &cancellables)
    }
    
    func stop() {
        stopLoading()
    }
    
    func toPresentable() -> AnyView {
        AnyView(SoftLogoutScreen(context: viewModel.context))
    }
    
    func handleOAuthCallbackURL(_ url: URL) {
        guard let oAuthPresenter else {
            MXLog.error("Failed to find an OAuth request in progress.")
            return
        }
        
        oAuthPresenter.handleUniversalLinkCallback(url)
    }
    
    // MARK: - Private
    
    private static let loadingIndicatorIdentifier = "\(SoftLogoutScreenCoordinator.self)-Loading"
    
    /// Show an activity indicator whilst loading.
    @MainActor private func startLoading() {
        parameters.userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                                         type: .modal,
                                                                         title: L10n.commonLoading,
                                                                         persistent: true))
    }
    
    /// Hide the currently displayed activity indicator.
    @MainActor private func stopLoading() {
        parameters.userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
    
    /// Shows the forgot password screen.
    @MainActor private func showForgotPasswordScreen() {
        viewModel.displayError(.alert("Not implemented."))
    }
    
    /// Login with the supplied username and password.
    @MainActor private func login(withPassword password: String) {
        let username = parameters.credentials.userID
        
        startLoading()
        
        Task {
            switch await authenticationService.login(username: username,
                                                     password: password,
                                                     initialDeviceName: UIDevice.current.initialDeviceName,
                                                     deviceID: parameters.credentials.deviceID) {
            case .success(let userSession):
                actionsSubject.send(.signedIn(userSession))
                stopLoading()
            case .failure(let error):
                stopLoading()
                handleError(error)
            }
        }
    }
    
    private func continueWithOAuth(presentationAnchor: UIWindow?) {
        guard let presentationAnchor else { return }
        
        startLoading()
        
        Task {
            switch await authenticationService.urlForOAuthLogin(loginHint: nil) {
            case .failure(let error):
                stopLoading()
                handleError(error)
            case .success(let oAuthData):
                stopLoading()
                
                let presenter = OAuthAuthenticationPresenter(authenticationService: parameters.authenticationService,
                                                             redirectURL: parameters.appSettings.oAuthRedirectURL,
                                                             presentationAnchor: presentationAnchor,
                                                             appMediator: parameters.appMediator,
                                                             appHooks: parameters.appHooks,
                                                             userIndicatorController: parameters.userIndicatorController)
                self.oAuthPresenter = presenter
                switch await presenter.authenticate(using: oAuthData) {
                case .success(let userSession):
                    actionsSubject.send(.signedIn(userSession))
                case .failure(let error):
                    handleError(error)
                }
                self.oAuthPresenter = nil
            }
        }
    }
    
    /// Processes an error to either update the flow or display it to the user.
    private func handleError(_ error: AuthenticationServiceError) {
        switch error {
        case .invalidCredentials:
            viewModel.displayError(.alert(L10n.screenLoginErrorInvalidCredentials))
        case .accountDeactivated:
            viewModel.displayError(.alert(L10n.screenLoginErrorDeactivatedAccount))
        case .oAuthError(.notSupported):
            // Temporary alert hijacking the use of .notSupported, can be removed when OAuth support is in the SDK.
            viewModel.displayError(.alert(L10n.commonServerNotSupported))
        case .oAuthError(.userCancellation):
            // No need to show an error, the user cancelled authentication.
            break
        case .sessionTokenRefreshNotSupported:
            viewModel.displayError(.refreshTokenAlert)
        default:
            viewModel.displayError(.alert(L10n.errorUnknown))
        }
    }
}
