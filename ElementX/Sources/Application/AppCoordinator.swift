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

class AppCoordinator: AppCoordinatorProtocol, AuthenticationCoordinatorDelegate, NotificationManagerDelegate, WindowManagerDelegate {
    private let stateMachine: AppCoordinatorStateMachine
    private let navigationRootCoordinator: NavigationRootCoordinator
    private let userSessionStore: UserSessionStoreProtocol
    private let appSettings: AppSettings
    private let appDelegate: AppDelegate

    /// Common background task to continue long-running tasks in the background.
    private var backgroundTask: BackgroundTaskProtocol?

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
    
    private var authenticationCoordinator: AuthenticationCoordinator?
    private let appLockFlowCoordinator: AppLockFlowCoordinator
    // periphery:ignore - used to avoid deallocation
    private var appLockSetupFlowCoordinator: AppLockSetupFlowCoordinator?
    private var userSessionFlowCoordinator: UserSessionFlowCoordinator?
    private var softLogoutCoordinator: SoftLogoutScreenCoordinator?
    
    private let backgroundTaskService: BackgroundTaskServiceProtocol

    private var appDelegateObserver: AnyCancellable?
    private var userSessionObserver: AnyCancellable?
    private var clientProxyObserver: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    
    let windowManager: WindowManagerProtocol = WindowManager()
    let notificationManager: NotificationManagerProtocol

    private let appRouteURLParser: AppRouteURLParser
    @Consumable private var storedAppRoute: AppRoute?

    init(appDelegate: AppDelegate) {
        Self.setupEnvironmentVariables()
        
        let appSettings = AppSettings()
        
        if appSettings.otlpTracingEnabled {
            MXLog.configure(logLevel: appSettings.logLevel, otlpConfiguration: .init(url: appSettings.otlpTracingURL,
                                                                                     username: appSettings.otlpTracingUsername,
                                                                                     password: appSettings.otlpTracingPassword))
        } else {
            MXLog.configure(logLevel: appSettings.logLevel)
        }
        
        let appName = InfoPlistReader.main.bundleDisplayName
        let appVersion = InfoPlistReader.main.bundleShortVersionString
        let appBuild = InfoPlistReader.main.bundleVersion
        MXLog.info("\(appName) \(appVersion) (\(appBuild))")
        
        if ProcessInfo.processInfo.environment["RESET_APP_SETTINGS"].map(Bool.init) == true {
            AppSettings.reset()
        }
        
        self.appDelegate = appDelegate
        self.appSettings = appSettings
        appRouteURLParser = AppRouteURLParser(appSettings: appSettings)
        
        navigationRootCoordinator = NavigationRootCoordinator()
        
        Self.setupServiceLocator(appSettings: appSettings)
        
        ServiceLocator.shared.analytics.startIfEnabled()

        stateMachine = AppCoordinatorStateMachine()
                
        navigationRootCoordinator.setRootCoordinator(SplashScreenCoordinator())

        backgroundTaskService = UIKitBackgroundTaskService {
            UIApplication.shared
        }

        let keychainController = KeychainController(service: .sessions,
                                                    accessGroup: InfoPlistReader.main.keychainAccessGroupIdentifier)
        userSessionStore = UserSessionStore(keychainController: keychainController,
                                            backgroundTaskService: backgroundTaskService)
        
        let appLockService = AppLockService(keychainController: keychainController, appSettings: appSettings)
        let appLockNavigationCoordinator = NavigationRootCoordinator()
        appLockFlowCoordinator = AppLockFlowCoordinator(appLockService: appLockService,
                                                        navigationCoordinator: appLockNavigationCoordinator)
        
        notificationManager = NotificationManager(notificationCenter: UNUserNotificationCenter.current(),
                                                  appSettings: appSettings)
        
        windowManager.delegate = self
        
        notificationManager.delegate = self
        notificationManager.start()
        
        guard let currentVersion = Version(InfoPlistReader(bundle: .main).bundleShortVersionString) else {
            fatalError("The app's version number **must** use semver for migration purposes.")
        }
        
        if let previousVersion = appSettings.lastVersionLaunched.flatMap(Version.init) {
            performMigrationsIfNecessary(from: previousVersion, to: currentVersion)
        } else {
            // The app has been deleted since the previous run. Reset everything.
            wipeUserData(includingSettings: true)
        }
        appSettings.lastVersionLaunched = currentVersion.description

        setupStateMachine()

        observeApplicationState()
        observeNetworkState()
        observeAppLockChanges()
        
        registerBackgroundAppRefresh()
    }
    
