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

import Combine
import MatrixRustSDK
import UIKit

struct ServiceLocator {
    fileprivate static var serviceLocator: ServiceLocator?
    static var shared: ServiceLocator {
        guard let serviceLocator = serviceLocator else {
            fatalError("The service locator should be setup at this point")
        }
        
        return serviceLocator
    }
    
    let userIndicatorPresenter: UserIndicatorTypePresenter
}

class AppCoordinator: Coordinator, UserSessionFlowCoordinatorDelegate {
    private let window: UIWindow
    
    private let stateMachine: AppCoordinatorStateMachine
    
    private let mainNavigationController: UINavigationController
    private let splashViewController: UIViewController
    
    private let navigationRouter: NavigationRouter
    
    private let userSessionStore: UserSessionStoreProtocol
    
    private var userSession: UserSessionProtocol! {
        didSet {
            deobserveUserSessionChanges()
            if let userSession = userSession, !userSession.isSoftLogout {
                observeUserSessionChanges()
            }
        }
    }
    
    private var userSessionFlowCoordinator: UserSessionFlowCoordinator?
    
    private let bugReportService: BugReportServiceProtocol
    private let backgroundTaskService: BackgroundTaskServiceProtocol

    private var loadingIndicator: UserIndicator?
    private var statusIndicator: UserIndicator?

    private var cancellables = Set<AnyCancellable>()
    
    var childCoordinators: [Coordinator] = []
    
    init() {
        stateMachine = AppCoordinatorStateMachine()
        
        bugReportService = BugReportService(withBaseURL: BuildSettings.bugReportServiceBaseURL, sentryURL: BuildSettings.bugReportSentryURL)

        splashViewController = SplashViewController()
        
        mainNavigationController = ElementNavigationController(rootViewController: splashViewController)
        mainNavigationController.navigationBar.prefersLargeTitles = true
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = mainNavigationController
        window.tintColor = .element.accent
        
        navigationRouter = NavigationRouter(navigationController: mainNavigationController)
        
        ServiceLocator.serviceLocator = ServiceLocator(userIndicatorPresenter: UserIndicatorTypePresenter(presentingViewController: mainNavigationController))
        
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("Should have a valid bundle identifier at this point")
        }

        backgroundTaskService = UIKitBackgroundTaskService(withApplication: UIApplication.shared)
        
        userSessionStore = UserSessionStore(bundleIdentifier: bundleIdentifier,
                                            backgroundTaskService: backgroundTaskService)
        
        setupStateMachine()
        
        setupLogging()
        
