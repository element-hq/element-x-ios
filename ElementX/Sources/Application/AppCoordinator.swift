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
import SwiftUI

struct ServiceLocator {
    fileprivate static var serviceLocator: ServiceLocator?
    static var shared: ServiceLocator {
        guard let serviceLocator else {
            fatalError("The service locator should be setup at this point")
        }
        
        return serviceLocator
    }
    
    let userNotificationController: UserNotificationControllerProtocol
}

class AppCoordinator: AppCoordinatorProtocol {
    private let stateMachine: AppCoordinatorStateMachine
    private let navigationController: NavigationController
    private let userSessionStore: UserSessionStoreProtocol
    
    private var userSession: UserSessionProtocol! {
        didSet {
            deobserveUserSessionChanges()
            if let userSession, !userSession.isSoftLogout {
                configureNotificationManager()
                observeUserSessionChanges()
            }
        }
    }
    
    private var userSessionFlowCoordinator: UserSessionFlowCoordinator?
    private var authenticationCoordinator: AuthenticationCoordinator?
    
    private let bugReportService: BugReportServiceProtocol
    private let backgroundTaskService: BackgroundTaskServiceProtocol

    private var cancellables = Set<AnyCancellable>()
    private(set) var notificationManager: NotificationManagerProtocol?

    init() {
        navigationController = NavigationController()
        stateMachine = AppCoordinatorStateMachine()
        
        bugReportService = BugReportService(withBaseURL: BuildSettings.bugReportServiceBaseURL, sentryURL: BuildSettings.bugReportSentryURL)

        navigationController.setRootCoordinator(SplashScreenCoordinator())

        ServiceLocator.serviceLocator = ServiceLocator(userNotificationController: UserNotificationController(rootCoordinator: navigationController))

        backgroundTaskService = UIKitBackgroundTaskService(withApplication: UIApplication.shared)

        userSessionStore = UserSessionStore(backgroundTaskService: backgroundTaskService)
        
        setupStateMachine()
        
        setupLogging()
        
        Bundle.elementFallbackLanguage = "en"
        
        // Benchmark.trackingEnabled = true
    }
    
    func start() {
        stateMachine.processEvent(userSessionStore.hasSessions ? .startWithExistingSession : .startWithAuthentication)
    }

    func stop() {
        hideLoadingIndicator()
    }
    
    func toPresentable() -> AnyView {
        ServiceLocator.shared.userNotificationController.toPresentable()
    }
        
    // MARK: - Private
    