    func start() {
        guard stateMachine.state == .initial else {
            MXLog.error("Received a start request when already started")
            return
        }
        
        guard userSessionStore.hasSessions else {
            stateMachine.processEvent(.startWithAuthentication)
            return
        }
        
        if appSettings.appLockIsMandatory, !appLockFlowCoordinator.appLockService.isEnabled {
            stateMachine.processEvent(.startWithAppLockSetup)
        } else {
            stateMachine.processEvent(.startWithExistingSession)
        }
    }

    func stop() {
        hideLoadingIndicator()
    }
    
    func toPresentable() -> AnyView {
        AnyView(
            navigationRootCoordinator.toPresentable()
                .environment(\.analyticsService, ServiceLocator.shared.analytics)
                .onReceive(appSettings.$appAppearance) { [weak self] appAppearance in
                    guard let self else { return }
                    
                    windowManager.windows.forEach { window in
                        // Unfortunately .preferredColorScheme doesn't propagate properly throughout the app when changed
                        window.overrideUserInterfaceStyle = appAppearance.interfaceStyle
                    }
                }
        )
    }
    
    func handleDeepLink(_ url: URL) -> Bool {
        // Parse into an AppRoute to redirect these in a type safe way.
        
        if let route = appRouteURLParser.route(from: url) {
            switch route {
            case .oidcCallback(let url):
                if stateMachine.state == .softLogout {
                    softLogoutCoordinator?.handleOIDCRedirectURL(url)
                } else {
                    authenticationCoordinator?.handleOIDCRedirectURL(url)
                }
            case .genericCallLink(let url):
                if let userSessionFlowCoordinator {
                    userSessionFlowCoordinator.handleAppRoute(route, animated: true)
                } else {
                    navigationRootCoordinator.setSheetCoordinator(GenericCallLinkCoordinator(parameters: .init(url: url)))
                }
            case .roomMemberDetails, .room:
                userSessionFlowCoordinator?.handleAppRoute(route, animated: true)
            default:
                break
            }
            
            return true
        }
        
        return false
    }
    
    // MARK: - AuthenticationCoordinatorDelegate
    
    func authenticationCoordinator(didLoginWithSession userSession: UserSessionProtocol) {
        self.userSession = userSession
        authenticationCoordinator = nil
        stateMachine.processEvent(.createdUserSession)
    }
    
    // MARK: - WindowManagerDelegate
    
    func windowManagerDidConfigureWindows(_ windowManager: WindowManagerProtocol) {
        windowManager.alternateWindow.rootViewController = UIHostingController(rootView: appLockFlowCoordinator.toPresentable())
        ServiceLocator.shared.userIndicatorController.window = windowManager.overlayWindow
    }
    
    // MARK: - NotificationManagerDelegate
    
    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func unregisterForRemoteNotifications() {
        UIApplication.shared.unregisterForRemoteNotifications()
    }
        
    func shouldDisplayInAppNotification(content: UNNotificationContent) -> Bool {
        guard let roomID = content.roomID else {
            return true
        }
        guard let userSessionFlowCoordinator else {
            // there is not a user session yet
            return false
        }
        return !userSessionFlowCoordinator.isDisplayingRoomScreen(withRoomID: roomID)
    }
    
    func notificationTapped(content: UNNotificationContent) async {
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
        
        guard let roomID = content.userInfo[NotificationConstants.UserInfoKey.roomIdentifier] as? String else {
            return
        }
        let roomProxy = await userSession.clientProxy.roomForIdentifier(roomID)
        switch await roomProxy?.timeline.sendMessage(replyText,
                                                     html: nil,
                                                     intentionalMentions: .empty) {
        case .success:
            break
        default:
            // error or no room proxy
            await service.showLocalNotification(with: "⚠️ " + L10n.commonError,
                                                subtitle: L10n.errorSomeMessagesHaveNotBeenSent)
        }
    }
    
