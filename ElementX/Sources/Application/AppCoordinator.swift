//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import AnalyticsEvents
import BackgroundTasks
import Combine
import Intents
import MatrixRustSDK
import Sentry
import SwiftUI
import Version

class AppCoordinator: AppCoordinatorProtocol, AuthenticationFlowCoordinatorDelegate, NotificationManagerDelegate, SecureWindowManagerDelegate {
    private let stateMachine: AppCoordinatorStateMachine
    private let navigationRootCoordinator: NavigationRootCoordinator
    private let userSessionStore: UserSessionStoreProtocol
    private let appMediator: AppMediator
    private let appSettings: AppSettings
    private let appDelegate: AppDelegate
    private let appHooks: AppHooks
    private let elementCallService: ElementCallServiceProtocol

    /// Common background task to continue long-running tasks in the background.
    private var backgroundTask: UIBackgroundTaskIdentifier?

    private var isSuspended = false
    
    private var userSession: UserSessionProtocol? {
        didSet {
            userSessionObserver?.cancel()
            if let userSession {
                userSession.clientProxy.roomsToAwait = storedRoomsToAwait
                configureElementCallService()
                configureNotificationManager()
                observeUserSessionChanges()
                startSync()
            }
        }
    }
    
    private var authenticationFlowCoordinator: AuthenticationFlowCoordinator?
    private let appLockFlowCoordinator: AppLockFlowCoordinator
    // periphery:ignore - used to avoid deallocation
    private var appLockSetupFlowCoordinator: AppLockSetupFlowCoordinator?
    private var userSessionFlowCoordinator: UserSessionFlowCoordinator?
    private var softLogoutCoordinator: SoftLogoutScreenCoordinator?
    private var appDelegateObserver: AnyCancellable?
    private var userSessionObserver: AnyCancellable?
    private var clientProxyObserver: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    
    let windowManager: SecureWindowManagerProtocol
    let notificationManager: NotificationManagerProtocol

    private let appRouteURLParser: AppRouteURLParser
    @Consumable private var storedAppRoute: AppRoute?
    private var storedRoomsToAwait: Set<String> = []

    init(appDelegate: AppDelegate) {
        let appHooks = AppHooks()
        appHooks.configure()
        
        windowManager = WindowManager(appDelegate: appDelegate)
        let networkMonitor = NetworkMonitor()
        appMediator = AppMediator(windowManager: windowManager, networkMonitor: networkMonitor)
        
        let appSettings = appHooks.appSettingsHook.configure(AppSettings())
        
        MXLog.configure(logLevel: appSettings.logLevel)
        
        let appName = InfoPlistReader.main.bundleDisplayName
        let appVersion = InfoPlistReader.main.bundleShortVersionString
        let appBuild = InfoPlistReader.main.bundleVersion
        MXLog.info("\(appName) \(appVersion) (\(appBuild))")
        
        if ProcessInfo.processInfo.environment["RESET_APP_SETTINGS"].map(Bool.init) == true {
            AppSettings.resetAllSettings()
        }
        
        self.appDelegate = appDelegate
        self.appSettings = appSettings
        self.appHooks = appHooks
        appRouteURLParser = AppRouteURLParser(appSettings: appSettings)
        
        elementCallService = ElementCallService()
        
        navigationRootCoordinator = NavigationRootCoordinator()
        
        stateMachine = AppCoordinatorStateMachine()
                
        navigationRootCoordinator.setRootCoordinator(SplashScreenCoordinator())

        let keychainController = KeychainController(service: .sessions,
                                                    accessGroup: InfoPlistReader.main.keychainAccessGroupIdentifier)
        userSessionStore = UserSessionStore(keychainController: keychainController, appSettings: appSettings, appHooks: appHooks, networkMonitor: networkMonitor)
        
        let appLockService = AppLockService(keychainController: keychainController, appSettings: appSettings)
        let appLockNavigationCoordinator = NavigationRootCoordinator()
        appLockFlowCoordinator = AppLockFlowCoordinator(appLockService: appLockService,
                                                        navigationCoordinator: appLockNavigationCoordinator)
        
        notificationManager = NotificationManager(notificationCenter: UNUserNotificationCenter.current(),
                                                  appSettings: appSettings)
        
        Self.setupServiceLocator(appSettings: appSettings, appHooks: appHooks)
        Self.setupSentry(appSettings: appSettings)
        
        ServiceLocator.shared.analytics.signpost.start()
        ServiceLocator.shared.analytics.startIfEnabled()
        
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
        
        appSettings.$analyticsConsentState
            .dropFirst() // Called above before configuring the ServiceLocator
            .sink { _ in
                Self.setupSentry(appSettings: appSettings)
            }
            .store(in: &cancellables)
        
        elementCallService.actions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                switch action {
                case .startCall(let roomID):
                    self?.handleAppRoute(.call(roomID: roomID))
                default:
                    break
                }
            }
            .store(in: &cancellables)
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
        
