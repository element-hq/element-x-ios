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

class AppCoordinator: AppCoordinatorProtocol {
    private let stateMachine: AppCoordinatorStateMachine
    private let navigationRootCoordinator: NavigationRootCoordinator
    private let userSessionStore: UserSessionStoreProtocol
    /// Common background task to resume long-running tasks in the background.
    /// When this task expiring, we'll try to suspend the state machine by `suspend` event.
    private var backgroundTask: BackgroundTaskProtocol?
    private var isSuspended = false
    
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

    private var userSessionCancellables = Set<AnyCancellable>()
    private var cancellables = Set<AnyCancellable>()
    private(set) var notificationManager: NotificationManagerProtocol?

    init() {
        navigationRootCoordinator = NavigationRootCoordinator()
        
        Self.setupServiceLocator(navigationRootCoordinator: navigationRootCoordinator)
        Self.setupLogging()
        
        stateMachine = AppCoordinatorStateMachine()
        
        bugReportService = BugReportService(withBaseURL: ServiceLocator.shared.settings.bugReportServiceBaseURL, sentryURL: ServiceLocator.shared.settings.bugReportSentryURL)

        navigationRootCoordinator.setRootCoordinator(SplashScreenCoordinator())

        backgroundTaskService = UIKitBackgroundTaskService {
            UIApplication.shared
        }

        userSessionStore = UserSessionStore(backgroundTaskService: backgroundTaskService)
        
        // Reset everything if the app has been deleted since the previous run
        if !ServiceLocator.shared.settings.hasAppLaunchedOnce {
            AppSettings.reset()
            userSessionStore.reset()
            ServiceLocator.shared.settings.hasAppLaunchedOnce = true
        }
        
        setupStateMachine()
        
        Bundle.elementFallbackLanguage = "en"

        observeApplicationState()
        observeNetworkState()
    }
    
    func start() {
        guard stateMachine.state == .initial else {
            MXLog.error("Received a start request when already started")
            return
        }
        
        stateMachine.processEvent(userSessionStore.hasSessions ? .startWithExistingSession : .startWithAuthentication)
    }

    func stop() {
        hideLoadingIndicator()
    }
    
    func toPresentable() -> AnyView {
        ServiceLocator.shared.userNotificationController.toPresentable()
    }
        
    // MARK: - Private
    
    private static func setupServiceLocator(navigationRootCoordinator: NavigationRootCoordinator) {
        ServiceLocator.shared.register(userNotificationController: UserNotificationController(rootCoordinator: navigationRootCoordinator))
        ServiceLocator.shared.register(appSettings: AppSettings())
        ServiceLocator.shared.register(networkMonitor: NetworkMonitor())
    }
    