    // MARK: - Private
    
    private static func setupEnvironmentVariables() {
        setenv("RUST_BACKTRACE", "1", 1)
    }
    
    private static func setupServiceLocator(appSettings: AppSettings) {
        ServiceLocator.shared.register(userIndicatorController: UserIndicatorController())
        ServiceLocator.shared.register(appSettings: appSettings)
        ServiceLocator.shared.register(networkMonitor: NetworkMonitor())
        ServiceLocator.shared.register(bugReportService: BugReportService(withBaseURL: appSettings.bugReportServiceBaseURL,
                                                                          sentryURL: appSettings.bugReportSentryURL,
                                                                          applicationId: appSettings.bugReportApplicationId,
                                                                          sdkGitSHA: sdkGitSha(),
                                                                          maxUploadSize: appSettings.bugReportMaxUploadSize))
        ServiceLocator.shared.register(analytics: AnalyticsService(client: PostHogAnalyticsClient(),
                                                                   appSettings: appSettings,
                                                                   bugReportService: ServiceLocator.shared.bugReportService))
    }
    
    /// Perform any required migrations for the app to function correctly.
    private func performMigrationsIfNecessary(from oldVersion: Version, to newVersion: Version) {
        guard oldVersion != newVersion else { return }
        
        MXLog.info("The app was upgraded from \(oldVersion) to \(newVersion)")
        
        if oldVersion < Version(1, 1, 0) {
            MXLog.info("Migrating to v1.1.0, signing out the user.")
            // Version 1.1.0 switched the Rust crypto store to SQLite
            // There are no migrations in place so we need to sign the user out
            wipeUserData()
        }
        
        if oldVersion < Version(1, 1, 7) {
            MXLog.info("Migrating to v1.1.7, marking accounts as migrated.")
            for userID in userSessionStore.userIDs {
                appSettings.migratedAccounts[userID] = true
            }
        }
    }
    
    /// Clears the keychain, app support directory etc ready for a fresh use.
    /// - Parameter includingSettings: Whether to additionally wipe the user's app settings too.
    private func wipeUserData(includingSettings: Bool = false) {
        if includingSettings {
            AppSettings.reset()
            appLockFlowCoordinator.appLockService.disable()
        }
        userSessionStore.reset()
    }
    
