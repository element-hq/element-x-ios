//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftState
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
    
    enum State: StateType {
        /// The state machine hasn't started.
        case initial
        
        /// The initial screen shown when you first launch the app.
        case startScreen
        /// The initial screen with the selection of account provider having been restricted.
        case restrictedStartScreen
        
        /// The screen used for the whole QR Code flow.
        case qrCodeLoginScreen
        
        /// The screen to continue authentication with the current server.
        case serverConfirmationScreen
        /// The screen to choose a different server.
        case serverSelectionScreen
        /// The web authentication session is being presented.
        case oidcAuthentication
        /// The screen to login with a password.
        case loginScreen
        
        /// The screen to report an error.
        case bugReportFlow
        
        /// The flow is complete.
        case complete
    }
    
    enum Event: EventType {
        /// The flow is being started.
        case start(allowOtherAccountProviders: Bool)
        
        /// Modify the flow using the provisioning parameters in the `userInfo`.
        case applyProvisioningParameters
        
        /// The user would like to login with a QR code.
        case loginWithQR
        /// Show the server confirmation screen.
        case confirmServer(AuthenticationFlow)
        /// The user encountered a problem.
        case reportProblem
        
        /// The QR login flow was aborted.
        case cancelledLoginWithQR(previousState: State)
        /// The user aborted manual login.
        case cancelledServerConfirmation
        
        /// The user would like to enter a different server.
        case changeServer(AuthenticationFlow)
        /// The user is no longer selecting a server.
        case dismissedServerSelection
        
        /// Show the web authentication session for OIDC (using the parameters in the `userInfo`).
        case continueWithOIDC
        /// The web authentication session was aborted.
        case cancelledOIDCAuthentication(previousState: State)
        /// Show the screen to login with password (with the optional login hint in the `userInfo`).
        case continueWithPassword
        /// The password login was aborted.
        case cancelledPasswordLogin(previousState: State)
        
        /// The user has finished reporting a problem (or viewing the logs).
        case bugReportFlowComplete(previousState: State)
        
        /// The user has successfully signed in. The new session can be found in the `userInfo`.
        case signedIn
    }
    
    private let stateMachine: StateMachine<State, Event>
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
        
        stateMachine = .init(state: .initial)
        configureStateMachine()
    }
    
    func start() {
        stateMachine.tryEvent(.start(allowOtherAccountProviders: appSettings.allowOtherAccountProviders))
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        switch appRoute {
        case .accountProvisioningLink(let provisioningParameters):
            guard appSettings.allowOtherAccountProviders else {
                MXLog.error("Provisioning links not allowed, ignoring.")
                return
            }
            
            if stateMachine.state != .startScreen {
                clearRoute(animated: animated)
            }
            
            stateMachine.tryEvent(.applyProvisioningParameters, userInfo: provisioningParameters)
        default:
            fatalError()
        }
    }
    
    func clearRoute(animated: Bool) {
        switch stateMachine.state {
        case .initial, .startScreen, .restrictedStartScreen:
            break
        case .qrCodeLoginScreen:
            navigationStackCoordinator.setSheetCoordinator(nil)
            stateMachine.tryEvent(.cancelledLoginWithQR(previousState: .initial)) // Needs to be handled manually.
        case .serverConfirmationScreen:
            navigationStackCoordinator.popToRoot(animated: animated)
        case .serverSelectionScreen:
            navigationStackCoordinator.setSheetCoordinator(nil)
            navigationStackCoordinator.popToRoot(animated: animated)
        case .oidcAuthentication:
            oidcPresenter?.cancel()
            navigationStackCoordinator.popToRoot(animated: animated)
        case .loginScreen:
            navigationStackCoordinator.popToRoot(animated: animated)
        case .bugReportFlow:
            navigationStackCoordinator.setSheetCoordinator(nil)
        case .complete:
            fatalError()
        }
    }
    
    // MARK: - Setup
    
    private func configureStateMachine() {
        stateMachine.addRoutes(event: .start(allowOtherAccountProviders: true), transitions: [.initial => .startScreen]) { [weak self] _ in
            self?.showStartScreen(fromState: .initial)
        }
        stateMachine.addRoutes(event: .start(allowOtherAccountProviders: false), transitions: [.initial => .restrictedStartScreen]) { [weak self] _ in
            self?.showStartScreen(fromState: .initial)
        }
        
        stateMachine.addRoutes(event: .applyProvisioningParameters, transitions: [.initial => .restrictedStartScreen,
                                                                                  .startScreen => .restrictedStartScreen]) { [weak self] context in
            guard let provisioningParameters = context.userInfo as? AccountProvisioningParameters else { fatalError("The authentication configuration is missing.") }
            self?.showStartScreen(fromState: context.fromState, applying: provisioningParameters)
        }
        
        // QR Code
        
        stateMachine.addRoutes(event: .loginWithQR, transitions: [.startScreen => .qrCodeLoginScreen,
                                                                  .restrictedStartScreen => .qrCodeLoginScreen]) { [weak self] context in
            self?.showQRCodeLoginScreen(fromState: context.fromState)
        }
        stateMachine.addRoutes(event: .cancelledLoginWithQR(previousState: .startScreen), transitions: [.qrCodeLoginScreen => .startScreen])
        stateMachine.addRoutes(event: .cancelledLoginWithQR(previousState: .restrictedStartScreen), transitions: [.qrCodeLoginScreen => .restrictedStartScreen])
        
        // Manual Authentication
        
        stateMachine.addRoutes(event: .confirmServer(.login), transitions: [.startScreen => .serverConfirmationScreen]) { [weak self] _ in
            self?.showServerConfirmationScreen(authenticationFlow: .login)
        }
        stateMachine.addRoutes(event: .confirmServer(.register), transitions: [.startScreen => .serverConfirmationScreen]) { [weak self] _ in
            self?.showServerConfirmationScreen(authenticationFlow: .register)
        }
        stateMachine.addRoutes(event: .cancelledServerConfirmation, transitions: [.serverConfirmationScreen => .startScreen])
        
        stateMachine.addRoutes(event: .changeServer(.login), transitions: [.serverConfirmationScreen => .serverSelectionScreen]) { [weak self] _ in
            self?.showServerSelectionScreen(authenticationFlow: .login)
        }
        stateMachine.addRoutes(event: .changeServer(.register), transitions: [.serverConfirmationScreen => .serverSelectionScreen]) { [weak self] _ in
            self?.showServerSelectionScreen(authenticationFlow: .register)
        }
        stateMachine.addRoutes(event: .dismissedServerSelection, transitions: [.serverSelectionScreen => .serverConfirmationScreen])
        
        stateMachine.addRoutes(event: .continueWithOIDC, transitions: [.serverConfirmationScreen => .oidcAuthentication,
                                                                       .restrictedStartScreen => .oidcAuthentication]) { [weak self] context in
            guard let (oidcData, window) = context.userInfo as? (OIDCAuthorizationDataProxy, UIWindow) else {
                fatalError("Missing the OIDC data and presentation anchor.")
            }
            self?.showOIDCAuthentication(oidcData: oidcData, presentationAnchor: window, fromState: context.fromState)
        }
        stateMachine.addRoutes(event: .cancelledOIDCAuthentication(previousState: .serverConfirmationScreen), transitions: [.oidcAuthentication => .serverConfirmationScreen])
        stateMachine.addRoutes(event: .cancelledOIDCAuthentication(previousState: .restrictedStartScreen), transitions: [.oidcAuthentication => .restrictedStartScreen])
        
        stateMachine.addRoutes(event: .continueWithPassword, transitions: [.serverConfirmationScreen => .loginScreen,
                                                                           .restrictedStartScreen => .loginScreen]) { [weak self] context in
            let loginHint = context.userInfo as? String
            self?.showLoginScreen(loginHint: loginHint, fromState: context.fromState)
        }
        stateMachine.addRoutes(event: .cancelledPasswordLogin(previousState: .serverConfirmationScreen), transitions: [.loginScreen => .serverConfirmationScreen])
        stateMachine.addRoutes(event: .cancelledPasswordLogin(previousState: .restrictedStartScreen), transitions: [.loginScreen => .restrictedStartScreen])
        
        // Bug Report
        
        stateMachine.addRoutes(event: .reportProblem, transitions: [.startScreen => .bugReportFlow,
                                                                    .restrictedStartScreen => .bugReportFlow]) { [weak self] context in
            self?.startBugReportFlow(fromState: context.fromState)
        }
        stateMachine.addRoutes(event: .bugReportFlowComplete(previousState: .startScreen), transitions: [.bugReportFlow => .startScreen])
        stateMachine.addRoutes(event: .bugReportFlowComplete(previousState: .restrictedStartScreen), transitions: [.bugReportFlow => .restrictedStartScreen])
        
        // Completion
        
        stateMachine.addRoutes(event: .signedIn, transitions: [.qrCodeLoginScreen => .complete,
                                                               .oidcAuthentication => .complete,
                                                               .loginScreen => .complete]) { [weak self] context in
            guard let userSession = context.userInfo as? UserSessionProtocol else { fatalError("The user session wasn't included in the context") }
            self?.userHasSignedIn(userSession: userSession)
        }
        
        // Unhandled
        
        stateMachine.addErrorHandler { context in
            switch (context.fromState, context.toState) {
            case (.complete, .complete):
                break // Ignore all events triggered by
            default:
                fatalError("Unexpected transition: \(context)")
            }
        }
    }
    
    private func showStartScreen(fromState: State, applying provisioningParameters: AccountProvisioningParameters? = nil) {
        let parameters = AuthenticationStartScreenParameters(authenticationService: authenticationService,
                                                             provisioningParameters: provisioningParameters,
                                                             isBugReportServiceEnabled: bugReportService.isEnabled,
                                                             appSettings: appSettings,
                                                             userIndicatorController: userIndicatorController)
        let coordinator = AuthenticationStartScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .loginWithQR:
                    stateMachine.tryEvent(.loginWithQR)
                case .login:
                    stateMachine.tryEvent(.confirmServer(.login))
                case .register:
                    stateMachine.tryEvent(.confirmServer(.register))
                case .reportProblem:
                    stateMachine.tryEvent(.reportProblem)
                    
                case .loginDirectlyWithOIDC(let oidcData, let window):
                    stateMachine.tryEvent(.continueWithOIDC, userInfo: (oidcData, window))
                case .loginDirectlyWithPassword(let loginHint):
                    stateMachine.tryEvent(.continueWithPassword, userInfo: loginHint)
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.setRootCoordinator(coordinator)
        
        if fromState == .initial {
            navigationRootCoordinator.setRootCoordinator(navigationStackCoordinator)
        }
    }
    
    // MARK: - QR Code
    
    private func showQRCodeLoginScreen(fromState: State) {
        let coordinator = QRCodeLoginScreenCoordinator(parameters: .init(qrCodeLoginService: qrCodeLoginService,
                                                                         canSignInManually: fromState != .restrictedStartScreen,
                                                                         orientationManager: appMediator.windowManager,
                                                                         appMediator: appMediator))
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else {
                return
            }
            switch action {
            case .signInManually:
                navigationStackCoordinator.setSheetCoordinator(nil)
                stateMachine.tryEvent(.cancelledLoginWithQR(previousState: fromState))
                stateMachine.tryEvent(.confirmServer(.login))
            case .cancel:
                navigationStackCoordinator.setSheetCoordinator(nil)
                stateMachine.tryEvent(.cancelledLoginWithQR(previousState: fromState))
            case .done(let userSession):
                navigationStackCoordinator.setSheetCoordinator(nil)
                // Since the qr code login flow includes verification
                appSettings.hasRunIdentityConfirmationOnboarding = true
                DispatchQueue.main.async {
                    self.stateMachine.tryEvent(.signedIn, userInfo: userSession)
                }
            }
        }
        .store(in: &cancellables)
        navigationStackCoordinator.setSheetCoordinator(coordinator) // Don't use the callback (interactive dismiss disabled), choose the event with the action.
    }
    
    // MARK: - Manual Authentication
    
    private func showServerConfirmationScreen(authenticationFlow: AuthenticationFlow) {
        // Reset the service back to the default homeserver before continuing. This ensures
        // we check that registration is supported if it was previously configured for login.
        authenticationService.reset()
        
        let parameters = ServerConfirmationScreenCoordinatorParameters(authenticationService: authenticationService,
                                                                       authenticationFlow: authenticationFlow,
                                                                       userIndicatorController: userIndicatorController)
        let coordinator = ServerConfirmationScreenCoordinator(parameters: parameters)
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .continueWithOIDC(let oidcData, let window):
                stateMachine.tryEvent(.continueWithOIDC, userInfo: (oidcData, window))
            case .continueWithPassword:
                stateMachine.tryEvent(.continueWithPassword)
            case .changeServer:
                stateMachine.tryEvent(.changeServer(authenticationFlow))
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator) { [weak self] in
            self?.stateMachine.tryEvent(.cancelledServerConfirmation)
        }
    }
    
    private func showServerSelectionScreen(authenticationFlow: AuthenticationFlow) {
        let navigationCoordinator = NavigationStackCoordinator()
        
        let parameters = ServerSelectionScreenCoordinatorParameters(authenticationService: authenticationService,
                                                                    authenticationFlow: authenticationFlow,
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
        navigationStackCoordinator.setSheetCoordinator(navigationCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissedServerSelection)
        }
    }
    
    private func showOIDCAuthentication(oidcData: OIDCAuthorizationDataProxy, presentationAnchor: UIWindow, fromState: State) {
        let presenter = OIDCAuthenticationPresenter(authenticationService: authenticationService,
                                                    oidcRedirectURL: appSettings.oidcRedirectURL,
                                                    presentationAnchor: presentationAnchor,
                                                    userIndicatorController: userIndicatorController)
        oidcPresenter = presenter
        
        Task {
            switch await presenter.authenticate(using: oidcData) {
            case .success(let userSession):
                stateMachine.tryEvent(.signedIn, userInfo: userSession)
            case .failure:
                stateMachine.tryEvent(.cancelledOIDCAuthentication(previousState: fromState))
                // Nothing more to do, the alerts are handled by the presenter.
            }
            oidcPresenter = nil
        }
    }
    
    private func showLoginScreen(loginHint: String?, fromState: State) {
        let parameters = LoginScreenCoordinatorParameters(authenticationService: authenticationService,
                                                          loginHint: loginHint,
                                                          userIndicatorController: userIndicatorController,
                                                          analytics: analytics)
        let coordinator = LoginScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }

                switch action {
                case .signedIn(let userSession):
                    stateMachine.tryEvent(.signedIn, userInfo: userSession)
                case .configuredForOIDC:
                    // Pop back to the confirmation screen for OIDC login to continue.
                    navigationStackCoordinator.pop(animated: false)
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator) { [weak self] in
            self?.stateMachine.tryEvent(.cancelledPasswordLogin(previousState: fromState))
        }
    }
    
    // MARK: - Bug Report
    
    private func startBugReportFlow(fromState: State) {
        let coordinator = BugReportFlowCoordinator(parameters: .init(presentationMode: .sheet(navigationStackCoordinator),
                                                                     userIndicatorController: userIndicatorController,
                                                                     bugReportService: bugReportService,
                                                                     userSession: nil))
        coordinator.actionsPublisher.sink { [weak self] action in
            switch action {
            case .complete:
                self?.stateMachine.tryEvent(.bugReportFlowComplete(previousState: fromState))
            }
        }
        .store(in: &cancellables)
        
        bugReportFlowCoordinator = coordinator
        coordinator.start()
    }
    
    // MARK: - Completion
        
    private func userHasSignedIn(userSession: UserSessionProtocol) {
        delegate?.authenticationFlowCoordinator(didLoginWithSession: userSession)
    }
}