        // Benchmark.trackingEnabled = true
    }
    
    func start() {
        window.makeKeyAndVisible()
        stateMachine.processEvent(userSessionStore.hasSessions ? .startWithExistingSession : .startWithAuthentication)
    }

    func stop() {
        hideLoadingIndicator()
    }
    
    // MARK: - UserSessionFlowCoordinatorDelegate
    
    func userSessionFlowCoordinatorDidRequestSignOut(_ userSessionFlowCoordinator: UserSessionFlowCoordinator) {
        stateMachine.processEvent(.signOut)
    }

    // MARK: - Private
    
    private func setupLogging() {
        let loggerConfiguration = MXLogConfiguration()
        
        #if DEBUG
        // This exposes the full Rust side tracing subscriber filter for more flexibility.
        // We can filter by level, crate and even file. See more details here:
        // https://docs.rs/tracing-subscriber/0.2.7/tracing_subscriber/filter/struct.EnvFilter.html#examples
        setupTracing(configuration: "warn,hyper=warn,sled=warn,matrix_sdk_sled=warn")
        
        loggerConfiguration.logLevel = .debug
        #else
        setupTracing(configuration: "info,hyper=warn,sled=warn,matrix_sdk_sled=warn")
        loggerConfiguration.logLevel = .info
        #endif
        
        // Avoid redirecting NSLogs to files if we are attached to a debugger.
        if isatty(STDERR_FILENO) == 0 {
            loggerConfiguration.redirectLogsToFiles = true
        }
      
        MXLog.configure(loggerConfiguration)
    }
    
    // swiftlint:disable:next cyclomatic_complexity
    private func setupStateMachine() {
        stateMachine.addTransitionHandler { [weak self] context in
            guard let self = self else { return }
            
            switch (context.fromState, context.event, context.toState) {
            case (.initial, .startWithAuthentication, .signedOut):
                self.startAuthentication()
            case (.signedOut, .succeededSigningIn, .signedIn):
                self.setupUserSession()
            case (.initial, .startWithExistingSession, .restoringSession):
                self.showLoadingIndicator()
                self.restoreUserSession()
            case (.restoringSession, .failedRestoringSession, .signedOut):
                self.hideLoadingIndicator()
                self.showLoginErrorToast()
            case (.restoringSession, .succeededRestoringSession, .signedIn):
                self.hideLoadingIndicator()
                self.setupUserSession()
            case (_, .signOut, .signingOut):
                self.showLoadingIndicator()
                self.tearDownUserSession()
            case (.signingOut, .completedSigningOut, .signedOut):
                self.presentSplashScreen()
                self.hideLoadingIndicator()
            case (_, .remoteSignOut(let isSoft), .remoteSigningOut):
                self.showLoadingIndicator()
                self.tearDownUserSession(isSoftLogout: isSoft)
            case (.remoteSigningOut(let isSoft), .completedSigningOut, .signedOut):
                self.presentSplashScreen(isSoftLogout: isSoft)
                self.hideLoadingIndicator()
            default:
                fatalError("Unknown transition: \(context)")
            }
        }
        
        stateMachine.addErrorHandler { context in
            fatalError("Failed transition with context: \(context)")
        }
    }
    
    private func restoreUserSession() {
        Task {
            switch await userSessionStore.restoreUserSession() {
            case .success(let userSession):
                self.userSession = userSession
                if userSession.isSoftLogout {
                    stateMachine.processEvent(.remoteSignOut(isSoft: true))
                } else {
                    stateMachine.processEvent(.succeededRestoringSession)
                }
            case .failure:
                MXLog.error("Failed to restore an existing session.")
                stateMachine.processEvent(.failedRestoringSession)
            }
        }
    }
    
    private func startAuthentication() {
        let authenticationService = AuthenticationServiceProxy(userSessionStore: userSessionStore)
        let coordinator = AuthenticationCoordinator(authenticationService: authenticationService,
                                                    navigationRouter: navigationRouter)
        coordinator.delegate = self
        
        add(childCoordinator: coordinator)
        coordinator.start()
    }

    private func startAuthenticationSoftLogout() {
        Task {
            var displayName = ""
            if case .success(let name) = await userSession.clientProxy.loadUserDisplayName() {
                displayName = name
            }

            let credentials = SoftLogoutCredentials(userId: userSession.userID,
                                                    homeserverName: userSession.homeserver,
                                                    userDisplayName: displayName,
                                                    deviceId: userSession.deviceId)

            let authenticationService = AuthenticationServiceProxy(userSessionStore: userSessionStore)
            _ = await authenticationService.configure(for: userSession.homeserver)
            
            let parameters = SoftLogoutCoordinatorParameters(authenticationService: authenticationService,
                                                             credentials: credentials,
                                                             keyBackupNeeded: false)
            let coordinator = SoftLogoutCoordinator(parameters: parameters)
            coordinator.callback = { result in
                switch result {
                case .signedIn(let session):
                    self.userSession = session
                    self.remove(childCoordinator: coordinator)
                    self.stateMachine.processEvent(.succeededSigningIn)
                case .clearAllData:
                    //  clear user data
                    self.userSessionStore.logout(userSession: self.userSession)
                    self.userSession = nil
                    self.remove(childCoordinator: coordinator)
                    self.startAuthentication()
                }
            }

            add(childCoordinator: coordinator)
            coordinator.start()

            navigationRouter.setRootModule(coordinator)
        }
    }
    
    private func setupUserSession() {
        let userSessionFlowCoordinator = UserSessionFlowCoordinator(userSession: userSession,
                                                                    navigationRouter: navigationRouter,
                                                                    bugReportService: bugReportService)
        userSessionFlowCoordinator.delegate = self
        userSessionFlowCoordinator.start()
        
        self.userSessionFlowCoordinator = userSessionFlowCoordinator
    }
    
    private func tearDownUserSession(isSoftLogout: Bool = false) {
        userSession.clientProxy.stopSync()
        userSessionFlowCoordinator?.stop()
        
        deobserveUserSessionChanges()
        
        if !isSoftLogout {
            Task {
                //  first log out from the server
                _ = await userSession.clientProxy.logout()
                
                //  regardless of the result, clear user data
                userSessionStore.logout(userSession: userSession)
                userSession = nil
            }
        }
        
        //  complete logging out
        stateMachine.processEvent(.completedSigningOut)
    }

    private func presentSplashScreen(isSoftLogout: Bool = false) {
        if let presentedCoordinator = childCoordinators.first {
            remove(childCoordinator: presentedCoordinator)
        }

        mainNavigationController.setViewControllers([splashViewController], animated: false)

        if isSoftLogout {
            startAuthenticationSoftLogout()
        } else {
            startAuthentication()
        }
    }
    
    private func observeUserSessionChanges() {
        userSession.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                guard let self = self else { return }
                switch callback {
                case .didReceiveAuthError(let isSoftLogout):
                    self.stateMachine.processEvent(.remoteSignOut(isSoft: isSoftLogout))
                case .updateRestoreTokenNeeded:
                    if let userSession = self.userSession {
                        _ = self.userSessionStore.refreshRestoreToken(for: userSession)
                    }
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    private func deobserveUserSessionChanges() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
    // MARK: Toasts and loading indicators
    
    private func showLoadingIndicator() {
        loadingIndicator = ServiceLocator.shared.userIndicatorPresenter.present(.loading(label: ElementL10n.loading, isInteractionBlocking: true))
    }
    
    private func hideLoadingIndicator() {
        loadingIndicator = nil
    }
    
    private func showLoginErrorToast() {
        statusIndicator = ServiceLocator.shared.userIndicatorPresenter.present(.error(label: "Failed logging in"))
    }
}

// MARK: - AuthenticationCoordinatorDelegate

extension AppCoordinator: AuthenticationCoordinatorDelegate {
    func authenticationCoordinator(_ authenticationCoordinator: AuthenticationCoordinator, didLoginWithSession userSession: UserSessionProtocol) {
        self.userSession = userSession
        remove(childCoordinator: authenticationCoordinator)
        stateMachine.processEvent(.succeededSigningIn)
    }
}