    private func setupLogging() {
        let loggerConfiguration = MXLogConfiguration()
        loggerConfiguration.maxLogFilesCount = 10
        
        #if DEBUG
        // This exposes the full Rust side tracing subscriber filter for more flexibility.
        // We can filter by level, crate and even file. See more details here:
        // https://docs.rs/tracing-subscriber/0.2.7/tracing_subscriber/filter/struct.EnvFilter.html#examples
        setupTracing(filter: "warn,hyper=warn,sled=warn,matrix_sdk_sled=warn")
        
        loggerConfiguration.logLevel = .debug
        #else
        setupTracing(filter: "info,hyper=warn,sled=warn,matrix_sdk_sled=warn")
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
            guard let self else { return }
            
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
        authenticationCoordinator = AuthenticationCoordinator(authenticationService: authenticationService,
                                                              navigationController: navigationController)
        authenticationCoordinator?.delegate = self
        
        authenticationCoordinator?.start()
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
                    self.stateMachine.processEvent(.succeededSigningIn)
                case .clearAllData:
                    //  clear user data
                    self.userSessionStore.logout(userSession: self.userSession)
                    self.userSession = nil
                    self.startAuthentication()
                }
            }
            
            navigationController.setRootCoordinator(coordinator)
        }
    }
    
    private func setupUserSession() {
        let userSessionFlowCoordinator = UserSessionFlowCoordinator(userSession: userSession,
                                                                    navigationController: navigationController,
                                                                    bugReportService: bugReportService)
        
        userSessionFlowCoordinator.callback = { [weak self] action in
            switch action {
            case .signOut:
                self?.stateMachine.processEvent(.signOut)
            }
        }
        
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
                notificationManager?.delegate = nil
                notificationManager = nil
            }
        }
        
        //  complete logging out
        stateMachine.processEvent(.completedSigningOut)
    }

    private func presentSplashScreen(isSoftLogout: Bool = false) {
        navigationController.setRootCoordinator(SplashScreenCoordinator())
        
        if isSoftLogout {
            startAuthenticationSoftLogout()
        } else {
            startAuthentication()
        }
    }

    private func configureNotificationManager() {
        guard BuildSettings.enableNotifications else {
            return
        }
        guard notificationManager == nil else {
            return
        }

        let manager = NotificationManager(clientProxy: userSession.clientProxy)
        if manager.isAvailable {
            manager.delegate = self
            notificationManager = manager
            manager.start()

            if let appDelegate = AppDelegate.shared {
                appDelegate.callbacks
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] callback in
                        switch callback {
                        case .registeredNotifications(let deviceToken):
                            self?.notificationManager?.register(with: deviceToken)
                        case .failedToRegisteredNotifications(let error):
                            self?.notificationManager?.registrationFailed(with: error)
                        }
                    }
                    .store(in: &cancellables)
            } else {
                MXLog.debug("Couldn't register to AppDelegate callbacks")
            }
        }
    }
    
    private func observeUserSessionChanges() {
        userSession.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                guard let self else { return }
                switch callback {
                case .didReceiveAuthError(let isSoftLogout):
                    self.stateMachine.processEvent(.remoteSignOut(isSoft: isSoftLogout))
                case .updateRestoreTokenNeeded:
                    if let userSession = self.userSession {
                        _ = self.userSessionStore.refreshRestorationToken(for: userSession)
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
    
    static let loadingIndicatorIdentifier = "AppCoordinatorLoading"
    
    private func showLoadingIndicator() {
        ServiceLocator.shared.userNotificationController.submitNotification(UserNotification(id: Self.loadingIndicatorIdentifier,
                                                                                             type: .modal,
                                                                                             title: ElementL10n.loading,
                                                                                             persistent: true))
    }
    
    private func hideLoadingIndicator() {
        ServiceLocator.shared.userNotificationController.retractNotificationWithId(Self.loadingIndicatorIdentifier)
    }
    
    private func showLoginErrorToast() {
        ServiceLocator.shared.userNotificationController.submitNotification(UserNotification(title: "Failed logging in"))
    }
}

// MARK: - AuthenticationCoordinatorDelegate

extension AppCoordinator: AuthenticationCoordinatorDelegate {
    func authenticationCoordinator(_ authenticationCoordinator: AuthenticationCoordinator, didLoginWithSession userSession: UserSessionProtocol) {
        self.userSession = userSession
        stateMachine.processEvent(.succeededSigningIn)
    }
}

// MARK: - NotificationManagerDelegate

extension AppCoordinator: NotificationManagerDelegate {
    func authorizationStatusUpdated(_ service: NotificationManagerProtocol, granted: Bool) {
        if granted {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    func shouldDisplayInAppNotification(_ service: NotificationManagerProtocol, content: UNNotificationContent) -> Bool {
        guard let roomId = content.userInfo[NotificationConstants.UserInfoKey.roomIdentifier] as? String else {
            return true
        }
        guard let userSessionFlowCoordinator else {
            // there is not a user session yet
            return false
        }
        return !userSessionFlowCoordinator.isDisplayingRoomScreen(withRoomId: roomId)
    }

    func notificationTapped(_ service: NotificationManagerProtocol, content: UNNotificationContent) async {
        MXLog.debug("[AppCoordinator] tappedNotification")

        guard let roomId = content.userInfo[NotificationConstants.UserInfoKey.roomIdentifier] as? String else {
            return
        }

        userSessionFlowCoordinator?.tryDisplayingRoomScreen(roomId: roomId)
    }

    func handleInlineReply(_ service: NotificationManagerProtocol, content: UNNotificationContent, replyText: String) async {
        MXLog.debug("[AppCoordinator] handle notification reply")

        guard let roomId = content.userInfo[NotificationConstants.UserInfoKey.roomIdentifier] as? String else {
            return
        }
        let roomProxy = await userSession.clientProxy.roomForIdentifier(roomId)
        switch await roomProxy?.sendMessage(replyText) {
        case .success:
            break
        default:
            // error or no room proxy
            service.showLocalNotification(with: "⚠️ " + ElementL10n.dialogTitleError,
                                          subtitle: ElementL10n.a11yErrorSomeMessageNotSent)
        }
    }
}
