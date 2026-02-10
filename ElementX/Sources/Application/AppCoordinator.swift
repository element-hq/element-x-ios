//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
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
    private let targetConfiguration: Target.ConfigurationResult
    private let appMediator: AppMediator
    private let appSettings: AppSettings
    private let appDelegate: AppDelegate
    private let appHooks: AppHooks
    private let bugReportService: BugReportServiceProtocol
    private let elementCallService: ElementCallServiceProtocol

    /// Common background task to continue long-running tasks in the background.
    private var backgroundTask: UIBackgroundTaskIdentifier?
    
    private var userSessionMigrationsOldVersion: Version?
    private var userSession: UserSessionProtocol? {
        didSet {
            userSessionObserver?.cancel()
            if let userSession {
                configureElementCallService()
                configureNotificationManager()
                observeUserSessionChanges()
                startSync()
                Task { await appHooks.configure(with: userSession) }
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
    
    private var storedAppRoute: AppRoute?
    @Consumable private var storedInlineReply: (roomID: String, message: String)?
    @Consumable private var storedRoomsToAwait: Set<String>?

    init(appDelegate: AppDelegate) {
        let appHooks = AppHooks()
        appHooks.setUp()
        
        // Override colours before we start building any UI components.
        appHooks.compoundHook.override(colors: Color.compound, uiColors: UIColor.compound)
        
        windowManager = WindowManager(appDelegate: appDelegate)
        let networkMonitor = NetworkMonitor()
        appMediator = AppMediator(windowManager: windowManager, networkMonitor: networkMonitor)
        
        let appSettings = appHooks.appSettingsHook.configure(AppSettings())
        ServiceLocator.shared.register(appSettings: appSettings)
        
        targetConfiguration = Target.mainApp.configure(logLevel: appSettings.logLevel,
                                                       traceLogPacks: appSettings.traceLogPacks,
                                                       sentryURL: appSettings.bugReportSentryRustURL,
                                                       rageshakeURL: appSettings.bugReportRageshakeURL,
                                                       appHooks: appHooks)
        
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
        
        ServiceLocator.shared.register(userIndicatorController: UserIndicatorController())
        
        let posthogAnalyticsClient = PostHogAnalyticsClient()
        posthogAnalyticsClient.updateSuperProperties(AnalyticsEvent.SuperProperties(appPlatform: .EXI, cryptoSDK: .Rust, cryptoSDKVersion: sdkGitSha()))
        let analyticsService = AnalyticsService(client: posthogAnalyticsClient, appSettings: appSettings)
        ServiceLocator.shared.register(analytics: analyticsService)
        
        elementCallService = ElementCallService()
        
        navigationRootCoordinator = NavigationRootCoordinator()
        
        stateMachine = AppCoordinatorStateMachine()
                
        navigationRootCoordinator.setRootCoordinator(SplashScreenCoordinator())

        let keychainController = KeychainController(service: .sessions,
                                                    accessGroup: InfoPlistReader.main.keychainAccessGroupIdentifier)
        userSessionStore = UserSessionStore(keychainController: keychainController,
                                            appSettings: appSettings,
                                            analyticsService: analyticsService,
                                            appHooks: appHooks,
                                            networkMonitor: networkMonitor)
        
        let appLockService = AppLockService(keychainController: keychainController, appSettings: appSettings)
        let appLockNavigationCoordinator = NavigationRootCoordinator()
        appLockFlowCoordinator = AppLockFlowCoordinator(appLockService: appLockService,
                                                        navigationCoordinator: appLockNavigationCoordinator,
                                                        appSettings: appSettings)
        
        notificationManager = NotificationManager(notificationCenter: UNUserNotificationCenter.current(),
                                                  appSettings: appSettings)
        
        bugReportService = BugReportService(rageshakeURLPublisher: appSettings.bugReportRageshakeURL.publisher,
                                            applicationID: appSettings.bugReportApplicationID,
                                            sdkGitSHA: sdkGitSha(),
                                            maxUploadSize: appSettings.bugReportMaxUploadSize,
                                            appHooks: appHooks)
        
        Self.setupSentry(bugReportService: bugReportService, appSettings: appSettings)
        
        analyticsService.startIfEnabled()
        
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
        observeAppLockChanges()
        
        registerBackgroundAppRefresh()
        
        appSettings.$analyticsConsentState
            .dropFirst() // Called above before configuring the ServiceLocator
            .sink { [bugReportService] _ in
                Self.setupSentry(bugReportService: bugReportService, appSettings: appSettings)
            }
            .store(in: &cancellables)
        
        elementCallService.actions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                switch action {
                case .startCall(let roomID):
                    self?.handleAppRoute(.call(roomID: roomID))
                case .receivedIncomingCallRequest:
                    // When reporting a VoIP call through the CXProvider's `reportNewIncomingVoIPPushPayload`
                    // the UIApplication states don't change and syncing is neither started nor ran on
                    // a background task. Handle both manually here.
                    self?.startSync()
                    self?.scheduleDelayedSyncStop()
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
        AnyView(navigationRootCoordinator.toPresentable()
            .environment(\.analyticsService, ServiceLocator.shared.analytics)
            .onReceive(appSettings.$appAppearance) { [weak self] appAppearance in
                guard let self else { return }
                    
                windowManager.windows.forEach { window in
                    // Unfortunately .preferredColorScheme doesn't propagate properly throughout the app when changed
                    window.overrideUserInterfaceStyle = appAppearance.interfaceStyle
                }
            })
    }
    
    func handlePotentialPhishingAttempt(url: URL, openURLAction: @escaping (URL) -> Void) -> Bool {
        guard let confirmationParameters = url.confirmationParameters else {
            return false
        }
        navigationRootCoordinator.alertInfo = .init(id: .init(),
                                                    title: L10n.dialogConfirmLinkTitle,
                                                    message: L10n.dialogConfirmLinkMessage(confirmationParameters.displayString,
                                                                                           confirmationParameters.internalURL.absoluteString),
                                                    primaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil),
                                                    secondaryButton: .init(title: L10n.actionContinue) { openURLAction(confirmationParameters.internalURL) })
        return true
    }

    func handleDeepLink(_ url: URL, isExternalURL: Bool) -> Bool {
        // Parse into an AppRoute to redirect these in a type safe way.
        
        if let route = appRouteURLParser.route(from: url) {
            switch route {
            case .accountProvisioningLink:
                handleAppRoute(route)
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
            case .share(let payload):
                guard isExternalURL else {
                    MXLog.error("Received unexpected internal share route")
                    break
                }
                
                do {
                    try handleAppRoute(.share(payload.withDefaultTemporaryDirectory()))
                } catch {
                    MXLog.error("Failed moving payload out of the app group container: \(error)")
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
        MXLog.info("Tapped Notification")
        
        guard let roomID = content.roomID,
              content.receiverID != nil else {
            return
        }
        
        let eventID = appSettings.focusEventOnNotificationTap ? content.eventID : nil
        if content.categoryIdentifier == NotificationConstants.Category.invite {
            if let userSession {
                userSession.clientProxy.roomsToAwait.insert(roomID)
            } else {
                storedRoomsToAwait = [roomID]
            }
            handleAppRoute(.room(roomID: roomID, via: []))
        } else if appSettings.threadsEnabled, let threadRootEventID = content.threadRootEventID {
            handleAppRoute(.thread(roomID: roomID, threadRootEventID: threadRootEventID, focusEventID: eventID))
        } else if let eventID {
            // Only track main timeline event deeplinking
            ServiceLocator.shared.analytics.signpost.startTransaction(.notificationToMessage)
            handleAppRoute(.event(eventID: eventID, roomID: roomID, via: []))
        } else {
            handleAppRoute(.room(roomID: roomID, via: []))
        }
    }
    
    func handleInlineReply(_ service: NotificationManagerProtocol, content: UNNotificationContent, replyText: String) async {
        MXLog.info("Handle notification reply")
        
        guard let roomID = content.roomID else {
            return
        }
        
        if userSession == nil {
            // Store the data so it can be used after the session is established
            storedInlineReply = (roomID, replyText)
            return
        }
        
        await processInlineReply(roomID: roomID, replyText: replyText)
    }
    
    // MARK: - Private
    
    /// Perform any required migrations for the app to function correctly.
    private func performMigrationsIfNecessary(from oldVersion: Version, to newVersion: Version) {
        guard oldVersion != newVersion else { return }
        
        // Be tidy and clean up after ourselves every now and then (because Apple is lazy)
        clearTemporaryDirectories()
        
        MXLog.info("The app was upgraded from \(oldVersion) to \(newVersion)")
        
        if oldVersion < Version(1, 6, 0) {
            MXLog.info("Migrating to v1.6.0, marking identity confirmation onboarding as ran.")
            if !userSessionStore.userIDs.isEmpty {
                appSettings.hasRunIdentityConfirmationOnboarding = true
                appSettings.hasRunNotificationPermissionsOnboarding = true
            }
        }
        
        if oldVersion < Version(1, 6, 7) {
            Tracing.deleteLogFiles(in: Tracing.legacyLogsDirectory)
            MXLog.info("Migrating to v1.6.7, log files have been wiped")
        }
        
        if oldVersion < Version(25, 7, 4) {
            Tracing.migrateLogFiles()
            MXLog.info("Migrating to version 25.07.4, log files have been moved.")
        }
        
        // Store the old version to run additional migrations on the user session once it has been set up.
        userSessionMigrationsOldVersion = oldVersion
    }
    
    private func performUserSessionMigrations(_ userSession: UserSessionProtocol) async {
        guard let oldVersion = userSessionMigrationsOldVersion else { return }
        
        MXLog.info("Migrating user session from \(oldVersion)")
        
        MXLog.info("Performing client store optimizations.")
        await userSession.clientProxy.optimizeStores()
        MXLog.info("Finished optimizing client stores.")
        
        if oldVersion < Version(25, 6, 0) {
            MXLog.info("Migrating to version 25.06.0, migrating timeline media settings to account data.")
            performSettingsToAccountDataMigration(userSession: userSession)
        }
        
        if oldVersion < Version(25, 9, 2) {
            MXLog.info("Migrating to version 25.09.2, triggering sync to ensure m.space state is up to date.")
            await userSession.clientProxy.expireSyncSessions()
        }
        
        if oldVersion < Version(25, 10, 0) {
            MXLog.info("Migrating to version 25.10.0, showing new sound banner to existing user.")
            appSettings.hasSeenNewSoundBanner = false
        }
        
        userSessionMigrationsOldVersion = nil
    }
    
    /// This could be removed once the adoption of 25.06.x is widespread.
    private func performSettingsToAccountDataMigration(userSession: UserSessionProtocol) {
        guard let userDefaults = UserDefaults(suiteName: InfoPlistReader.main.appGroupIdentifier) else {
            return
        }
        
        let hideInviteAvatars = userDefaults.value(forKey: "hideInviteAvatars") as? Bool
        let timelineMediaVisibility = userDefaults
            .data(forKey: "timelineMediaVisibility")
            .flatMap {
                try? JSONDecoder().decode(TimelineMediaVisibility.self, from: $0)
            }
        let hideTimelineMedia = userDefaults.value(forKey: "hideTimelineMedia") as? Bool
        
        guard hideInviteAvatars != nil || timelineMediaVisibility != nil || hideTimelineMedia != nil else {
            // No migration needed, no local settings found.
            return
        }
        
        Task {
            switch await userSession.clientProxy.fetchMediaPreviewConfiguration() {
            case let .success(config):
                guard config == nil else {
                    // Found a server configuration, no need to migrate.
                    userDefaults.removeObject(forKey: "hideInviteAvatars")
                    userDefaults.removeObject(forKey: "timelineMediaVisibility")
                    userDefaults.removeObject(forKey: "hideTimelineMedia")
                    return
                }
                
                if let hideInviteAvatars, case .success = await userSession.clientProxy.setHideInviteAvatars(hideInviteAvatars) {
                    userDefaults.removeObject(forKey: "hideInviteAvatars")
                }
                
                if let timelineMediaVisibility, case .success = await userSession.clientProxy.setTimelineMediaVisibility(timelineMediaVisibility) {
                    userDefaults.removeObject(forKey: "timelineMediaVisibility")
                } else if let hideTimelineMedia, case .success = await userSession.clientProxy.setTimelineMediaVisibility(hideTimelineMedia ? .never : .always) {
                    userDefaults.removeObject(forKey: "hideTimelineMedia")
                }
            case let .failure(error):
                MXLog.error("Could not perform migration, failed to fetch media preview config: \(error)")
                return
            }
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
    
    /// Manually cleans up any files in the app group's `tmp` directory.
    ///
    /// **Note:** If there is a single file we consider it to be an active share payload and ignore it.
    private func clearTemporaryDirectories() {
        // First get rid of everything in the App's temporary directory
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: URL.temporaryDirectory, includingPropertiesForKeys: nil, options: [])
            
            fileURLs.forEach { url in
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                    MXLog.warning("Failed to remove file from temporary directory: \(error)")
                }
            }
        } catch {
            MXLog.warning("Failed to enumerate temporary directory: \(error)")
        }
        
        // Manual clean to handle the potential case where the app crashes before moving a shared file.
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: URL.appGroupTemporaryDirectory, includingPropertiesForKeys: nil, options: [])
            
            guard fileURLs.count > 1 else {
                return // If there is only a single item in here, there's likely a pending share payload that is yet to be processed.
            }
            
            for url in fileURLs {
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                    MXLog.warning("Failed to remove file from app group temporary directory: \(error)")
                }
            }
        } catch {
            MXLog.warning("Failed to enumerate app group temporary directory: \(error)")
        }
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
                await self.performUserSessionMigrations(userSession)
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
        
        let coordinator = AuthenticationFlowCoordinator(authenticationService: authenticationService,
                                                        bugReportService: bugReportService,
                                                        navigationRootCoordinator: navigationRootCoordinator,
                                                        appMediator: appMediator,
                                                        appSettings: appSettings,
                                                        analytics: ServiceLocator.shared.analytics,
                                                        userIndicatorController: ServiceLocator.shared.userIndicatorController)
        coordinator.delegate = self
        
        authenticationFlowCoordinator = coordinator
        coordinator.start()
        
        if storedAppRoute?.isAuthenticationRoute == true,
           let storedAppRoute = storedAppRoute.take() {
            coordinator.handleAppRoute(storedAppRoute, animated: false)
        }
    }
    
    private func runPostSessionSetupTasks() async {
        guard let userSession, let userSessionFlowCoordinator else {
            fatalError("User session not setup")
        }
        
        if let storedRoomsToAwait {
            userSession.clientProxy.roomsToAwait = storedRoomsToAwait
        }
        
        if storedAppRoute?.isAuthenticationRoute == false,
           let storedAppRoute = storedAppRoute.take() {
            userSessionFlowCoordinator.handleAppRoute(storedAppRoute, animated: false)
        }
        
        if let storedInlineReply {
            await processInlineReply(roomID: storedInlineReply.roomID, replyText: storedInlineReply.message)
        }
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
            _ = await authenticationService.configure(for: userSession.clientProxy.homeserver, flow: .login)
            
            let parameters = SoftLogoutScreenCoordinatorParameters(authenticationService: authenticationService,
                                                                   credentials: credentials,
                                                                   keyBackupNeeded: false,
                                                                   appSettings: appSettings,
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
        
        if let serverName = userSession.clientProxy.userIDServerName {
            ServiceLocator.shared.analytics.signpost.addGlobalTag(.homeserver, value: serverName)
        }
        
        if !isNewLogin {
            ServiceLocator.shared.analytics.signpost.startTransaction(.cachedRoomList)
        }
        
        let flowParameters = CommonFlowParameters(userSession: userSession,
                                                  bugReportService: bugReportService,
                                                  elementCallService: elementCallService,
                                                  timelineControllerFactory: TimelineControllerFactory(),
                                                  emojiProvider: EmojiProvider(appSettings: appSettings),
                                                  linkMetadataProvider: LinkMetadataProvider(),
                                                  appMediator: appMediator,
                                                  appSettings: appSettings,
                                                  appHooks: appHooks,
                                                  analytics: ServiceLocator.shared.analytics,
                                                  userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                  notificationManager: notificationManager,
                                                  stateMachineFactory: StateMachineFactory())
        
        let userSessionFlowCoordinator = UserSessionFlowCoordinator(isNewLogin: isNewLogin,
                                                                    navigationRootCoordinator: navigationRootCoordinator,
                                                                    appLockService: appLockFlowCoordinator.appLockService,
                                                                    flowParameters: flowParameters)
        
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
        
        Task {
            await runPostSessionSetupTasks()
        }
    }
        
    private func logout(isSoft: Bool) {
        guard let userSession else {
            fatalError("User session not setup")
        }
        
        showLoadingIndicator()
        
        stopSync(isBackgroundTask: false)
        userSessionFlowCoordinator?.stop()
        
        guard !isSoft else {
            stateMachine.processEvent(.showSoftLogout)
            hideLoadingIndicator()
            return
        }
        
        // The user will log out, clear any existing notifications and unregister from receving new ones
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().setBadgeCount(0)
        
        unregisterForRemoteNotifications()
        
        Task {
            // First log out from the server
            await userSession.clientProxy.logout()
            
            // Regardless of the result, clear user data
            userSessionStore.logout(userSession: userSession)
            tearDownUserSession()
            
            AppSettings.resetSessionSpecificSettings()
            appHooks.remoteSettingsHook.reset(appSettings)
            
            // Reset analytics
            ServiceLocator.shared.analytics.optOut()
            ServiceLocator.shared.analytics.resetConsentState()
            
            stateMachine.processEvent(.completedSigningOut)
                       
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
                                                                            appSettings: appSettings,
                                                                            appHooks: appHooks,
                                                                            analytics: ServiceLocator.shared.analytics))
        
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
        var handled = false
        
        switch appRoute {
        case .accountProvisioningLink:
            if let authenticationFlowCoordinator {
                authenticationFlowCoordinator.handleAppRoute(appRoute, animated: appMediator.appState == .active)
                handled = true
            }
        default:
            if let userSessionFlowCoordinator {
                userSessionFlowCoordinator.handleAppRoute(appRoute, animated: appMediator.appState == .active)
                handled = true
            }
        }
        
        if !handled {
            storedAppRoute = appRoute
        }
    }
    
    private func clearCache() {
        guard let userSession else {
            fatalError("User session not setup")
        }
        
        showLoadingIndicator()
        
        navigationRootCoordinator.setRootCoordinator(PlaceholderScreenCoordinator(hideBrandChrome: appSettings.hideBrandChrome))
        
        stopSync(isBackgroundTask: false)
        userSessionFlowCoordinator?.stop()
        
        tearDownUserSession()
    
        // Allow for everything to deallocate properly
        Task {
            try? await Task.sleep(for: .seconds(2))
            await userSession.clientProxy.clearCaches()
            stateMachine.processEvent(.startWithExistingSession)
            hideLoadingIndicator()
        }
    }
    
    private static func setupSentry(bugReportService: BugReportServiceProtocol, appSettings: AppSettings) {
        guard let bugReportSentryURL = appSettings.bugReportSentryURL else { return }
        
        let options: Options = .init()
        
        #if DEBUG
        options.enabled = false
        #else
        options.enabled = appSettings.analyticsConsentState == .optedIn
        #endif

        options.dsn = bugReportSentryURL.absoluteString
        
        // Matches android, at least for now.
        switch AppSettings.appBuildType {
        case .debug:
            options.environment = "DEBUG"
        case .nightly:
            options.environment = "NIGHTLY"
        case .release:
            options.environment = "RELEASE"
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
        options.sampleRate = 1.0
        options.tracesSampleRate = 1.0
        options.configureProfiling = { $0.sessionSampleRate = 1.0 }

        // This callback is only executed once during the entire run of the program to avoid
        // multiple callbacks if there are multiple crash events to send (see method documentation)
        options.onCrashedLastRun = { event in
            MXLog.error("Sentry detected a crash in the previous run: \(event.eventId.sentryIdString)")
            bugReportService.lastCrashEventID = event.eventId.sentryIdString
        }
        
        SentrySDK.start(options: options) // Swift
        enableSentryLogging(enabled: options.enabled) // Rust
        
        MXLog.info("Sentry configured (enabled: \(options.enabled))")
    }
    
    private func teardownSentry() {
        SentrySDK.close()
        MXLog.info("SentrySDK stopped")
    }
    
    private func processInlineReply(roomID: String, replyText: String) async {
        guard let userSession else {
            fatalError("User session not setup")
        }
        
        guard case let .joined(roomProxy) = await userSession.clientProxy.roomForIdentifier(roomID) else {
            MXLog.error("Tried to reply in an unjoined room: \(roomID)")
            return
        }
        
        switch await roomProxy.timeline.sendMessage(replyText,
                                                    html: nil,
                                                    inReplyToEventID: nil,
                                                    intentionalMentions: .empty) {
        case .success:
            break
        default:
            await notificationManager.showLocalNotification(with: "⚠️ " + L10n.commonError,
                                                            subtitle: L10n.errorSomeMessagesHaveNotBeenSent)
        }
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

    private func stopSync(isBackgroundTask: Bool, completion: (() -> Void)? = nil) {
        if isBackgroundTask, UIApplication.shared.applicationState == .active {
            // Attempt to stop the background task sync loop cleanly, only if the app not already running
            return
        }
        
        MainActor.assumeIsolated {
            userSession?.clientProxy.stopSync(completion: completion)
            clientProxyObserver = nil
        }
    }

    private func startSync() {
        guard let userSession else { return }
        
        ServiceLocator.shared.analytics.signpost.startTransaction(.upToDateRoomList)
    
        userSession.clientProxy.startSync()
        
        guard clientProxyObserver == nil else {
            return
        }
        
        clientProxyObserver = userSession.clientProxy
            .loadingStatePublisher
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                let toastIdentifier = "StaleDataIndicator"
                
                switch state {
                case .loading:
                    if self?.userSession?.clientProxy.homeserverReachabilityPublisher.value == .reachable,
                       self?.appMediator.networkMonitor.reachabilityPublisher.value == .reachable {
                        ServiceLocator.shared.userIndicatorController.submitIndicator(.init(id: toastIdentifier, type: .toast(progress: .indeterminate), title: L10n.commonSyncing, persistent: true))
                    }
                case .notLoading:
                    ServiceLocator.shared.analytics.signpost.finishTransaction(.upToDateRoomList)
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
        stopSync(isBackgroundTask: false)
    }

    @objc
    private func applicationWillResignActive() {
        MXLog.info("Application will resign active")

        scheduleDelayedSyncStop()
        scheduleBackgroundAppRefresh()
    }
    
    private func scheduleDelayedSyncStop() {
        guard backgroundTask == nil else {
            return
        }
        
        backgroundTask = appMediator.beginBackgroundTask {
            MXLog.info("Background task is about to expire.")
            
            // We're intentionally strongly retaining self here to an EXC_BAD_ACCESS
            // `backgroundTask` will be eventually released in `endActiveBackgroundTask`
            // https://sentry.tools.element.io/organizations/element/issues/4477794/events/9cfd04e4d045440f87498809cf718de5/
            self.stopSync(isBackgroundTask: true) {
                self.endActiveBackgroundTask()
            }
        }
    }
    
    @objc
    private func applicationDidBecomeActive() {
        MXLog.info("Application did become active")
        endActiveBackgroundTask()
        startSync()
    }
    
    private func endActiveBackgroundTask() {
        guard let backgroundTask else {
            return
        }
        
        MXLog.info("Ending background task.")
        appMediator.endBackgroundTask(backgroundTask)
        self.backgroundTask = nil
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
        
        // We have a lot of crashes stemming here which we previously believed are caused by stopSync not being async
        // on the client proxy side (see the comment on that method). We have now realised that will likely not fix anything but
        // we also noticed this does not crash on the main thread, even though the whole AppCoordinator is on the Main actor.
        // As such, we introduced a MainActor conformance on the expirationHandler but we are also assuming main actor
        // isolated in the `stopSync` method above.
        // https://sentry.tools.element.io/organizations/element/issues/4477794/
        task.expirationHandler = { @Sendable [weak self] in
            MXLog.info("Background app refresh task is about to expire.")
            
            Task { @MainActor in
                self?.stopSync(isBackgroundTask: true) {
                    MXLog.info("Marking Background app refresh task as complete.")
                    task.setTaskCompleted(success: true)
                }
            }
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
            .sink { [weak self] _ in
                guard let self else { return }
                MXLog.info("Background app refresh finished")
                backgroundRefreshSyncObserver?.cancel()
                
                // Make sure we stop the sync loop, otherwise the ongoing request is immediately
                // handled the next time the app refreshes, which can trigger timeout failures.
                stopSync(isBackgroundTask: true) {
                    MXLog.info("Marking Background app refresh task as complete.")
                    task.setTaskCompleted(success: true)
                }
            }
    }
}