    private static func setupLogging() {
        let loggerConfiguration = MXLogConfiguration()
        loggerConfiguration.maxLogFilesCount = 10
        
        #if DEBUG
        setupTracing(configuration: .debug)
        loggerConfiguration.logLevel = .debug
        #else
        setupTracing(configuration: .release)
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
                self.restoreUserSession()
            case (.restoringSession, .failedRestoringSession, .signedOut):
                self.showLoginErrorToast()
                self.presentSplashScreen(isSoftLogout: false)
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
        let authenticationNavigationStackCoordinator = NavigationStackCoordinator()
        let authenticationService = AuthenticationServiceProxy(userSessionStore: userSessionStore)
        authenticationCoordinator = AuthenticationCoordinator(authenticationService: authenticationService,
                                                              navigationStackCoordinator: authenticationNavigationStackCoordinator)
        authenticationCoordinator?.delegate = self
        
        authenticationCoordinator?.start()
        
        navigationRootCoordinator.setRootCoordinator(authenticationNavigationStackCoordinator)
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
            
            navigationRootCoordinator.setRootCoordinator(coordinator)
        }
    }
    
    private func setupUserSession() {
        let navigationSplitCoordinator = NavigationSplitCoordinator(placeholderCoordinator: SplashScreenCoordinator())
        let userSessionFlowCoordinator = UserSessionFlowCoordinator(userSession: userSession,
                                                                    navigationSplitCoordinator: navigationSplitCoordinator,
                                                                    bugReportService: bugReportService,
                                                                    roomTimelineControllerFactory: RoomTimelineControllerFactory())
        
        userSessionFlowCoordinator.callback = { [weak self] action in
            switch action {
            case .signOut:
                self?.stateMachine.processEvent(.signOut)
            }
        }
        
        userSessionFlowCoordinator.start()
        
        self.userSessionFlowCoordinator = userSessionFlowCoordinator
        
        navigationRootCoordinator.setRootCoordinator(navigationSplitCoordinator)
    }
    
    private func tearDownUserSession(isSoftLogout: Bool = false) {
        userSession.clientProxy.stopSync()
        userSessionFlowCoordinator?.stop()
        
        deobserveUserSessionChanges()
        
        guard !isSoftLogout else {
            stateMachine.processEvent(.completedSigningOut)
            return
        }
        
        Task {
            showLoadingIndicator()
            
            //  first log out from the server
            _ = await userSession.clientProxy.logout()
            
            //  regardless of the result, clear user data
            userSessionStore.logout(userSession: userSession)
            userSession = nil
            notificationManager?.delegate = nil
            notificationManager = nil
            
            stateMachine.processEvent(.completedSigningOut)
            
            hideLoadingIndicator()
        }
    }

    private func presentSplashScreen(isSoftLogout: Bool = false) {
        navigationRootCoordinator.setRootCoordinator(SplashScreenCoordinator())
        
        if isSoftLogout {
            startAuthenticationSoftLogout()
        } else {
            startAuthentication()
        }
    }

    private func configureNotificationManager() {
        guard ServiceLocator.shared.settings.enableNotifications else {
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
                            Task { await self?.notificationManager?.register(with: deviceToken) }
                        case .failedToRegisteredNotifications(let error):
                            self?.notificationManager?.registrationFailed(with: error)
                        }
                    }
                    .store(in: &cancellables)
            } else {
                MXLog.error("Couldn't register to AppDelegate callbacks")
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
            .store(in: &userSessionCancellables)
    }

    private func deobserveUserSessionChanges() {
        userSessionCancellables.removeAll()
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

    // MARK: - Application State

    private func pause() {
        userSession?.clientProxy.stopSync()
    }

    private func resume() {
        userSession?.clientProxy.startSync()
    }

    private func observeApplicationState() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillResignActive),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }

    @objc
    private func applicationWillResignActive() {
        MXLog.info("Application will resign active")
        
        guard backgroundTask == nil else {
            return
        }

        backgroundTask = backgroundTaskService.startBackgroundTask(withName: "SuspendApp: \(UUID().uuidString)") { [weak self] in
            self?.pause()
            
            self?.backgroundTask = nil
            self?.isSuspended = true
        }
    }

    @objc
    private func applicationDidBecomeActive() {
        MXLog.info("Application did become active")
        
        backgroundTask?.stop()
        backgroundTask = nil

        if isSuspended {
            isSuspended = false
            resume()
        }
    }
    
    private func observeNetworkState() {
        let reachabilityNotificationIdentifier = "io.element.elementx.reachability.notification"
        ServiceLocator.shared.networkMonitor.reachabilityPublisher.sink { reachable in
            MXLog.info("Reachability changed to \(reachable)")
            
            if reachable {
                ServiceLocator.shared.userNotificationController.retractNotificationWithId(reachabilityNotificationIdentifier)
            } else {
                ServiceLocator.shared.userNotificationController.submitNotification(.init(id: reachabilityNotificationIdentifier,
                                                                                          title: ElementL10n.a11yPresenceOffline,
                                                                                          persistent: true))
            }
        }.store(in: &cancellables)
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
        MXLog.info("[AppCoordinator] tappedNotification")

        guard let roomId = content.userInfo[NotificationConstants.UserInfoKey.roomIdentifier] as? String else {
            return
        }

        userSessionFlowCoordinator?.tryDisplayingRoomScreen(roomId: roomId)
    }

    func handleInlineReply(_ service: NotificationManagerProtocol, content: UNNotificationContent, replyText: String) async {
        MXLog.info("[AppCoordinator] handle notification reply")

        guard let roomId = content.userInfo[NotificationConstants.UserInfoKey.roomIdentifier] as? String else {
            return
        }
        let roomProxy = await userSession.clientProxy.roomForIdentifier(roomId)
        switch await roomProxy?.sendMessage(replyText) {
        case .success:
            break
        default:
            // error or no room proxy
            await service.showLocalNotification(with: "⚠️ " + ElementL10n.dialogTitleError,
                                                subtitle: ElementL10n.a11yErrorSomeMessageNotSent)
        }
    }
}
