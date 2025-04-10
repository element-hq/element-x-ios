//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

@MainActor
protocol AuthenticationFlowCoordinatorDelegate: AnyObject {
    func authenticationFlowCoordinator(didLoginWithSession userSession: UserSessionProtocol)
}

class AuthenticationFlowCoordinator: FlowCoordinatorProtocol {
    private let authenticationService: AuthenticationServiceProtocol
    private let bugReportService: BugReportServiceProtocol
    private let navigationRootCoordinator: NavigationRootCoordinator
    private let navigationStackCoordinator: NavigationStackCoordinator
    private let appMediator: AppMediatorProtocol
    private let appSettings: AppSettings
    private let analytics: AnalyticsService
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let qrCodeLoginService: QRCodeLoginServiceProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    private var oidcPresenter: OIDCAuthenticationPresenter?
    
    // periphery:ignore - retaining purpose
    private var bugReportFlowCoordinator: BugReportFlowCoordinator?
    
    weak var delegate: AuthenticationFlowCoordinatorDelegate?
    
    init(authenticationService: AuthenticationServiceProtocol,
         qrCodeLoginService: QRCodeLoginServiceProtocol,
         bugReportService: BugReportServiceProtocol,
         navigationRootCoordinator: NavigationRootCoordinator,
         appMediator: AppMediatorProtocol,
         appSettings: AppSettings,
         analytics: AnalyticsService,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.authenticationService = authenticationService
        self.bugReportService = bugReportService
        self.navigationRootCoordinator = navigationRootCoordinator
        self.appMediator = appMediator
        self.appSettings = appSettings
        self.analytics = analytics
        self.userIndicatorController = userIndicatorController
        self.qrCodeLoginService = qrCodeLoginService
        
        navigationStackCoordinator = NavigationStackCoordinator()
    }
    
    func start() {
        showStartScreen()
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        fatalError()
    }
    
    func clearRoute(animated: Bool) {
        fatalError()
    }
    
    // MARK: - Private
    
    private func showStartScreen() {
        let parameters = AuthenticationStartScreenParameters(showCreateAccountButton: appSettings.showCreateAccountButton,
                                                             isBugReportServiceEnabled: bugReportService.isEnabled)
        let coordinator = AuthenticationStartScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .loginManually:
                    showServerConfirmationScreen(authenticationFlow: .login)
                case .loginWithQR:
                    startQRCodeLogin()
                case .register:
                    showServerConfirmationScreen(authenticationFlow: .register)
                case .reportProblem:
                    showReportProblemScreen()
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.setRootCoordinator(coordinator)
        
        navigationRootCoordinator.setRootCoordinator(navigationStackCoordinator)
    }
    
    private func startQRCodeLogin() {
        let coordinator = QRCodeLoginScreenCoordinator(parameters: .init(qrCodeLoginService: qrCodeLoginService,
                                                                         orientationManager: appMediator.windowManager,
                                                                         appMediator: appMediator))
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else {
                return
            }
            switch action {
            case .signInManually:
                navigationStackCoordinator.setSheetCoordinator(nil)
                showServerConfirmationScreen(authenticationFlow: .login)
            case .cancel:
                navigationStackCoordinator.setSheetCoordinator(nil)
            case .done(let userSession):
                navigationStackCoordinator.setSheetCoordinator(nil)
                // Since the qr code login flow includes verification
                appSettings.hasRunIdentityConfirmationOnboarding = true
                DispatchQueue.main.async {
                    self.userHasSignedIn(userSession: userSession)
                }
            }
        }
        .store(in: &cancellables)
        navigationStackCoordinator.setSheetCoordinator(coordinator)
    }
    
    private func showReportProblemScreen() {
        bugReportFlowCoordinator = BugReportFlowCoordinator(parameters: .init(presentationMode: .sheet(navigationStackCoordinator),
                                                                              userIndicatorController: userIndicatorController,
                                                                              bugReportService: bugReportService,
                                                                              userSession: nil))
        bugReportFlowCoordinator?.start()
    }
    
    private func showServerConfirmationScreen(authenticationFlow: AuthenticationFlow) {
        // Reset the service back to the default homeserver before continuing. This ensures
        // we check that registration is supported if it was previously configured for login.
        authenticationService.reset()
        
        let parameters = ServerConfirmationScreenCoordinatorParameters(authenticationService: authenticationService,
                                                                       authenticationFlow: authenticationFlow,
                                                                       slidingSyncLearnMoreURL: appSettings.slidingSyncLearnMoreURL,
                                                                       userIndicatorController: userIndicatorController)
        let coordinator = ServerConfirmationScreenCoordinator(parameters: parameters)
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .continueWithOIDC(let oidcData, let window):
                showOIDCAuthentication(oidcData: oidcData, presentationAnchor: window)
            case .continueWithPassword:
                showLoginScreen()
            case .changeServer:
                showServerSelectionScreen(authenticationFlow: authenticationFlow)
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator)
    }
    
    private func showServerSelectionScreen(authenticationFlow: AuthenticationFlow) {
        let navigationCoordinator = NavigationStackCoordinator()
        
        let parameters = ServerSelectionScreenCoordinatorParameters(authenticationService: authenticationService,
                                                                    authenticationFlow: authenticationFlow,
                                                                    slidingSyncLearnMoreURL: appSettings.slidingSyncLearnMoreURL,
                                                                    userIndicatorController: userIndicatorController)
        let coordinator = ServerSelectionScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .updated:
                    navigationStackCoordinator.setSheetCoordinator(nil)
                case .dismiss:
                    navigationStackCoordinator.setSheetCoordinator(nil)
                }
            }
            .store(in: &cancellables)
        
        navigationCoordinator.setRootCoordinator(coordinator)
        navigationStackCoordinator.setSheetCoordinator(navigationCoordinator)
    }
    
    private func showOIDCAuthentication(oidcData: OIDCAuthorizationDataProxy, presentationAnchor: UIWindow) {
        let presenter = OIDCAuthenticationPresenter(authenticationService: authenticationService,
                                                    oidcRedirectURL: appSettings.oidcRedirectURL,
                                                    presentationAnchor: presentationAnchor,
                                                    userIndicatorController: userIndicatorController)
        oidcPresenter = presenter
        
        Task {
            switch await presenter.authenticate(using: oidcData) {
            case .success(let userSession):
                userHasSignedIn(userSession: userSession)
            case .failure:
                break // Nothing to do, the alerts are handled by the presenter.
            }
            oidcPresenter = nil
        }
    }
    
    private func showLoginScreen() {
        let parameters = LoginScreenCoordinatorParameters(authenticationService: authenticationService,
                                                          slidingSyncLearnMoreURL: appSettings.slidingSyncLearnMoreURL,
                                                          userIndicatorController: userIndicatorController,
                                                          analytics: analytics)
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
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator)
    }
        
    private func userHasSignedIn(userSession: UserSessionProtocol) {
        delegate?.authenticationFlowCoordinator(didLoginWithSession: userSession)
    }
}
