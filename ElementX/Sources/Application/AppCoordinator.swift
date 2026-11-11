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

class AppCoordinator: AppCoordinatorProtocol, NotificationManagerDelegate, SecureWindowManagerDelegate {
    private let stateMachine: AppCoordinatorStateMachine
    private let navigationRootCoordinator: NavigationRootCoordinator
    private let userSessionManager: UserSessionManagerProtocol
    // periphery:ignore - retaining purpose
    private let targetConfiguration: Target.ConfigurationResult
    private let appMediator: AppMediator
    private let appSettings: AppSettings
    private let analyticsService: AnalyticsServiceProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let appDelegate: AppDelegate
    private let appHooks: AppHooks
    private let bugReportService: BugReportServiceProtocol
    private let elementCallManager: ElementCallManagerProtocol
    
    /// Common background task to continue long-running tasks in the background.
    private var backgroundTask: UIBackgroundTaskIdentifier?
    
    private var backgroundRefreshSyncObserver: AnyCancellable?
    
    private var userSession: UserSessionProtocol? {
        userSessionManager.activeSession
    }
    
    private let rootFlowCoordinator: RootFlowCoordinator
    private let appLockFlowCoordinator: AppLockFlowCoordinator
    // periphery:ignore - used to avoid deallocation
    private var appLockSetupFlowCoordinator: AppLockSetupFlowCoordinator?
    
    private var appDelegateObserver: AnyCancellable?
    /// Becomes `true` once the app is no longer waiting on a session restore, whatever the outcome.
    private let isSessionRestoredSubject = CurrentValueSubject<Bool, Never>(false)
    private var cancellables = Set<AnyCancellable>()
    
    let windowManager: SecureWindowManagerProtocol
    let notificationManager: NotificationManagerProtocol
    
    private let appRouteURLParser: AppRouteURLParser
    
    /// A reply made from a notification before its account was live.
    private var storedInlineReply: PendingInlineReplyDetails?
    