    private func setupStateMachine() {
        stateMachine.addTransitionHandler { [weak self] context in
            guard let self else { return }
            
            switch (context.fromState, context.event, context.toState) {
            case (.initial, .startWithAuthentication, .signedOut):
                startAuthentication()
            case (.signedOut, .createdUserSession, .signedIn):
                setupUserSession()
            case (.initial, .startWithExistingSession, .restoringSession):
                restoreUserSession()
            case (.restoringSession, .failedRestoringSession, .signedOut):
                showLoginErrorToast()
                presentSplashScreen()
            case (.restoringSession, .createdUserSession, .signedIn):
                setupUserSession()
            
            case (.initial, .startWithAppLockSetup, .mandatoryAppLockSetup):
                startMandatoryAppLockSetup()
            case (.mandatoryAppLockSetup, .appLockSetupComplete, .restoringSession):
                restoreUserSession()
            
            case (.signingOut, .signOut, .signingOut):
                // We can ignore signOut when already in the process of signing out,
                // such as the SDK sending an authError due to token invalidation.
                break
            case (_, .signOut(let isSoft, _), .signingOut):
                logout(isSoft: isSoft)
            case (.signingOut(_, let disableAppLock), .completedSigningOut, .signedOut):
                presentSplashScreen(isSoftLogout: false, disableAppLock: disableAppLock)
            case (.signingOut(_, let disableAppLock), .showSoftLogout, .softLogout):
                presentSplashScreen(isSoftLogout: true, disableAppLock: disableAppLock)
            case (.signedIn, .clearCache, .initial):
                clearCache()
            default:
                fatalError("Unknown transition: \(context)")
            }
        }
        
        stateMachine.addErrorHandler { context in
            if context.fromState == context.toState {
                MXLog.error("Failed transition from equal states: \(context.fromState)")
            } else {
                fatalError("Failed transition with context: \(context)")
            }
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
        let authenticationService = AuthenticationServiceProxy(userSessionStore: userSessionStore, appSettings: appSettings)
        authenticationCoordinator = AuthenticationCoordinator(authenticationService: authenticationService,
                                                              navigationStackCoordinator: authenticationNavigationStackCoordinator,
                                                              appSettings: appSettings,
                                                              analytics: ServiceLocator.shared.analytics,
                                                              userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                              appLockService: appLockFlowCoordinator.appLockService)
        authenticationCoordinator?.delegate = self
        
        authenticationCoordinator?.start()
        
        navigationRootCoordinator.setRootCoordinator(authenticationNavigationStackCoordinator)
    }

    private func startAuthenticationSoftLogout() {
        guard let userSession else {
            fatalError("User session not setup")
        }
        
        Task {
            let credentials = SoftLogoutScreenCredentials(userID: userSession.userID,
                                                          homeserverName: userSession.homeserver,
                                                          userDisplayName: userSession.clientProxy.userDisplayName.value ?? "",
                                                          deviceID: userSession.deviceID)
            
            let authenticationService = AuthenticationServiceProxy(userSessionStore: userSessionStore, appSettings: appSettings)
            _ = await authenticationService.configure(for: userSession.homeserver)
            
            let parameters = SoftLogoutScreenCoordinatorParameters(authenticationService: authenticationService,
                                                                   credentials: credentials,
                                                                   keyBackupNeeded: false,
                                                                   userIndicatorController: ServiceLocator.shared.userIndicatorController)
            let coordinator = SoftLogoutScreenCoordinator(parameters: parameters)
            self.softLogoutCoordinator = coordinator
            coordinator.actions
                .sink { [weak self] action in
                    guard let self else { return }
                    
                    switch action {
                    case .signedIn(let session):
                        self.userSession = session
                        self.softLogoutCoordinator = nil
                        stateMachine.processEvent(.createdUserSession)
                    case .clearAllData:
                        self.softLogoutCoordinator = nil
                        stateMachine.processEvent(.signOut(isSoft: false, disableAppLock: false))
                    }
                }
                .store(in: &cancellables)
            
            navigationRootCoordinator.setRootCoordinator(coordinator)
        }
    }
    
    private func setupUserSession() {
        guard let userSession else {
            fatalError("User session not setup")
        }
        
        let navigationSplitCoordinator = NavigationSplitCoordinator(placeholderCoordinator: PlaceholderScreenCoordinator())
        let userSessionFlowCoordinator = UserSessionFlowCoordinator(userSession: userSession,
                                                                    navigationSplitCoordinator: navigationSplitCoordinator,
                                                                    windowManager: windowManager,
                                                                    appLockService: appLockFlowCoordinator.appLockService,
                                                                    bugReportService: ServiceLocator.shared.bugReportService,
                                                                    roomTimelineControllerFactory: RoomTimelineControllerFactory(),
                                                                    appSettings: appSettings,
                                                                    analytics: ServiceLocator.shared.analytics)
        
        userSessionFlowCoordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .logout:
                    stateMachine.processEvent(.signOut(isSoft: false, disableAppLock: false))
                case .clearCache:
                    stateMachine.processEvent(.clearCache)
                case .forceLogout:
                    stateMachine.processEvent(.signOut(isSoft: false, disableAppLock: true))
                }
            }
            .store(in: &cancellables)
        
        userSessionFlowCoordinator.start()
        
        self.userSessionFlowCoordinator = userSessionFlowCoordinator
        
        navigationRootCoordinator.setRootCoordinator(navigationSplitCoordinator)