        stateMachine.processEvent(.startWithExistingSession)
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
    
    func handleDeepLink(_ url: URL, isExternalURL: Bool) -> Bool {
        // Parse into an AppRoute to redirect these in a type safe way.
        
        if let route = appRouteURLParser.route(from: url) {
            switch route {
            case .oidcCallback(let url):
                if stateMachine.state == .softLogout {
                    softLogoutCoordinator?.handleOIDCRedirectURL(url)
                } else {
                    authenticationFlowCoordinator?.handleOIDCRedirectURL(url)
                }
            case .genericCallLink(let url):
                if let userSessionFlowCoordinator {
                    userSessionFlowCoordinator.handleAppRoute(route, animated: true)
                } else {
                    presentCallScreen(genericCallLink: url)
                }
            case .userProfile(let userID):
                if isExternalURL {
                    handleAppRoute(route)
                } else {
                    handleAppRoute(.roomMemberDetails(userID: userID))
                }
            case .room(let roomID, let via):
                if isExternalURL {
                    handleAppRoute(route)
                } else {
                    handleAppRoute(.childRoom(roomID: roomID, via: via))
                }
            case .roomAlias(let alias):
                if isExternalURL {
                    handleAppRoute(route)
                } else {
                    handleAppRoute(.childRoomAlias(alias))
                }
            case .event(let eventID, let roomID, let via):
                if isExternalURL {
                    handleAppRoute(route)
                } else {
                    handleAppRoute(.childEvent(eventID: eventID, roomID: roomID, via: via))
                }
            case .eventOnRoomAlias(let eventID, let alias):
                if isExternalURL {
                    handleAppRoute(route)
                } else {
                    handleAppRoute(.childEventOnRoomAlias(eventID: eventID, alias: alias))
                }
            default:
                break
            }
            
            return true
        }
        
        return false
    }
    
    func handleUserActivity(_ userActivity: NSUserActivity) {
        // `INStartVideoCallIntent` is to be replaced with `INStartCallIntent`
        // but calls from Recents still send it ¯\_(ツ)_/¯
        guard let intent = userActivity.interaction?.intent as? INStartVideoCallIntent,
              let contact = intent.contacts?.first,
              let roomIdentifier = contact.personHandle?.value else {
            MXLog.error("Failed retrieving information from userActivity: \(userActivity)")
            return
        }
        
        MXLog.info("Starting call in room: \(roomIdentifier)")
        handleAppRoute(AppRoute.call(roomID: roomIdentifier))
    }
    
    // MARK: - AuthenticationFlowCoordinatorDelegate
    
    func authenticationFlowCoordinator(didLoginWithSession userSession: UserSessionProtocol) {
        self.userSession = userSession
        authenticationFlowCoordinator = nil
        stateMachine.processEvent(.createdUserSession)
    }
    
    // MARK: - WindowManagerDelegate
    
