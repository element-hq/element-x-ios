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

import BackgroundTasks
import Combine
import MatrixRustSDK
import SwiftUI
import Version

class AppCoordinator: AppCoordinatorProtocol, AuthenticationCoordinatorDelegate, NotificationManagerDelegate {
    private let stateMachine: AppCoordinatorStateMachine
    private let navigationRootCoordinator: NavigationRootCoordinator
    private let userSessionStore: UserSessionStoreProtocol
    /// Common background task to resume long-running tasks in the background.
    /// When this task expiring, we'll try to suspend the state machine by `suspend` event.
    private var backgroundTask: BackgroundTaskProtocol?

    /// Task used while processing background app refreshes
    private var backgroundAppRefreshTask: BGAppRefreshTask?
    
    private var isSuspended = false
    
    private var userSession: UserSessionProtocol? {
        didSet {
            userSessionObserver?.cancel()
            
            if userSession != nil {
                configureNotificationManager()
                observeUserSessionChanges()
                startSync()
            }
        }
    }
    
    private var userSessionFlowCoordinator: UserSessionFlowCoordinator?
    private var authenticationCoordinator: AuthenticationCoordinator?
    
    private let backgroundTaskService: BackgroundTaskServiceProtocol

    private var appDelegateObserver: AnyCancellable?
    private var userSessionObserver: AnyCancellable?
    private var networkMonitorObserver: AnyCancellable?
    private var initialSyncObserver: AnyCancellable?
    private var backgroundRefreshSyncObserver: AnyCancellable?
    
    let notificationManager: NotificationManagerProtocol

    @Consumable private var storedAppRoute: AppRoute?

    init() {
        MXLog.configure()
        
        navigationRootCoordinator = NavigationRootCoordinator()
        
        Self.setupServiceLocator(navigationRootCoordinator: navigationRootCoordinator)

        ServiceLocator.shared.analytics.startIfEnabled()

        stateMachine = AppCoordinatorStateMachine()
                
        navigationRootCoordinator.setRootCoordinator(SplashScreenCoordinator())

        backgroundTaskService = UIKitBackgroundTaskService {
            UIApplication.shared
        }

        userSessionStore = UserSessionStore(backgroundTaskService: backgroundTaskService)

        notificationManager = NotificationManager()
        notificationManager.delegate = self
        notificationManager.start()
        
        guard let currentVersion = Version(InfoPlistReader(bundle: .main).bundleShortVersionString) else {
            fatalError("The app's version number **must** use semver for migration purposes.")
        }
        
        if let previousVersion = ServiceLocator.shared.settings.lastVersionLaunched.flatMap(Version.init) {
            performMigrationsIfNecessary(from: previousVersion, to: currentVersion)
        } else {
            // The app has been deleted since the previous run. Reset everything.
            wipeUserData(includingSettings: true)
        }
        ServiceLocator.shared.settings.lastVersionLaunched = currentVersion.description

        setupStateMachine()

        observeApplicationState()
        observeNetworkState()
        
        registerBackgroundAppRefresh()
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
        ServiceLocator.shared.userIndicatorController.toPresentable()
    }
    
    // MARK: - AuthenticationCoordinatorDelegate
    
    func authenticationCoordinator(_ authenticationCoordinator: AuthenticationCoordinator, didLoginWithSession userSession: UserSessionProtocol) {
        self.userSession = userSession
        stateMachine.processEvent(.createdUserSession)
    }
    
    // MARK: - NotificationManagerDelegate
    
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
        
        guard let roomID = content.roomID,
              content.receiverID != nil else {
            return
        }
        
        // Handle here the account switching when available
        
