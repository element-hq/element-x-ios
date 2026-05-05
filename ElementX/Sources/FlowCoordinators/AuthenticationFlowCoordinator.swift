//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
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
    private let appHooks: AppHooks
    private let analytics: AnalyticsService
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    enum State: StateType {
        /// The state machine hasn't started.
        case initial
        
        /// The initial screen shown when you first launch the app.
        case startScreen
        
        /// The screen used for the whole QR Code flow.
        case qrCodeLoginScreen
        
        /// The screen to continue authentication with the current server.
        case serverConfirmationScreen
        /// The screen to choose a different server.
        case serverSelectionScreen
        /// The screen to login with a password.
        case loginScreen
        
        /// The screen to report an error.
        case bugReportFlow
        /// The screen to toggle feature flags.
        case developerOptions
        
        /// The flow is complete.
        case complete
    }
    
    enum Event: EventType {
        /// The flow is being started.
        case start
        
        /// Modify the flow using the provisioning parameters in the `userInfo`.
        case applyProvisioningParameters
        
        /// The user would like to login with a QR code.
        case loginWithQR
        /// Show the server confirmation screen.
        case confirmServer(AuthenticationFlow)
        
        /// The QR login flow was aborted.
        case cancelledLoginWithQR
        /// The user aborted manual login.
        case cancelledServerConfirmation
        
        /// The user would like to enter a different server.
        case changeServer(AuthenticationFlow)
        /// The user is no longer selecting a server.
        case dismissedServerSelection
        
        /// Show the screen to login with password (with the optional login hint in the `userInfo`).
        case continueWithPassword
        /// The password login was aborted.
        case cancelledPasswordLogin(previousState: State)
        
        /// The user encountered a problem.
        case reportProblem
        /// The user has finished reporting a problem (or viewing the logs).
        case bugReportFlowComplete
        
        /// The user wants to toggle a feature flag.
        case developerOptions
        /// The user finished toggling feature flags.
        case dismissedDeveloperOptions
        
        /// The user has successfully signed in. The new session can be found in the `userInfo`.
        case signedIn
    }
    
    private let stateMachine: StateMachine<State, Event>
    private var cancellables = Set<AnyCancellable>()
    
    private var oAuthPresenter: OAuthAuthenticationPresenter?
    
    // periphery:ignore - retaining purpose
    private var bugReportFlowCoordinator: BugReportFlowCoordinator?
    
    weak var delegate: AuthenticationFlowCoordinatorDelegate?
    
    init(authenticationService: AuthenticationServiceProtocol,
         bugReportService: BugReportServiceProtocol,
         navigationRootCoordinator: NavigationRootCoordinator,
         appMediator: AppMediatorProtocol,
         appSettings: AppSettings,
         appHooks: AppHooks,
         analytics: AnalyticsService,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.authenticationService = authenticationService
        self.bugReportService = bugReportService
        self.navigationRootCoordinator = navigationRootCoordinator
        self.appMediator = appMediator
        self.appSettings = appSettings
        self.appHooks = appHooks
        self.analytics = analytics
        self.userIndicatorController = userIndicatorController
        
        navigationStackCoordinator = NavigationStackCoordinator()
        
        stateMachine = .init(state: .initial)
        configureStateMachine()
    }
    
    func start(animated: Bool) {
        stateMachine.tryEvent(.start)
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        MXLog.info("Handling app route: \(appRoute)")
        
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
        oAuthPresenter?.cancel() // Handle ongoing OAuth authentication first.
        
        switch stateMachine.state {
        case .initial, .startScreen:
            break
        case .qrCodeLoginScreen:
            navigationStackCoordinator.setSheetCoordinator(nil)
            stateMachine.tryEvent(.cancelledLoginWithQR) // Needs to be handled manually.
        case .serverConfirmationScreen:
            navigationStackCoordinator.popToRoot(animated: animated)
        case .serverSelectionScreen:
            navigationStackCoordinator.setSheetCoordinator(nil)
            navigationStackCoordinator.popToRoot(animated: animated)
        case .loginScreen:
            navigationStackCoordinator.popToRoot(animated: animated)
        case .bugReportFlow:
            navigationStackCoordinator.setSheetCoordinator(nil)
        case .developerOptions:
            navigationStackCoordinator.setSheetCoordinator(nil)
        case .complete:
            fatalError()
        }
    }
    
    func handleOAuthCallbackURL(_ url: URL) {
        guard let oAuthPresenter else {
            MXLog.error("Failed to find an OAuth request in progress.")
            return
        }
        
        oAuthPresenter.handleUniversalLinkCallback(url)
    }
    
    // MARK: - Setup
    
    private func configureStateMachine() {
        stateMachine.addRoutes(event: .start, transitions: [.initial => .startScreen]) { [weak self] _ in
            self?.showStartScreen(fromState: .initial)
        }
        
        stateMachine.addRoutes(event: .applyProvisioningParameters, transitions: [.initial => .startScreen,
                                                                                  .startScreen => .startScreen]) { [weak self] context in
            guard let provisioningParameters = context.userInfo as? AccountProvisioningParameters else { fatalError("The authentication configuration is missing.") }
            self?.showStartScreen(fromState: context.fromState, applying: provisioningParameters)
        }
        
        // QR Code
        
        stateMachine.addRoutes(event: .loginWithQR, transitions: [.startScreen => .qrCodeLoginScreen]) { [weak self] _ in
            self?.showQRCodeLoginScreen()
        }
        stateMachine.addRoutes(event: .cancelledLoginWithQR, transitions: [.qrCodeLoginScreen => .startScreen])
        
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
        
        stateMachine.addRoutes(event: .continueWithPassword, transitions: [.serverConfirmationScreen => .loginScreen,
                                                                           .startScreen => .loginScreen]) { [weak self] context in
            let loginHint = context.userInfo as? String
            self?.showLoginScreen(loginHint: loginHint, fromState: context.fromState)
        }
        stateMachine.addRoutes(event: .cancelledPasswordLogin(previousState: .serverConfirmationScreen), transitions: [.loginScreen => .serverConfirmationScreen])
        stateMachine.addRoutes(event: .cancelledPasswordLogin(previousState: .startScreen), transitions: [.loginScreen => .startScreen])
        
        // Bug Report
        
        stateMachine.addRoutes(event: .reportProblem, transitions: [.startScreen => .bugReportFlow]) { [weak self] _ in
            self?.startBugReportFlow()
        }
        stateMachine.addRoutes(event: .bugReportFlowComplete, transitions: [.bugReportFlow => .startScreen])
        
        // Developer Options
        
        stateMachine.addRoutes(event: .developerOptions, transitions: [.startScreen => .developerOptions]) { [weak self] _ in
            self?.showDeveloperOptionsScreen()
        }
        stateMachine.addRoutes(event: .dismissedDeveloperOptions, transitions: [.developerOptions => .startScreen])
        
        // Completion
        
        stateMachine.addRoutes(event: .signedIn, transitions: [.qrCodeLoginScreen => .complete,
                                                               .serverConfirmationScreen => .complete, // OAuth authentication
                                                               .startScreen => .complete, // Direct OAuth authentication
                                                               .loginScreen => .complete]) { [weak self] context in
            guard let userSession = context.userInfo as? UserSessionProtocol else { fatalError("The user session wasn't included in the context") }
            self?.userHasSignedIn(userSession: userSession)
        }
        
        // Logging
        
        stateMachine.addAnyHandler(.any => .any) { context in
            MXLog.info("Transitioning from `\(context.fromState)` to `\(context.toState)` with event `\(String(describing: context.event))`.")
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
        let mediaProvider = authenticationService.classicAppAccount.map { account in
            MediaProvider(mediaLoader: ClassicAppMediaLoader(classicAppAccount: account),
                          imageCache: .onlyInMemory,
                          homeserverReachabilityPublisher: appMediator.networkMonitor.reachabilityPublisher) // Close enough approximation
        }
        
        let parameters = AuthenticationStartScreenParameters(authenticationService: authenticationService,
                                                             provisioningParameters: provisioningParameters,
                                                             isBugReportServiceEnabled: bugReportService.isEnabled,
                                                             appMediator: appMediator,
                                                             appSettings: appSettings,
                                                             mediaProvider: mediaProvider,
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
                    
                case .loginDirectlyWithOAuth(let oAuthData, let window):
                    showOAuthAuthentication(oAuthData: oAuthData, presentationAnchor: window)
                case .loginDirectlyWithPassword(let loginHint):
                    stateMachine.tryEvent(.continueWithPassword, userInfo: loginHint)
                
                case .reportProblem:
                    stateMachine.tryEvent(.reportProblem)
                case .developerOptions:
                    stateMachine.tryEvent(.developerOptions)
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.setRootCoordinator(coordinator)
        
        if fromState == .initial {
            navigationRootCoordinator.setRootCoordinator(navigationStackCoordinator)
        }
    }
    
    // MARK: - QR Code
    
    private func showQRCodeLoginScreen() {
        let stackCoordinator = NavigationStackCoordinator()
        let coordinator = QRCodeLoginScreenCoordinator(parameters: .init(mode: .login(authenticationService),
                                                                         canSignInManually: appSettings.allowOtherAccountProviders, // No need to worry about provisioning links as we hide QR login.
                                                                         orientationManager: appMediator.windowManager,
                                                                         appMediator: appMediator))
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else {
                return
            }
            switch action {
            case .startOver:
                fatalError("QR code login shouldn't request to start over as it's handled within the screen.")
            case .requestOAuthAuthorisation, .linkedDevice:
                fatalError("QR code login shouldn't request an OAuth flow or link a device.")
            case .signInManually:
                navigationStackCoordinator.setSheetCoordinator(nil)
                stateMachine.tryEvent(.cancelledLoginWithQR)
                stateMachine.tryEvent(.confirmServer(.login))
            case .signedIn(let userSession):
                navigationStackCoordinator.setSheetCoordinator(nil)
                DispatchQueue.main.async {
                    self.stateMachine.tryEvent(.signedIn, userInfo: userSession)
                }
            case .cancel:
                navigationStackCoordinator.setSheetCoordinator(nil)
                stateMachine.tryEvent(.cancelledLoginWithQR)
            }
        }
        .store(in: &cancellables)
        
        stackCoordinator.setRootCoordinator(coordinator)
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) // Don't use the callback (interactive dismiss disabled), choose the event with the action.
    }
    
    // MARK: - Manual Authentication
    
    private func showServerConfirmationScreen(authenticationFlow: AuthenticationFlow) {
        // Reset the service back to the default homeserver before continuing. This ensures
        // we check that registration is supported if it was previously configured for login.
        authenticationService.reset()
        
        let parameters = ServerConfirmationScreenCoordinatorParameters(authenticationService: authenticationService,
                                                                       authenticationFlow: authenticationFlow,
                                                                       appSettings: appSettings,
                                                                       userIndicatorController: userIndicatorController)
        let coordinator = ServerConfirmationScreenCoordinator(parameters: parameters)
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .continueWithOAuth(let oAuthData, let window):
                showOAuthAuthentication(oAuthData: oAuthData, presentationAnchor: window)
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
                                                                    appSettings: appSettings,
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
    
    /// **Note:** We have intentionally excluded this presentation from the state machine as it doesn't mutate our navigation stack and there
    /// isn't a robust way to detect why the user returned to the app when the MAS URL directly opens an external app for authentication without
    /// presenting a web authentication session.
    private func showOAuthAuthentication(oAuthData: OAuthAuthorizationDataProxy, presentationAnchor: UIWindow) {
        let presenter = OAuthAuthenticationPresenter(authenticationService: authenticationService,
                                                     redirectURL: appSettings.oAuthRedirectURL,
                                                     presentationAnchor: presentationAnchor,
                                                     appMediator: appMediator,
                                                     userIndicatorController: userIndicatorController)
        oAuthPresenter = presenter
        
        Task {
            switch await presenter.authenticate(using: oAuthData) {
            case .success(let userSession):
                stateMachine.tryEvent(.signedIn, userInfo: userSession)
            case .failure:
                break // Nothing to do, any alerts will be handled by the presenter.
            }
            oAuthPresenter = nil
        }
    }
    
    private func showLoginScreen(loginHint: String?, fromState: State) {
        let parameters = LoginScreenCoordinatorParameters(authenticationService: authenticationService,
                                                          loginHint: loginHint,
                                                          userIndicatorController: userIndicatorController,
                                                          appSettings: appSettings,
                                                          analytics: analytics)
        let coordinator = LoginScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }

                switch action {
                case .signedIn(let userSession):
                    stateMachine.tryEvent(.signedIn, userInfo: userSession)
                case .configuredForOAuth:
                    // Pop back to the confirmation screen for OAuth login to continue.
                    navigationStackCoordinator.pop(animated: false)
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator) { [weak self] in
            self?.stateMachine.tryEvent(.cancelledPasswordLogin(previousState: fromState))
        }
    }
    
    // MARK: - Bug Report
    
    private func startBugReportFlow() {
        let coordinator = BugReportFlowCoordinator(parameters: .init(presentationMode: .sheet(navigationStackCoordinator),
                                                                     userIndicatorController: userIndicatorController,
                                                                     bugReportService: bugReportService,
                                                                     userSession: nil))
        coordinator.actionsPublisher.sink { [weak self] action in
            switch action {
            case .complete:
                self?.stateMachine.tryEvent(.bugReportFlowComplete)
            }
        }
        .store(in: &cancellables)
        
        bugReportFlowCoordinator = coordinator
        coordinator.start()
    }
    
    // MARK: - Developer Options
    
    private func showDeveloperOptionsScreen() {
        let stackCoordinator = NavigationStackCoordinator()
        let coordinator = DeveloperOptionsScreenCoordinator(appSettings: appSettings,
                                                            appHooks: appHooks,
                                                            clientProxy: nil)
        coordinator.actions
            .sink { action in
                switch action {
                case .clearCache:
                    break // Not sent when clientProxy == nil
                }
            }
            .store(in: &cancellables)
        
        stackCoordinator.setRootCoordinator(coordinator)
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissedDeveloperOptions)
        }
    }
    
    // MARK: - Completion
        
    private func userHasSignedIn(userSession: UserSessionProtocol) {
        delegate?.authenticationFlowCoordinator(didLoginWithSession: userSession)
    }
}