    func windowManagerDidConfigureWindows(_ windowManager: SecureWindowManagerProtocol) {
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
        
        if content.categoryIdentifier == NotificationConstants.Category.invite {
            if let userSession {
                userSession.clientProxy.roomsToAwait.insert(roomID)
            } else {
                storedRoomsToAwait.insert(roomID)
            }
        }
        
        handleAppRoute(.room(roomID: roomID, via: []))
    }
    
    func handleInlineReply(_ service: NotificationManagerProtocol, content: UNNotificationContent, replyText: String) async {
        guard let userSession else {
            fatalError("User session not setup")
        }
        
        MXLog.info("[AppCoordinator] handle notification reply")
        
        guard let roomID = content.userInfo[NotificationConstants.UserInfoKey.roomIdentifier] as? String else {
            return
        }
        
        guard case let .joined(roomProxy) = await userSession.clientProxy.roomForIdentifier(roomID) else {
            MXLog.error("Tried to reply in an unjoined room: \(roomID)")
            return
        }
        
        switch await roomProxy.timeline.sendMessage(replyText,
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
    
    private static func setupServiceLocator(appSettings: AppSettings, appHooks: AppHooks) {
        ServiceLocator.shared.register(userIndicatorController: UserIndicatorController())
        ServiceLocator.shared.register(appSettings: appSettings)
        ServiceLocator.shared.register(bugReportService: BugReportService(withBaseURL: appSettings.bugReportServiceBaseURL,
                                                                          applicationId: appSettings.bugReportApplicationId,
                                                                          sdkGitSHA: sdkGitSha(),
                                                                          maxUploadSize: appSettings.bugReportMaxUploadSize,
                                                                          appHooks: appHooks))
        let posthogAnalyticsClient = PostHogAnalyticsClient()
        posthogAnalyticsClient.updateSuperProperties(AnalyticsEvent.SuperProperties(appPlatform: .EXI, cryptoSDK: .Rust, cryptoSDKVersion: sdkGitSha()))
        ServiceLocator.shared.register(analytics: AnalyticsService(client: posthogAnalyticsClient,
                                                                   appSettings: appSettings))
    }
    
    /// Perform any required migrations for the app to function correctly.
    private func performMigrationsIfNecessary(from oldVersion: Version, to newVersion: Version) {
        guard oldVersion != newVersion else { return }
        
        MXLog.info("The app was upgraded from \(oldVersion) to \(newVersion)")
        
        if oldVersion < Version(1, 6, 0) {
            MXLog.info("Migrating to v1.6.0, marking identity confirmation onboarding as ran.")
            if !userSessionStore.userIDs.isEmpty {
                appSettings.hasRunIdentityConfirmationOnboarding = true
                appSettings.hasRunNotificationPermissionsOnboarding = true
            }
        }
        
        if oldVersion < Version(1, 6, 7) {
            RustTracing.deleteLogFiles()
            MXLog.info("Migrating to v1.6.7, log files have been wiped")
        }
    }
    
    /// Clears the keychain, app support directory etc ready for a fresh use.
    /// - Parameter includingSettings: Whether to additionally wipe the user's app settings too.
    private func wipeUserData(includingSettings: Bool = false) {
        if includingSettings {
            AppSettings.resetAllSettings()
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
                setupUserSession(isNewLogin: true)
            case (.initial, .startWithExistingSession, .restoringSession):
                restoreUserSession()
            case (.restoringSession, .failedRestoringSession, .signedOut):
                showLoginErrorToast()
                presentSplashScreen()
            case (.restoringSession, .createdUserSession, .signedIn):
                setupUserSession(isNewLogin: false)
                        
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
        let encryptionKeyProvider = EncryptionKeyProvider()
        let authenticationService = AuthenticationService(userSessionStore: userSessionStore,
                                                          encryptionKeyProvider: encryptionKeyProvider,
                                                          appSettings: appSettings,
                                                          appHooks: appHooks)
        let qrCodeLoginService = QRCodeLoginService(encryptionKeyProvider: encryptionKeyProvider,
                                                    userSessionStore: userSessionStore,
                                                    appSettings: appSettings,
                                                    appHooks: appHooks)
        
        authenticationFlowCoordinator = AuthenticationFlowCoordinator(authenticationService: authenticationService,
                                                                      qrCodeLoginService: qrCodeLoginService,
                                                                      bugReportService: ServiceLocator.shared.bugReportService,
                                                                      navigationRootCoordinator: navigationRootCoordinator,
                                                                      appMediator: appMediator,
                                                                      appSettings: appSettings,
                                                                      analytics: ServiceLocator.shared.analytics,
                                                                      userIndicatorController: ServiceLocator.shared.userIndicatorController)
        authenticationFlowCoordinator?.delegate = self
        
        authenticationFlowCoordinator?.start()
    }

    private func startAuthenticationSoftLogout() {
        guard let userSession else {
            fatalError("User session not setup")
        }
        
        Task {
            let credentials = SoftLogoutScreenCredentials(userID: userSession.clientProxy.userID,
                                                          homeserverName: userSession.clientProxy.homeserver,
                                                          userDisplayName: userSession.clientProxy.userDisplayNamePublisher.value ?? "",
                                                          deviceID: userSession.clientProxy.deviceID)
            
            let authenticationService = AuthenticationService(userSessionStore: userSessionStore,
                                                              encryptionKeyProvider: EncryptionKeyProvider(),
                                                              appSettings: appSettings,
                                                              appHooks: appHooks)
            _ = await authenticationService.configure(for: userSession.clientProxy.homeserver)
            
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
    
    private func setupUserSession(isNewLogin: Bool) {
        guard let userSession else {
            fatalError("User session not setup")
        }
        
        let userSessionFlowCoordinator = UserSessionFlowCoordinator(userSession: userSession,
                                                                    navigationRootCoordinator: navigationRootCoordinator,
                                                                    appLockService: appLockFlowCoordinator.appLockService,
                                                                    bugReportService: ServiceLocator.shared.bugReportService,
                                                                    elementCallService: elementCallService,
                                                                    roomTimelineControllerFactory: RoomTimelineControllerFactory(),
                                                                    appMediator: appMediator,
                                                                    appSettings: appSettings,
                                                                    appHooks: appHooks,
                                                                    analytics: ServiceLocator.shared.analytics,
                                                                    notificationManager: notificationManager,
                                                                    isNewLogin: isNewLogin)
        
        userSessionFlowCoordinator.actionsPublisher
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

        if let storedAppRoute {
            userSessionFlowCoordinator.handleAppRoute(storedAppRoute, animated: false)
        }
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
            
            AppSettings.resetSessionSpecificSettings()
            
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
    
    private func configureElementCallService() {
        guard let userSession else {
            fatalError("User session not setup")
        }
        
        elementCallService.setClientProxy(userSession.clientProxy)
    }
    
    private func presentCallScreen(genericCallLink url: URL) {
        let configuration = ElementCallConfiguration(genericCallLink: url)
        
        let callScreenCoordinator = CallScreenCoordinator(parameters: .init(elementCallService: elementCallService,
                                                                            configuration: configuration,
                                                                            allowPictureInPicture: false,
                                                                            appHooks: appHooks))
        
        callScreenCoordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .pictureInPictureIsAvailable:
                    break
                case .pictureInPictureStarted, .pictureInPictureStopped:
                    // Don't allow PiP when signed out - the user could login at which point we'd
                    // need to hand over the call from here to the user session flow coordinator.
                    MXLog.error("Picture in Picture not supported before login.")
                case .dismiss:
                    navigationRootCoordinator.setOverlayCoordinator(nil)
                }
            }
            .store(in: &cancellables)
        
        navigationRootCoordinator.setOverlayCoordinator(callScreenCoordinator, animated: false)
    }

    private func configureNotificationManager() {
        notificationManager.setUserSession(userSession)

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
        appMediator.networkMonitor
            .reachabilityPublisher
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
            userSessionFlowCoordinator.handleAppRoute(appRoute, animated: appMediator.appState == .active)
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
        
        let userID = userSession.clientProxy.userID
        tearDownUserSession()
    
        // Allow for everything to deallocate properly
        Task {
            try? await Task.sleep(for: .seconds(2))
            userSessionStore.clearCache(for: userID)
            stateMachine.processEvent(.startWithExistingSession)
            hideLoadingIndicator()
        }
    }
    
    private static func setupSentry(appSettings: AppSettings) {
        let options: Options = .init()
        
        #if DEBUG
        options.enabled = false
        #else
        options.enabled = appSettings.analyticsConsentState == .optedIn
        #endif

        options.dsn = appSettings.bugReportSentryURL.absoluteString
        
        if AppSettings.isDevelopmentBuild {
            options.environment = "development"
        }
        
        // Sentry swizzling shows up quite often as the heaviest stack trace when profiling
        // We don't need any of the features it powers (see docs)
        options.enableSwizzling = false
        
        // WatchdogTermination is currently the top issue but we've had zero complaints
        // so it might very well just all be false positives
        options.enableWatchdogTerminationTracking = false
        
        // Disabled as it seems to report a lot of false positives
        options.enableAppHangTracking = false
        
        // Most of the network requests are made Rust side, this is useless
        options.enableNetworkBreadcrumbs = false
        
        // Doesn't seem to work at all well with SwiftUI
        options.enableAutoBreadcrumbTracking = false
        
        // Experimental. Stitches stack traces of asynchronous code together
        options.swiftAsyncStacktraces = true
        
        // Uniform sample rate: 1.0 captures 100% of transactions
        // In Production you will probably want a smaller number such as 0.5 for 50%
        if AppSettings.isDevelopmentBuild {
            options.sampleRate = 1.0
            options.tracesSampleRate = 1.0
            options.profilesSampleRate = 1.0
        } else {
            options.sampleRate = 0.5
            options.tracesSampleRate = 0.5
            options.profilesSampleRate = 0.5
        }

        // This callback is only executed once during the entire run of the program to avoid
        // multiple callbacks if there are multiple crash events to send (see method documentation)
        options.onCrashedLastRun = { event in
            MXLog.error("Sentry detected a crash in the previous run: \(event.eventId.sentryIdString)")
            ServiceLocator.shared.bugReportService.lastCrashEventID = event.eventId.sentryIdString
        }
        
        SentrySDK.start(options: options)
        
        MXLog.info("SentrySDK started")
    }
    
    private func teardownSentry() {
        SentrySDK.close()
        MXLog.info("SentrySDK stopped")
    }
           
    // MARK: Toasts and loading indicators
    
    private static let loadingIndicatorIdentifier = "\(AppCoordinator.self)-Loading"
    
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
        
        let serverName = String(userSession.clientProxy.userIDServerName ?? "Unknown")
        
        ServiceLocator.shared.analytics.signpost.beginFirstSync(serverName: serverName)
        userSession.clientProxy.startSync()
        
        guard clientProxyObserver == nil else {
            return
        }
        
        clientProxyObserver = userSession.clientProxy
            .loadingStatePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                let toastIdentifier = "StaleDataIndicator"
                
                switch state {
                case .loading:
                    if self?.appMediator.networkMonitor.reachabilityPublisher.value == .reachable {
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
        
        backgroundTask = appMediator.beginBackgroundTask { [weak self] in
            guard let self else { return }
            
            stopSync()
            
            if let backgroundTask {
                appMediator.endBackgroundTask(backgroundTask)
                self.backgroundTask = nil
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
        
        if let backgroundTask {
            appMediator.endBackgroundTask(backgroundTask)
            self.backgroundTask = nil
        }

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
            .actionsPublisher
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
