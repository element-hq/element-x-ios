//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias LoginScreenViewModelType = StateStoreViewModel<LoginScreenViewState, LoginScreenViewAction>

class LoginScreenViewModel: LoginScreenViewModelType, LoginScreenViewModelProtocol {
    private let authenticationService: AuthenticationServiceProtocol
    private let slidingSyncLearnMoreURL: URL
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let analytics: AnalyticsService
    
    private var actionsSubject: PassthroughSubject<LoginScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<LoginScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(authenticationService: AuthenticationServiceProtocol,
         slidingSyncLearnMoreURL: URL,
         userIndicatorController: UserIndicatorControllerProtocol,
         analytics: AnalyticsService) {
        self.authenticationService = authenticationService
        self.slidingSyncLearnMoreURL = slidingSyncLearnMoreURL
        self.userIndicatorController = userIndicatorController
        self.analytics = analytics
        
        let viewState = LoginScreenViewState(homeserver: authenticationService.homeserver.value)
        
        super.init(initialViewState: viewState)
        
        authenticationService.homeserver
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.homeserver, on: self)
            .store(in: &cancellables)
    }

    override func process(viewAction: LoginScreenViewAction) {
        switch viewAction {
        case .parseUsername:
            parseUsername()
        case .next:
            login()
        }
    }
    
    func stopLoading() {
        state.isLoading = false
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
    
    // MARK: - Private
    
    /// Parses the specified username and looks up the homeserver when a Matrix ID is entered.
    private func parseUsername() {
        let username = state.bindings.username
        
        guard MatrixEntityRegex.isMatrixUserIdentifier(username) else { return }
        
        let homeserverDomain = String(username.split(separator: ":")[1])
        
        startLoading(isInteractionBlocking: false)
        
        Task {
            switch await authenticationService.configure(for: homeserverDomain, flow: .login) {
            case .success:
                if authenticationService.homeserver.value.loginMode == .oidc {
                    actionsSubject.send(.configuredForOIDC)
                }
                stopLoading()
            case .failure(let error):
                stopLoading()
                handleError(error)
            }
        }
    }
    
    /// Requests the authentication coordinator to log in using the specified credentials.
    private func login() {
        MXLog.info("Starting login with password.")
        startLoading(isInteractionBlocking: true)
        
        Task {
            analytics.signpost.beginLogin()
            switch await authenticationService.login(username: state.bindings.username,
                                                     password: state.bindings.password,
                                                     initialDeviceName: UIDevice.current.initialDeviceName,
                                                     deviceID: nil) {
            case .success(let userSession):
                actionsSubject.send(.signedIn(userSession))
                analytics.signpost.endLogin()
                stopLoading()
            case .failure(let error):
                stopLoading()
                analytics.signpost.endLogin()
                handleError(error)
            }
        }
    }
    
    private static let loadingIndicatorIdentifier = "\(LoginScreenCoordinatorAction.self)-Loading"
    
    private func startLoading(isInteractionBlocking: Bool) {
        if isInteractionBlocking {
            userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                                  type: .modal,
                                                                  title: L10n.commonLoading,
                                                                  persistent: true))
        } else {
            state.isLoading = true
        }
    }
    
    /// Processes an error to either update the flow or display it to the user.
    private func handleError(_ error: AuthenticationServiceError) {
        MXLog.info("Error occurred: \(error)")
        
        switch error {
        case .invalidCredentials:
            state.bindings.alertInfo = AlertInfo(id: .credentialsAlert,
                                                 title: L10n.commonError,
                                                 message: L10n.screenLoginErrorInvalidCredentials)
        case .accountDeactivated:
            state.bindings.alertInfo = AlertInfo(id: .deactivatedAlert,
                                                 title: L10n.commonError,
                                                 message: L10n.screenLoginErrorDeactivatedAccount)
        case .invalidWellKnown(let error):
            state.bindings.alertInfo = AlertInfo(id: .slidingSyncAlert,
                                                 title: L10n.commonServerNotSupported,
                                                 message: L10n.screenChangeServerErrorInvalidWellKnown(error))
        case .slidingSyncNotAvailable:
            let openURL = { UIApplication.shared.open(self.slidingSyncLearnMoreURL) }
            state.bindings.alertInfo = AlertInfo(id: .slidingSyncAlert,
                                                 title: L10n.commonServerNotSupported,
                                                 message: L10n.screenChangeServerErrorNoSlidingSyncMessage,
                                                 primaryButton: .init(title: L10n.actionLearnMore, role: .cancel, action: openURL),
                                                 secondaryButton: .init(title: L10n.actionCancel, action: nil))
            
            // Clear out the invalid username to avoid an attempted login to matrix.org
            state.bindings.username = ""
        case .sessionTokenRefreshNotSupported:
            state.bindings.alertInfo = AlertInfo(id: .refreshTokenAlert,
                                                 title: L10n.commonServerNotSupported,
                                                 message: L10n.screenLoginErrorRefreshTokens)
        default:
            state.bindings.alertInfo = AlertInfo(id: .unknown)
        }
    }
}
