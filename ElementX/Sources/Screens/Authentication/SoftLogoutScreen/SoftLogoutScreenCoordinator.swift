//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct SoftLogoutScreenCoordinatorParameters {
    let authenticationService: AuthenticationServiceProtocol
    let credentials: SoftLogoutScreenCredentials
    let keyBackupNeeded: Bool
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

// Note: This code was brought over from Riot, we should move the authentication service logic into the view model.
final class SoftLogoutScreenCoordinator: CoordinatorProtocol {
    private let parameters: SoftLogoutScreenCoordinatorParameters
    private var viewModel: SoftLogoutScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<SoftLogoutScreenCoordinatorResult, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    private var authenticationService: AuthenticationServiceProtocol { parameters.authenticationService }
    private var oidcPresenter: OIDCAuthenticationPresenter?
    
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
                MXLog.info("[SoftLogoutCoordinator] SoftLogoutViewModel did complete with result: \(action).")

                switch action {
                case .login(let password):
                    login(withPassword: password)
                case .forgotPassword:
                    showForgotPasswordScreen()
                case .clearAllData:
                    actionsSubject.send(.clearAllData)
                case .continueWithOIDC:
                    continueWithOIDC(presentationAnchor: viewModel.context.viewState.window)
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
    
    func handleOIDCRedirectURL(_ url: URL) {
        guard let oidcPresenter else {
            MXLog.error("Failed to find an OIDC request in progress.")
            return
        }
        
        oidcPresenter.handleUniversalLinkCallback(url)
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

    private func continueWithOIDC(presentationAnchor: UIWindow?) {
        guard let presentationAnchor else { return }
        
        startLoading()
        
        Task {
            switch await authenticationService.urlForOIDCLogin() {
            case .failure(let error):
                stopLoading()
                handleError(error)
            case .success(let oidcData):
                stopLoading()
                
                let presenter = OIDCAuthenticationPresenter(authenticationService: parameters.authenticationService,
                                                            oidcRedirectURL: ServiceLocator.shared.settings.oidcRedirectURL,
                                                            presentationAnchor: presentationAnchor)
                self.oidcPresenter = presenter
                switch await presenter.authenticate(using: oidcData) {
                case .success(let userSession):
                    actionsSubject.send(.signedIn(userSession))
                case .failure(let error):
                    handleError(error)
                }
                self.oidcPresenter = nil
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
        case .oidcError(.notSupported):
            // Temporary alert hijacking the use of .notSupported, can be removed when OIDC support is in the SDK.
            viewModel.displayError(.alert(L10n.commonServerNotSupported))
        case .oidcError(.userCancellation):
            // No need to show an error, the user cancelled authentication.
            break
        case .sessionTokenRefreshNotSupported:
            viewModel.displayError(.refreshTokenAlert)
        default:
            viewModel.displayError(.alert(L10n.errorUnknown))
        }
    }
}