    // swiftlint:disable:next function_body_length
    init(appDelegate: AppDelegate) {
        let appHooks = AppHooks()
        appHooks.setUp()
        
        // Override colours before we start building any UI components.
        appHooks.compoundHook.override(colors: Color.compound, uiColors: UIColor.compound)
        
        windowManager = WindowManager(appDelegate: appDelegate)
        let networkMonitor = NetworkMonitor()
        appMediator = AppMediator(windowManager: windowManager, networkMonitor: networkMonitor)
        
        guard let userDefaults = TrackedUserDefaults(suiteName: AppSettings.suiteName) else {
            fatalError("Catastrophic error retrieving user defaults for \(AppSettings.suiteName)")
        }
        let appSettings = appHooks.appSettingsHook.configure(AppSettings(store: userDefaults))
        self.appSettings = appSettings
        
        let keychainController = KeychainController(service: .sessions,
                                                    accessGroup: InfoPlistReader.main.keychainAccessGroupIdentifier)
        
        targetConfiguration = Target.mainApp.configure(logLevel: appSettings.logLevel,
                                                       traceLogPacks: appSettings.traceLogPacks,
                                                       sentryURL: appSettings.bugReportSentryRustURL,
                                                       keychainController: keychainController,
                                                       appHooks: appHooks)
        
        let appName = InfoPlistReader.main.bundleDisplayName
        let appVersion = InfoPlistReader.main.bundleShortVersionString
        let appBuild = InfoPlistReader.main.bundleVersion
        MXLog.info("\(appName) \(appVersion) (\(appBuild))")
        
        guard let currentVersion = Version(appVersion) else {
            fatalError("The app's version number **must** use semver for migration purposes.")
        }
        
        if ProcessInfo.processInfo.environment["RESET_APP_SETTINGS"].map(Bool.init) == true {
            appSettings.resetAllSettings()
        }
        let previousVersion = appSettings.lastVersionLaunched.flatMap(Version.init)
        
        self.appDelegate = appDelegate
        self.appHooks = appHooks
        
        appRouteURLParser = AppRouteURLParser(appSettings: appSettings)
        
        let posthogAnalyticsClient = PostHogAnalyticsClient()
        posthogAnalyticsClient.updateSuperProperties(AnalyticsEvent.SuperProperties(appPlatform: .EXI, cryptoSDK: .Rust, cryptoSDKVersion: sdkGitSha()))
        analyticsService = AnalyticsService(client: posthogAnalyticsClient, appSettings: appSettings)
        
        userIndicatorController = UserIndicatorController()
        
        elementCallManager = ElementCallManager(appSettings: appSettings)
        
        navigationRootCoordinator = NavigationRootCoordinator()
        
        stateMachine = AppCoordinatorStateMachine()
        
        navigationRootCoordinator.setRootCoordinator(SplashScreenCoordinator())
        
        let userSessionStore = UserSessionStore(keychainController: keychainController,
                                                appSettings: appSettings,
                                                analyticsService: analyticsService,
                                                appHooks: appHooks,
                                                networkMonitor: networkMonitor,
                                                targetContext: targetConfiguration.context)
        notificationManager = NotificationManager(notificationCenter: UNUserNotificationCenter.current(), appSettings: appSettings)
        userSessionManager = UserSessionManager(userSessionStore: userSessionStore,
                                                appSettings: appSettings,
                                                notificationManager: notificationManager,
                                                liveLocationManager: LiveLocationManager(appSettings: appSettings),
                                                elementCallManager: elementCallManager,
                                                userSessionMigrator: UserSessionMigrator(newVersion: currentVersion, oldAppVersion: previousVersion, appSettings: appSettings, appMediator: appMediator),
                                                signposter: analyticsService.signpost)
        
        let appLockService = AppLockService(keychainController: keychainController, appSettings: appSettings)
        let appLockNavigationCoordinator = NavigationRootCoordinator()
        appLockFlowCoordinator = AppLockFlowCoordinator(appLockService: appLockService,
                                                        navigationCoordinator: appLockNavigationCoordinator,
                                                        appSettings: appSettings)
        
        bugReportService = BugReportService(applicationID: appSettings.bugReportApplicationID,
                                            sdkGitSHA: sdkGitSha(),
                                            appHooks: appHooks)
        
        rootFlowCoordinator = RootFlowCoordinator(navigationRootCoordinator: navigationRootCoordinator,
                                                  userSessionManager: userSessionManager,
                                                  elementCallManager: elementCallManager,
                                                  appLockService: appLockService,
                                                  bugReportService: bugReportService,
                                                  appMediator: appMediator,
                                                  appSettings: appSettings,
                                                  appHooks: appHooks,
                                                  analyticsService: analyticsService,
                                                  userIndicatorController: userIndicatorController,
                                                  targetContext: targetConfiguration.context)
        
        Self.setupSentry(bugReportService: bugReportService, appSettings: appSettings, analytics: analyticsService)
        
        analyticsService.startIfEnabled()
        
        windowManager.delegate = self
        
        configureNotificationManager()
        
        if let previousVersion {
            performMigrationsIfNecessary(from: previousVersion, to: currentVersion)
        } else {
            // The app has been deleted since the previous run. Reset everything.
            wipeUserData(includingSettings: true)
        }
        appSettings.lastVersionLaunched = currentVersion.description
        
        setupStateMachine()
        
        observeApplicationState()
        observeUserSessionChanges()
        observeAppLockChanges()
        observeRootFlowActions()
        
        registerBackgroundAppRefresh()
        registerSearchBackfill()
        
        appSettings.analyticsConsentStatePublisher
            .dropFirst() // Sentry is configured during init; only reconfigure when consent state actually changes
            .sink { [bugReportService, analyticsService, appSettings] _ in
                Self.setupSentry(bugReportService: bugReportService, appSettings: appSettings, analytics: analyticsService)
            }
            .store(in: &cancellables)
        
        configureCalls()
        
        windowManager.secondaryWindowsEnabled = !appLockService.isEnabled
        appLockService.isEnabledPublisher.sink { [weak windowManager] appLockEnabled in
            windowManager?.secondaryWindowsEnabled = !appLockEnabled
        }
        .store(in: &cancellables)
    }
    