        handleAppRoute(.room(roomID: roomID))
    }
    
    func handleInlineReply(_ service: NotificationManagerProtocol, content: UNNotificationContent, replyText: String) async {
        guard let userSession else {
            fatalError("User session not setup")
        }
        
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
            await service.showLocalNotification(with: "⚠️ " + L10n.commonError,
                                                subtitle: L10n.errorSomeMessagesHaveNotBeenSent)
        }
    }
    
    // MARK: - Private
    
    private static func setupServiceLocator(navigationRootCoordinator: NavigationRootCoordinator) {
        ServiceLocator.shared.register(userIndicatorController: UserIndicatorController(rootCoordinator: navigationRootCoordinator))
        ServiceLocator.shared.register(appSettings: AppSettings())
        ServiceLocator.shared.register(networkMonitor: NetworkMonitor())
        ServiceLocator.shared.register(bugReportService: BugReportService(withBaseURL: ServiceLocator.shared.settings.bugReportServiceBaseURL,
                                                                          sentryURL: ServiceLocator.shared.settings.bugReportSentryURL))
        ServiceLocator.shared.register(analytics: Analytics(client: PostHogAnalyticsClient()))
    }
    
    /// Perform any required migrations for the app to function correctly.
    private func performMigrationsIfNecessary(from oldVersion: Version, to newVersion: Version) {
        guard oldVersion != newVersion else { return }
        
        if oldVersion < Version(1, 1, 0) {
            // Version 1.1.0 switched the Rust crypto store to SQLite
            // There are no migrations in place so we need to reset everything
            wipeUserData()
        }
    }
    
    /// Clears the keychain, app support directory etc ready for a fresh use.
    /// - Parameter includingSettings: Whether to additionally wipe the user's app settings too.
    private func wipeUserData(includingSettings: Bool = false) {
        if includingSettings {
            AppSettings.reset()
        }
        userSessionStore.reset()
    }
    
    // swiftlint:disable:next cyclomatic_complexity
    private func setupStateMachine() {
        stateMachine.addTransitionHandler { [weak self] context in
            guard let self else { return }
            
            switch (context.fromState, context.event, context.toState) {
            case (.initial, .startWithAuthentication, .signedOut):
                self.startAuthentication()
            case (.signedOut, .createdUserSession, .signedIn):
                self.setupUserSession()
            case (.initial, .startWithExistingSession, .restoringSession):
                self.restoreUserSession()
            case (.restoringSession, .failedRestoringSession, .signedOut):
                self.showLoginErrorToast()
                self.presentSplashScreen()
            case (.restoringSession, .createdUserSession, .signedIn):
                self.setupUserSession()
            case (.signingOut, .signOut, .signingOut):
                // We can ignore signOut when already in the process of signing out,
                // such as the SDK sending an authError due to token invalidation.
                break
            case (_, .signOut(let isSoft), .signingOut):
                self.logout(isSoft: isSoft)
            case (.signingOut, .completedSigningOut(let isSoft), .signedOut):
                self.presentSplashScreen(isSoftLogout: isSoft)
            case (.signedIn, .clearCache, .initial):
                self.clearCache()
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
                stateMachine.processEvent(.createdUserSession)
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
        guard let userSession else {
            fatalError("User session not setup")
        }
        
        Task {
            var displayName = ""
            if case .success(let name) = await userSession.clientProxy.loadUserDisplayName() {
                displayName = name
            }
            
            let credentials = SoftLogoutScreenCredentials(userId: userSession.userID,
                                                          homeserverName: userSession.homeserver,
                                                          userDisplayName: displayName,
                                                          deviceId: userSession.deviceID)
            
            let authenticationService = AuthenticationServiceProxy(userSessionStore: userSessionStore)
            _ = await authenticationService.configure(for: userSession.homeserver)
            
            let parameters = SoftLogoutScreenCoordinatorParameters(authenticationService: authenticationService,
                                                                   credentials: credentials,
                                                                   keyBackupNeeded: false)
            let coordinator = SoftLogoutScreenCoordinator(parameters: parameters)
            coordinator.callback = { result in
                switch result {
                case .signedIn(let session):
                    self.userSession = session
                    self.stateMachine.processEvent(.createdUserSession)
                case .clearAllData:
                    self.stateMachine.processEvent(.signOut(isSoft: false))
                }
            }
            
            navigationRootCoordinator.setRootCoordinator(coordinator)
        }
    }
    
    private func setupUserSession() {
        guard let userSession else {
            fatalError("User session not setup")
        }
        
        let navigationSplitCoordinator = NavigationSplitCoordinator(placeholderCoordinator: SplashScreenCoordinator())
        let userSessionFlowCoordinator = UserSessionFlowCoordinator(userSession: userSession,
                                                                    navigationSplitCoordinator: navigationSplitCoordinator,
                                                                    bugReportService: ServiceLocator.shared.bugReportService,
                                                                    roomTimelineControllerFactory: RoomTimelineControllerFactory())
        
        userSessionFlowCoordinator.callback = { [weak self] action in
            switch action {
            case .signOut:
                self?.stateMachine.processEvent(.signOut(isSoft: false))
            case .clearCache:
                self?.stateMachine.processEvent(.clearCache)
            }
        }
        
        userSessionFlowCoordinator.start()
        
        self.userSessionFlowCoordinator = userSessionFlowCoordinator
        
        navigationRootCoordinator.setRootCoordinator(navigationSplitCoordinator)

        if let storedAppRoute {
            userSessionFlowCoordinator.handleAppRoute(storedAppRoute, animated: false)
        }
    }
    
    private func logout(isSoft: Bool) {
        guard let userSession else {
            fatalError("User session not setup")
        }
        
        showLoadingIndicator()
        
        defer {
            hideLoadingIndicator()
        }
        
        stopSync()
        userSessionFlowCoordinator?.stop()
        
        guard !isSoft else {
            stateMachine.processEvent(.completedSigningOut(isSoft: isSoft))
            return
        }
        
        Task {
            //  first log out from the server
            _ = await userSession.clientProxy.logout()
            
            //  regardless of the result, clear user data
            userSessionStore.logout(userSession: userSession)
            tearDownUserSession()
            
            // reset analytics
            ServiceLocator.shared.analytics.optOut()
            ServiceLocator.shared.analytics.resetConsentState()
            
            stateMachine.processEvent(.completedSigningOut(isSoft: isSoft))
        }
    }
    
    private func tearDownUserSession() {
        userSession = nil
        
        userSessionFlowCoordinator = nil

        notificationManager.setUserSession(nil)
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
        notificationManager.setUserSession(userSession)
        notificationManager.requestAuthorization()

        if let appDelegate = AppDelegate.shared {
            appDelegateObserver = appDelegate.callbacks
                .receive(on: DispatchQueue.main)
                .sink { [weak self] callback in
                    switch callback {
                    case .registeredNotifications(let deviceToken):
                        Task { await self?.notificationManager.register(with: deviceToken) }
                    case .failedToRegisteredNotifications(let error):
                        self?.notificationManager.registrationFailed(with: error)
                    }
                }
        } else {
            MXLog.error("Couldn't register to AppDelegate callbacks")
        }
    }
    
    private func observeUserSessionChanges() {
        guard let userSession else {
            fatalError("User session not setup")
        }
        
        userSessionObserver = userSession.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                guard let self else { return }
                switch callback {
                case .didReceiveAuthError(let isSoftLogout):
                    stateMachine.processEvent(.signOut(isSoft: isSoftLogout))
                case .updateRestorationToken:
                    userSessionStore.refreshRestorationToken(for: userSession)
                default:
                    break
                }
            }
    }
    
    private func observeNetworkState() {
        let reachabilityNotificationIdentifier = "io.element.elementx.reachability.notification"
        networkMonitorObserver = ServiceLocator.shared.networkMonitor.reachabilityPublisher.sink { reachable in
            MXLog.info("Reachability changed to \(reachable)")
            
            if reachable {
                ServiceLocator.shared.userIndicatorController.retractIndicatorWithId(reachabilityNotificationIdentifier)
            } else {
                ServiceLocator.shared.userIndicatorController.submitIndicator(.init(id: reachabilityNotificationIdentifier,
                                                                                    title: L10n.commonOffline,
                                                                                    persistent: true))
            }
        }
    }

    private func handleAppRoute(_ appRoute: AppRoute) {
        if let userSessionFlowCoordinator {
            userSessionFlowCoordinator.handleAppRoute(appRoute, animated: UIApplication.shared.applicationState == .active)
        } else {
            storedAppRoute = appRoute
        }
    }
    
    private func clearCache() {
        guard let userSession else {
            fatalError("User session not setup")
        }
        
        showLoadingIndicator()
        
        navigationRootCoordinator.setRootCoordinator(SplashScreenCoordinator())
        
        stopSync()
        userSessionFlowCoordinator?.stop()
        
        let userID = userSession.userID
        tearDownUserSession()
    
        // Allow for everything to deallocate properly
        Task {
            try? await Task.sleep(for: .seconds(2))
            userSessionStore.clearCache(for: userID)
            stateMachine.processEvent(.startWithExistingSession)
            hideLoadingIndicator()
        }
    }
    
    // MARK: Toasts and loading indicators
    
    private static let loadingIndicatorIdentifier = "AppCoordinatorLoading"
    
    private func showLoadingIndicator() {
        ServiceLocator.shared.userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                                                    type: .modal,
                                                                                    title: L10n.commonLoading,
                                                                                    persistent: true))
    }
    
    private func hideLoadingIndicator() {
        ServiceLocator.shared.userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
    
    private func showLoginErrorToast() {
        ServiceLocator.shared.userIndicatorController.submitIndicator(UserIndicator(title: "Failed logging in"))
    }

    // MARK: - Application State

    private func stopSync() {
        userSession?.clientProxy.stopSync()
        
        backgroundAppRefreshTask?.setTaskCompleted(success: true)
        backgroundAppRefreshTask = nil
    }

    private func startSync() {
        guard let userSession else {
            fatalError("User session not setup")
        }
        
        userSession.clientProxy.startSync()
        
        installBackgroundAppRefreshMonitor()
        
        let identifier = "StaleDataIndicator"
        
        ServiceLocator.shared.userIndicatorController.submitIndicator(.init(id: identifier, type: .toast, title: L10n.commonLoading, persistent: true))
        
        initialSyncObserver = userSession.clientProxy
            .callbacks
            .receive(on: DispatchQueue.main)
            .filter(\.isSyncUpdate)
            .sink { [weak self] _ in
                ServiceLocator.shared.userIndicatorController.retractIndicatorWithId(identifier)
                self?.initialSyncObserver?.cancel()
            }
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
            guard let self else { return }
            
            userSession?.clientProxy.stopSync {
                // No need to weakify self, this is a non escaping closure
                self.backgroundTask?.stop()
                self.backgroundTask = nil
                
                self.backgroundAppRefreshTask?.setTaskCompleted(success: true)
                self.backgroundAppRefreshTask = nil
            }
        }

        isSuspended = true

        // This does seem to work if scheduled from the background task above
        // Schedule it here instead but with an earliest being date of 30 seconds
        scheduleBackgroundAppRefresh()
    }

    @objc
    private func applicationDidBecomeActive() {
        MXLog.info("Application did become active")
        
        backgroundTask?.stop()
        backgroundTask = nil

        if isSuspended, userSession?.clientProxy.isSyncing == false {
            startSync()
        }

        isSuspended = false
    }
    
    // MARK: Background app refresh
    
    private func registerBackgroundAppRefresh() {
        let result = BGTaskScheduler.shared.register(forTaskWithIdentifier: ServiceLocator.shared.settings.backgroundAppRefreshTaskIdentifier, using: .main) { [weak self] task in
            guard let task = task as? BGAppRefreshTask else {
                MXLog.error("Invalid background app refresh configuration")
                return
            }
            
            self?.handleBackgroundAppRefresh(task)
        }
        
        MXLog.info("Register background app refresh with result: \(result)")
    }
    
    private func scheduleBackgroundAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: ServiceLocator.shared.settings.backgroundAppRefreshTaskIdentifier)
        
        // We have other background tasks that keep the app alive
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            MXLog.info("Successfully scheduled background app refresh task")
        } catch {
            MXLog.error("Failed scheduling background app refresh with error :\(error)")
        }
    }
    
    private func handleBackgroundAppRefresh(_ task: BGAppRefreshTask) {
        MXLog.info("Started background app refresh")
        
        backgroundAppRefreshTask = task
        
        // This is important for the app to keep refreshing in the background
        scheduleBackgroundAppRefresh()
        
        task.expirationHandler = { [weak self] in
            MXLog.info("Background app refresh task expired")
            self?.stopSync()
        }
        
        guard let userSession, !userSession.clientProxy.isSyncing else {
            return
        }
        
        startSync()
    }
    
    private func installBackgroundAppRefreshMonitor() {
        guard let userSession else {
            fatalError("User session not setup")
        }
        
        guard backgroundAppRefreshTask != nil else {
            return
        }
        
        // Be a good citizen, run for a max of 10 SS responses or 10 seconds
        // An SS request will time out after 30 seconds if no new data is available
        backgroundRefreshSyncObserver = userSession.clientProxy
            .callbacks
            .filter(\.isSyncUpdate)
            .collect(.byTimeOrCount(DispatchQueue.main, .seconds(10), 10))
            .sink(receiveValue: { [weak self] _ in
                MXLog.info("Background app refresh finished")
                self?.backgroundRefreshSyncObserver?.cancel()
                self?.stopSync()
            })
    }
}