        if let storedAppRoute {
            userSessionFlowCoordinator.handleAppRoute(storedAppRoute, animated: false)
        }
    }
    
    /// Used to add a PIN code to an existing session that somehow missed out mandatory PIN setup.
    private func startMandatoryAppLockSetup() {
        MXLog.info("Mandatory App Lock enabled but no PIN is set. Showing the setup flow.")
        
        let navigationCoordinator = NavigationStackCoordinator()
        let coordinator = AppLockSetupFlowCoordinator(presentingFlow: .onboarding,
                                                      appLockService: appLockFlowCoordinator.appLockService,
                                                      navigationStackCoordinator: navigationCoordinator)
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .complete:
                stateMachine.processEvent(.appLockSetupComplete)
                appLockSetupFlowCoordinator = nil
            case .forceLogout:
                fatalError("Creating a PIN shouldn't be able to fail in this way")
            }
        }
        .store(in: &cancellables)
        
        appLockSetupFlowCoordinator = coordinator
        navigationRootCoordinator.setRootCoordinator(navigationCoordinator)
        coordinator.start()
    }
    
    private func logout(isSoft: Bool) {
        guard let userSession else {
            fatalError("User session not setup")
        }
        
        showLoadingIndicator()
        
        stopSync()
        userSessionFlowCoordinator?.stop()
        
        guard !isSoft else {
            stateMachine.processEvent(.showSoftLogout)
            hideLoadingIndicator()
            return
        }
        
        // The user will log out, clear any existing notifications and unregister from receving new ones
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        unregisterForRemoteNotifications()
        
        Task {
            // First log out from the server
            let accountLogoutURL = await userSession.clientProxy.logout()
            
            // Regardless of the result, clear user data
            userSessionStore.logout(userSession: userSession)
            tearDownUserSession()
            
            // Reset analytics
            ServiceLocator.shared.analytics.optOut()
            ServiceLocator.shared.analytics.resetConsentState()
            
            stateMachine.processEvent(.completedSigningOut)
            
            // Handle OIDC's RP-Initiated Logout if needed. Don't fallback to an ASWebAuthenticationSession
            // as it looks weird to show an alert to the user asking them to sign in to their provider.
            if let accountLogoutURL, UIApplication.shared.canOpenURL(accountLogoutURL) {
                await UIApplication.shared.open(accountLogoutURL)
            }
            
            hideLoadingIndicator()
        }
    }
    
    private func tearDownUserSession() {
        ServiceLocator.shared.userIndicatorController.retractAllIndicators()
        
        userSession = nil
        
        userSessionFlowCoordinator = nil

        notificationManager.setUserSession(nil)
    }
    
    private func presentSplashScreen(isSoftLogout: Bool = false, disableAppLock: Bool = false) {
        navigationRootCoordinator.setRootCoordinator(SplashScreenCoordinator())
        
        if isSoftLogout {
            startAuthenticationSoftLogout()
        } else {
            startAuthentication()
        }
        
        if disableAppLock {
            Task {
                // Ensure the navigation stack has settled.
                try? await Task.sleep(for: .milliseconds(500))
                appLockFlowCoordinator.appLockService.disable()
                windowManager.switchToMain()
            }
        }
    }

    private func configureNotificationManager() {
        notificationManager.setUserSession(userSession)
        notificationManager.requestAuthorization()

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
                    stateMachine.processEvent(.signOut(isSoft: isSoftLogout, disableAppLock: false))
                }
            }
    }
    
    private func observeNetworkState() {
        let reachabilityNotificationIdentifier = "io.element.elementx.reachability.notification"
        ServiceLocator.shared.networkMonitor
            .reachabilityPublisher
            .removeDuplicates()
            .sink { reachability in
                MXLog.info("Reachability changed to \(reachability)")
                
                if reachability == .reachable {
                    ServiceLocator.shared.userIndicatorController.retractIndicatorWithId(reachabilityNotificationIdentifier)
                } else {
                    ServiceLocator.shared.userIndicatorController.submitIndicator(.init(id: reachabilityNotificationIdentifier,
                                                                                        title: L10n.commonOffline,
                                                                                        persistent: true))
                }
            }
            .store(in: &cancellables)
    }
    
    private func observeAppLockChanges() {
        appLockFlowCoordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .lockApp:
                windowManager.switchToAlternate()
            case .unlockApp:
                windowManager.switchToMain()
            case .forceLogout:
                stateMachine.processEvent(.signOut(isSoft: false, disableAppLock: true))
            }
        }
        .store(in: &cancellables)
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
        
        navigationRootCoordinator.setRootCoordinator(PlaceholderScreenCoordinator())
        
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
        clientProxyObserver = nil
    }

    private func startSync() {
        guard let userSession else { return }
        
        ServiceLocator.shared.analytics.signpost.beginFirstSync()
        userSession.clientProxy.startSync()
        
        guard clientProxyObserver == nil else {
            return
        }
        
        clientProxyObserver = userSession.clientProxy
            .loadingStatePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { state in
                let toastIdentifier = "StaleDataIndicator"
                
                switch state {
                case .loading:
                    if ServiceLocator.shared.networkMonitor.reachabilityPublisher.value == .reachable {
                        ServiceLocator.shared.userIndicatorController.submitIndicator(.init(id: toastIdentifier, type: .toast(progress: .indeterminate), title: L10n.commonSyncing, persistent: true))
                    }
                case .notLoading:
                    ServiceLocator.shared.analytics.signpost.endFirstSync()
                    ServiceLocator.shared.userIndicatorController.retractIndicatorWithId(toastIdentifier)
                }
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

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillTerminate),
                                               name: UIApplication.willTerminateNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didChangeContentSizeCategory),
                                               name: UIContentSizeCategory.didChangeNotification,
                                               object: nil)
    }

    @objc
    private func didChangeContentSizeCategory() {
        AttributedStringBuilder.invalidateCaches()
    }

    @objc
    private func applicationWillTerminate() {
        stopSync()
    }

    @objc
    private func applicationWillResignActive() {
        MXLog.info("Application will resign active")

        guard backgroundTask == nil else {
            return
        }

        backgroundTask = backgroundTaskService.startBackgroundTask(withName: "SuspendApp: \(UUID().uuidString)") { [weak self] in
            guard let self else { return }
            
            stopSync()
            
            backgroundTask?.stop()
            backgroundTask = nil
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

        if isSuspended {
            startSync()
        }

        isSuspended = false
    }
    
    // MARK: Background app refresh
    
    private func registerBackgroundAppRefresh() {
        let result = BGTaskScheduler.shared.register(forTaskWithIdentifier: appSettings.backgroundAppRefreshTaskIdentifier, using: .main) { [weak self] task in
            guard let task = task as? BGAppRefreshTask else {
                MXLog.error("Invalid background app refresh configuration")
                return
            }
            
            self?.handleBackgroundAppRefresh(task)
        }
        
        MXLog.info("Register background app refresh with result: \(result)")
    }
    
    private func scheduleBackgroundAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: appSettings.backgroundAppRefreshTaskIdentifier)
        
        // We have other background tasks that keep the app alive
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            MXLog.info("Successfully scheduled background app refresh task")
        } catch {
            MXLog.error("Failed scheduling background app refresh with error :\(error)")
        }
    }
    
    private var backgroundRefreshSyncObserver: AnyCancellable?
    private func handleBackgroundAppRefresh(_ task: BGAppRefreshTask) {
        MXLog.info("Started background app refresh")
        
        // This is important for the app to keep refreshing in the background
        scheduleBackgroundAppRefresh()
        
        task.expirationHandler = {
            MXLog.info("Background app refresh task expired")
            task.setTaskCompleted(success: true)
        }
        
        guard let userSession else {
            return
        }
        
        startSync()
        
        // Be a good citizen, run for a max of 10 SS responses or 10 seconds
        // An SS request will time out after 30 seconds if no new data is available
        backgroundRefreshSyncObserver = userSession.clientProxy
            .callbacks
            .filter(\.isSyncUpdate)
            .collect(.byTimeOrCount(DispatchQueue.main, .seconds(10), 10))
            .sink(receiveValue: { [weak self] _ in
                guard let self else { return }
                
                MXLog.info("Background app refresh finished")
                backgroundRefreshSyncObserver?.cancel()
                
                task.setTaskCompleted(success: true)
            })
    }
}