    func start() {
        guard stateMachine.state == .initial else {
            MXLog.info("Received a start request when already started")
            return
        }
        
        guard !userSessionManager.userIDs.isEmpty else {
            stateMachine.processEvent(.startWithAuthentication)
            return
        }
        
        stateMachine.processEvent(.startWithExistingSession)
    }
    
    func toPresentable() -> AnyView {
        AnyView(navigationRootCoordinator.toPresentable()
            .environment(\.analyticsService, analyticsService)
            .onReceive(appSettings.appAppearancePublisher) { [weak self] appAppearance in
                guard let self else { return }
                
                windowManager.windows.forEach { window in
                    // Unfortunately .preferredColorScheme doesn't propagate properly throughout the app when changed
                    window.overrideUserInterfaceStyle = appAppearance.interfaceStyle
                }
            }
            .modifier(SnowEffect(isEnabledPublisher: appSettings.snowEnabledPublisher)))
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
    
    func handleAppRoute(_ appRoute: AppRoute, windowType: SecondaryWindowType?) {
        // Read before resuming the services, by which time a push tap or deep link will have made the app active.
        let animated = appMediator.appState == .active
        Task { await handleAppRoute(appRoute, userID: nil, awaitsRoom: false, windowType: windowType, animated: animated) }
    }
    
    private func handleAppRoute(_ appRoute: AppRoute, userID: String?, awaitsRoom: Bool, windowType: SecondaryWindowType?, animated: Bool) async {
        // The animated parameter can be removed once iOS 18 is dropped in favour of using `Task.immediate` to read it in here.
        // let animated = appMediator.appState == .active
        
        MXLog.info("Handling app route:  \(appRoute)")
        
        await resumeClientServices()
        
        if let windowType {
            windowManager.handleRoute(appRoute, windowType: windowType)
            return
        }
        
        rootFlowCoordinator.handleAppRoute(appRoute, userID: userID, awaitsRoom: awaitsRoom, animated: animated)
    }
    
    func handleDeepLink(_ url: URL, isExternalURL: Bool, windowType: SecondaryWindowType?) -> Bool {
        // Parse into an AppRoute to redirect these in a type safe way.
        
        if let route = appRouteURLParser.route(from: url) {
            switch route {
            case .accountProvisioningLink:
                handleAppRoute(route,
                               windowType: windowType)
            case .oAuthCallback:
                rootFlowCoordinator.handleAppRoute(route, animated: true)
            case .userProfile(let userID):
                if isExternalURL {
                    handleAppRoute(route,
                                   windowType: windowType)
                } else {
                    handleAppRoute(.roomMemberDetails(userID: userID),
                                   windowType: windowType)
                }
            case .room(let roomID, let via):
                if isExternalURL {
                    handleAppRoute(route,
                                   windowType: windowType)
                } else {
                    handleAppRoute(.childRoom(roomID: roomID, via: via),
                                   windowType: windowType)
                }
            case .roomAlias(let alias):
                if isExternalURL {
                    handleAppRoute(route,
                                   windowType: windowType)
                } else {
                    handleAppRoute(.childRoomAlias(alias),
                                   windowType: windowType)
                }
            case .event(let eventID, let roomID, let via):
                if isExternalURL {
                    handleAppRoute(route,
                                   windowType: windowType)
                } else {
                    handleAppRoute(.childEvent(eventID: eventID, roomID: roomID, via: via),
                                   windowType: windowType)
                }
            case .eventOnRoomAlias(let eventID, let alias):
                if isExternalURL {
                    handleAppRoute(route,
                                   windowType: windowType)
                } else {
                    handleAppRoute(.childEventOnRoomAlias(eventID: eventID, alias: alias),
                                   windowType: windowType)
                }
            case .share(let payload):
                guard isExternalURL else {
                    MXLog.error("Received unexpected internal share route")
                    break
                }
                
                do {
                    try handleAppRoute(.share(payload.withDefaultTemporaryDirectory()),
                                       windowType: windowType)
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
        guard let intent = userActivity.interaction?.intent as? INStartCallIntent,
              let contact = intent.contacts?.first,
              let roomIdentifier = contact.personHandle?.value else {
            MXLog.error("Failed retrieving information from userActivity: \(userActivity)")
            return
        }
        
        MXLog.info("Starting call in room: \(roomIdentifier)")
        handleAppRoute(AppRoute.call(roomID: roomIdentifier, isVoiceCall: intent.callCapability == .audioCall, answeredFromCallKit: false), windowType: nil)
    }
    
    // MARK: - WindowManagerDelegate
    
    func windowManagerDidConfigureWindows(_ windowManager: SecureWindowManagerProtocol) {
        windowManager.alternateWindow.rootViewController = UIHostingController(rootView: appLockFlowCoordinator.toPresentable())
        userIndicatorController.window = windowManager.overlayWindow
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
        // Only the active account's rooms can be on screen.
        if let receiverID = content.receiverID, receiverID != userSession?.clientProxy.userID {
            return true
        }
        return !rootFlowCoordinator.isDisplayingRoomScreen(withRoomID: roomID)
    }
    
    func notificationTapped(content: UNNotificationContent) async {
        MXLog.info("Tapped Notification")
        
        guard let roomID = content.roomID,
              let receiverID = content.receiverID else {
            return
        }
        
        let eventID = appSettings.focusEventOnNotificationTap ? content.eventID : nil
        let isInvite = content.categoryIdentifier == NotificationConstants.Category.invite
        let appRoute: AppRoute
        if isInvite {
            appRoute = .room(roomID: roomID, via: [])
        } else if appSettings.threadsEnabled, let threadRootEventID = content.threadRootEventID {
            appRoute = .thread(roomID: roomID, threadRootEventID: threadRootEventID, focusEventID: eventID)
        } else if let eventID {
            // Only track main timeline event deeplinking
            analyticsService.signpost.startTransaction(.notificationToMessage)
            appRoute = .event(eventID: eventID, roomID: roomID, via: [])
        } else {
            appRoute = .room(roomID: roomID, via: [])
        }
        
        let animated = appMediator.appState == .active
        Task { await handleAppRoute(appRoute, userID: receiverID, awaitsRoom: isInvite, windowType: nil, animated: animated) }
    }
    
    func handleInlineReply(_ service: NotificationManagerProtocol, content: UNNotificationContent, replyText: String) async {
        MXLog.info("Handle notification reply")
        
        guard let roomID = content.roomID,
              let receiverID = content.receiverID else {
            return
        }
        
        let threadRootEventID = appSettings.threadsEnabled ? content.threadRootEventID : nil
        
        guard let userSession = userSessionManager.session(for: receiverID) else {
            // Store the data so it can be sent once the receiver's session is live.
            storedInlineReply = PendingInlineReplyDetails(userID: receiverID, roomID: roomID, threadRootEventID: threadRootEventID, message: replyText)
            return
        }
        
        await processInlineReply(replyText, roomID: roomID, threadRootEventID: threadRootEventID, userSession: userSession)
    }
    
    // MARK: - Private
    
    /// Perform any required migrations for the app to function correctly.
    private func performMigrationsIfNecessary(from oldVersion: Version, to newVersion: Version) {
        guard oldVersion != newVersion else { return }
        
        // Be tidy and clean up after ourselves every now and then (because Apple is lazy)
        clearTemporaryDirectories()
        
        MXLog.info("The app was upgraded from \(oldVersion) to \(newVersion)")
        
        if oldVersion < Version(1, 6, 7) {
            Tracing.deleteLogFiles(in: Tracing.legacyLogsDirectory)
            MXLog.info("Migrating to v1.6.7, log files have been wiped")
        }
        
        if oldVersion < Version(25, 7, 4) {
            Tracing.migrateLogFiles()
            MXLog.info("Migrating to version 25.07.4, log files have been moved.")
        }
        
        if oldVersion < Version(26, 10, 2) {
            MXLog.info("Migrating to version 26.10.2, moving notification sounds.")
            let soundsDirectory = URL.libraryDirectory.appending(component: "Sounds", directoryHint: .isDirectory)
            
            // Sounds are now referenced directly, the duplicate file can go.
            try? FileManager.default.removeItem(at: soundsDirectory.appending(component: "currentAlert.caf"))
            
            let oldCustomTonesLocation = soundsDirectory.appending(component: "AvailableSounds", directoryHint: .isDirectory)
            if FileManager.default.fileExists(atPath: oldCustomTonesLocation.path(percentEncoded: false)) {
                do {
                    try FileManager.default.moveItem(at: oldCustomTonesLocation, to: URL.customTonesDirectory)
                } catch {
                    MXLog.error("Failed moving custom notification sounds: \(error)")
                }
            }
        }
    }
    
    /// Clears the keychain, app support directory etc ready for a fresh use.
    /// - Parameter includingSettings: Whether to additionally wipe the user's app settings too.
    private func wipeUserData(includingSettings: Bool = false) {
        if includingSettings {
            appSettings.resetAllSettings()
            appLockFlowCoordinator.appLockService.disable()
        }
        userSessionManager.reset()
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
            
            if context.toState != .restoringSession {
                isSessionRestoredSubject.send(true)
            }
            
            switch (context.fromState, context.event, context.toState) {
            case (.initial, .startWithAuthentication, .running):
                startAuthentication()
            case (.initial, .startWithExistingSession, .restoringSession):
                restoreUserSessions()
            case (.restoringSession, .restoredSession, .running),
                 (.restoringSession, .failedRestoringSession, .running):
                break
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
    
    private func restoreUserSessions() {
        Task {
            await userSessionManager.restoreSessions()
            
            if stateMachine.state == .restoringSession {
                MXLog.error("Failed to restore an existing session.")
                stateMachine.processEvent(.failedRestoringSession)
            }
        }
    }
    
    /// Resumes the services once a session is live, and stops waiting for a restore.
    private func finishSessionRestoration() {
        guard stateMachine.state == .restoringSession else { return }
        
        Task { await resumeClientServices() }
        stateMachine.processEvent(.restoredSession)
    }
    
    /// Sends a reply made from a notification before its account was live.
    private func sendStoredInlineReply(from userSession: UserSessionProtocol) {
        guard let storedInlineReply, storedInlineReply.userID == userSession.clientProxy.userID else { return }
        self.storedInlineReply = nil
        
        Task {
            await processInlineReply(storedInlineReply.message,
                                     roomID: storedInlineReply.roomID,
                                     threadRootEventID: storedInlineReply.threadRootEventID,
                                     userSession: userSession)
        }
    }
    
    private func startAuthentication() {
        rootFlowCoordinator.handleAppRoute(.authentication, animated: true)
    }
    
    /// Logs out every account, then disables App Lock if requested (e.g. when the user forgot their PIN).
    private func logoutAllAccounts(disableAppLock: Bool) async {
        await userSessionManager.logoutAll()
        if disableAppLock {
            await disableAppLockAfterSigningOut()
        }
    }
    
    private func disableAppLockAfterSigningOut() async {
        // Ensure the navigation stack has settled.
        try? await Task.sleep(for: .milliseconds(500))
        
        // Never unlock while an account remains, its flow would be shown without a PIN.
        guard userSessionManager.userIDs.isEmpty else {
            MXLog.error("Not disabling App Lock, an account is still signed in.")
            return
        }
        
        appLockFlowCoordinator.appLockService.disable()
        windowManager.switchToMain()
    }
    
    private func configureNotificationManager() {
        notificationManager.delegate = self
        notificationManager.start()
        
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
    
    private func configureCalls() {
        elementCallManager.actionsPublisher
            .sink { [weak self] action in
                switch action {
                case .incomingCallReported:
                    // When reporting a VoIP call through the CXProvider's `reportNewIncomingVoIPPushPayload`
                    // the UIApplication states don't change and services are neither started nor ran on
                    // a background task. Handle both manually here.
                    Task {
                        await self?.resumeClientServices()
                        self?.scheduleDelayedPauseServices()
                    }
                case let .callAnswered(userID, roomID, isVoiceCall):
                    guard let self else { return }
                    
                    // TODO: Open other accounts' answered calls with their own session (#6387).
                    let animated = appMediator.appState == .active
                    let callRoute = AppRoute.call(roomID: roomID, isVoiceCall: isVoiceCall, answeredFromCallKit: true)
                    Task { await handleAppRoute(callRoute, userID: userID, awaitsRoom: false, windowType: nil, animated: animated) }
                case .callScreen:
                    break // Shown by the account's user session flow.
                }
            }
            .store(in: &cancellables)
    }
    
    private func observeUserSessionChanges() {
        // Delivered synchronously, so a restored session is shown before the manager resumes it.
        userSessionManager.callbacksPublisher
            .sink { [weak self] callback in
                guard let self else { return }
                switch callback {
                case .didRestoreSession(let userID):
                    if let userSession = userSessionManager.session(for: userID) {
                        finishSessionRestoration()
                        sendStoredInlineReply(from: userSession)
                    }
                case .didRemoveAccount:
                    handleAccountRemoval()
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleAccountRemoval() {
        #warning("Make sure to test this but it may well move.")
        if let activeSession = userSessionManager.activeSession {
            appHooks.remoteSettingsHook.loadCache(forHomeserver: activeSession.clientProxy.homeserver, applyingTo: appSettings)
        } else {
            appHooks.remoteSettingsHook.reset(appSettings)
        }
        
        // Signed in accounts that aren't live yet still count.
        guard userSessionManager.userIDs.isEmpty else { return }
        
        notificationManager.reset()
        analyticsService.optOut()
        analyticsService.resetConsentState()
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
                Task { await logoutAllAccounts(disableAppLock: true) }
            }
        }
        .store(in: &cancellables)
    }
    
    private func observeRootFlowActions() {
        rootFlowCoordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .closeSecondaryWindows:
                windowManager.closeAllSecondaryWindows()
            case .forceLogout:
                Task { await logoutAllAccounts(disableAppLock: true) }
            }
        }
        .store(in: &cancellables)
    }
    
    private static func setupSentry(bugReportService: BugReportServiceProtocol, appSettings: AppSettings, analytics: AnalyticsServiceProtocol) {
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
        
        // MetricKit is now the preferred way to track app hangs
        options.enableMetricKit = true
        options.enableAppHangTracking = false
        
        // Most of the network requests are made Rust side, this is useless
        options.enableNetworkBreadcrumbs = false
        
        // Doesn't seem to work at all well with SwiftUI
        options.enableAutoBreadcrumbTracking = false
        
        // Release health, we want the crash free rates it powers
        options.enableAutoSessionTracking = true
        
        // Off by default but spelled out so a Sentry default flip doesn't silently enable them
        options.sessionReplay.sessionSampleRate = 0
        options.sessionReplay.onErrorSampleRate = 0
        options.attachScreenshot = false
        options.attachViewHierarchy = false
        options.sendDefaultPii = false
        options.enableMetricKit = false
        
        // Experimental. Stitches stack traces of asynchronous code together
        options.swiftAsyncStacktraces = true
        
        // Uniform sample rate: 1.0 captures 100% of transactions
        // In Production you will probably want a smaller number such as 0.5 for 50%
        options.sampleRate = 1.0
        options.tracesSampleRate = 1.0
        options.configureProfiling = { $0.sessionSampleRate = 1.0 }
        
        // This callback is only executed once during the entire run of the program to avoid
        // multiple callbacks if there are multiple crash events to send (see method documentation)
        options.onLastRunStatusDetermined = { status, event in
            guard case .didCrash = status, let event else { return }
            MXLog.error("Sentry detected a crash in the previous run: \(event.eventId.sentryIdString)")
            bugReportService.lastCrashEventIDSubject.send(event.eventId.sentryIdString)
        }
        
        // Mirror every crash into our own logs (which ship with rageshakes) before it's sent to Sentry.
        // Device values are read here on the main thread; beforeSend runs on a background queue.
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        options.beforeSend = { @Sendable event in
            if let crashLog = event.crashLog(deviceModel: deviceModel, systemVersion: systemVersion) {
                MXLog.error("Sentry crash event \(event.eventId.sentryIdString):\n\(crashLog)")
            }
            return event
        }
        
        // Any ongoing transactions will no longer be valid after calling SentrySDK.start so lets
        // remove them and start over, otherwise the app will crash if finishTransaction is used.
        analytics.signpost.resetTransactions()
        
        SentrySDK.start(options: options) // Swift
        enableSentryLogging(enabled: options.enabled) // Rust
        
        MXLog.info("Sentry configured (enabled: \(options.enabled))")
    }
    
    private func processInlineReply(_ replyText: String, roomID: String, threadRootEventID: String?, userSession: UserSessionProtocol) async {
        guard case let .joined(roomProxy) = await userSession.clientProxy.roomForIdentifier(roomID) else {
            MXLog.error("Tried to reply in an unjoined room: \(roomID)")
            return
        }
        
        let timeline: TimelineProxyProtocol? = if let threadRootEventID {
            try? await roomProxy.threadTimeline(eventID: threadRootEventID).get()
        } else {
            roomProxy.timeline
        }
        
        switch await timeline?.sendMessage(replyText,
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
    
    // MARK: - Application State
    
    private func pauseClientServices(isBackgroundTask: Bool) async {
        if isBackgroundTask, UIApplication.shared.applicationState == .active {
            // Attempt to pause the background task services cleanly, only if the app not already running
            return
        }
        
        await userSessionManager.pauseServices()
    }
    
    private func resumeClientServices() async {
        await userSessionManager.resumeServices()
    }
    
    private func observeApplicationState() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillResignActive),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
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
        MXLog.info("Application will terminate")
        Task { await pauseClientServices(isBackgroundTask: false) }
    }
    
    @objc
    private func applicationDidEnterBackground() {
        MXLog.info("Application did enter background")
        
        scheduleDelayedPauseServices()
        scheduleBackgroundAppRefresh()
        scheduleSearchBackfill()
    }
    
    @objc
    private func applicationWillResignActive() {
        MXLog.info("Application will resign active")
    }
    
    private func scheduleDelayedPauseServices() {
        guard backgroundTask == nil else {
            return
        }
        
        backgroundTask = appMediator.beginBackgroundTask {
            MXLog.info("Background task is about to expire.")
            
            // We're intentionally strongly retaining self here to an EXC_BAD_ACCESS
            // `backgroundTask` will be eventually released in `endActiveBackgroundTask`
            // https://sentry.tools.element.io/organizations/element/issues/4477794/events/9cfd04e4d045440f87498809cf718de5/
            Task { @MainActor in
                await self.pauseClientServices(isBackgroundTask: true)
                self.endActiveBackgroundTask()
            }
        }
    }
    
    @objc
    private func applicationWillEnterForeground() {
        MXLog.info("Application will enter foreground")
        endActiveBackgroundTask()
        Task {
            await resumeClientServices()
        }
    }
    
    @objc
    private func applicationDidBecomeActive() {
        MXLog.info("Application did become active")
    }
    
    private func endActiveBackgroundTask() {
        guard let backgroundTask else {
            return
        }
        
        MXLog.info("Ending background task.")
        appMediator.endBackgroundTask(backgroundTask)
        self.backgroundTask = nil
    }
}

// MARK: Background app refresh

private extension AppCoordinator {
    func registerBackgroundAppRefresh() {
        let result = BGTaskScheduler.shared.register(forTaskWithIdentifier: appSettings.backgroundAppRefreshTaskIdentifier, using: .main) { [weak self] task in
            guard let task = task as? BGAppRefreshTask else {
                MXLog.error("Invalid background app refresh configuration")
                return
            }
            
            Task {
                await self?.handleBackgroundAppRefresh(task)
            }
        }
        
        MXLog.info("Register background app refresh with result: \(result)")
    }
    
    func scheduleBackgroundAppRefresh() {
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
    
    func handleBackgroundAppRefresh(_ task: BGAppRefreshTask) async {
        MXLog.info("Started background app refresh")
        
        // This is important for the app to keep refreshing in the background
        scheduleBackgroundAppRefresh()
        
        // We have a lot of crashes stemming here which we previously believed were caused by pauseServices not being
        // async on the client proxy side. We have now realised that will likely not fix anything but we also noticed
        // this does not crash on the main thread, even though the whole AppCoordinator is on the Main actor. As such,
        // we hop onto the main actor explicitly before pausing.
        // https://sentry.tools.element.io/organizations/element/issues/4477794/
        // BGTask isn't annotated but is documented as thread-safe, with
        // setTaskCompleted(success:) being callable from any thread.
        nonisolated(unsafe) let task = task
        task.expirationHandler = { @Sendable [weak self] in
            MXLog.info("Background app refresh task is about to expire.")
            
            Task { @MainActor in
                await self?.pauseClientServices(isBackgroundTask: true)
                MXLog.info("Marking Background app refresh task as complete.")
                task.setTaskCompleted(success: true)
            }
        }
        
        await waitForSessionRestore()
        
        guard let userSession else {
            MXLog.info("Background app refresh: no user session, giving up.")
            task.setTaskCompleted(success: false)
            return
        }
        
        // Configure the background-refresh sync to carry set_presence=offline so it doesn't mark the
        // user online or idle. Note: If already online/idle then setting offline shouldn't override that.
        await userSessionManager.configurePresence(.offline, sendImmediately: false)
        
        await resumeClientServices()
        
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
                Task {
                    await self.pauseClientServices(isBackgroundTask: true)
                    MXLog.info("Marking Background app refresh task as complete.")
                    task.setTaskCompleted(success: true)
                }
            }
    }
    
    /// When iOS relaunches a terminated app for a background task, the session needs restoring before the task can run.
    private func waitForSessionRestore() async {
        // A background launch doesn't necessarily connect a scene, which is what normally calls `start()`.
        if stateMachine.state == .initial, !userSessionManager.userIDs.isEmpty {
            start()
        }
        
        for await isSessionRestored in isSessionRestoredSubject.timeout(.seconds(5), scheduler: DispatchQueue.main).values where isSessionRestored {
            return
        }
    }
}

// MARK: Search backfill

private extension AppCoordinator {
    func registerSearchBackfill() {
        let result = BGTaskScheduler.shared.register(forTaskWithIdentifier: appSettings.searchBackfillTaskIdentifier, using: .main) { [weak self] task in
            guard let task = task as? BGProcessingTask else {
                MXLog.error("Invalid search backfill configuration")
                return
            }
            
            Task {
                await self?.handleSearchBackfill(task)
            }
        }
        
        MXLog.info("Register search backfill with result: \(result)")
    }
    
    func scheduleSearchBackfill() {
        guard let userSession, userSession.userSettings.app.globalSearchEnabled else {
            return
        }
        
        let request = BGProcessingTaskRequest(identifier: appSettings.searchBackfillTaskIdentifier)
        request.requiresExternalPower = true
        request.requiresNetworkConnectivity = true
        
        do {
            try BGTaskScheduler.shared.submit(request)
            MXLog.info("Successfully scheduled search backfill task")
        } catch {
            MXLog.error("Failed scheduling search backfill with error: \(error)")
        }
    }
    
    func handleSearchBackfill(_ task: BGProcessingTask) async {
        MXLog.info("Started search backfill task")
        
        await waitForSessionRestore()
        
        task.expirationHandler = { @Sendable [weak self] in
            MXLog.info("Search backfill task is about to expire.")
            Task { @MainActor in self?.userSessionManager.stopSearchBackfill() }
        }
        
        userSessionManager.startSearchBackfill(strategy: .background)
        
        // TaskHandle can't be awaited, so poll until every sweep finishes or is stopped on expiry.
        while userSessionManager.isSearchBackfillRunning {
            try? await Task.sleep(for: .seconds(1))
        }
        
        MXLog.info("Marking search backfill task as complete.")
        task.setTaskCompleted(success: true)
    }
}

private struct PendingInlineReplyDetails {
    let userID: String
    let roomID: String
    let threadRootEventID: String?
    let message: String
}

/// Shows the snow for as long as its developer option is enabled.
private struct SnowEffect: ViewModifier {
    let isEnabledPublisher: AnyPublisher<Bool, Never>
    
    @State private var isEnabled = false
    
    func body(content: Content) -> some View {
        content
            .particleEffect(isEnabled ? .snow : nil)
            .onReceive(isEnabledPublisher) { isEnabled = $0 }
    }
}
