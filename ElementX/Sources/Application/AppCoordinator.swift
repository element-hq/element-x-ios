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
import Version

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
            userSessionCancellables.removeAll()
            
            if userSession != nil {
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
    private(set) var notificationManager: NotificationManagerProtocol

    @Consumable private var storedAppRoute: AppRoute?

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
        ServiceLocator.shared.userIndicatorController.toPresentable()
    }
        
    // MARK: - Private
    
    private static func setupServiceLocator(navigationRootCoordinator: NavigationRootCoordinator) {
        ServiceLocator.shared.register(userIndicatorController: UserIndicatorController(rootCoordinator: navigationRootCoordinator))
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
            case (_, .signOut(let isSoft), .signingOut):
                self.logout(isSoft: isSoft)
            case (.signingOut, .completedSigningOut(let isSoft), .signedOut):
                self.presentSplashScreen(isSoftLogout: isSoft)
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
        Task {
            var displayName = ""
            if case .success(let name) = await userSession.clientProxy.loadUserDisplayName() {
                displayName = name
            }
            
            let credentials = SoftLogoutCredentials(userId: userSession.userID,
                                                    homeserverName: userSession.homeserver,
                                                    userDisplayName: displayName,
                                                    deviceId: userSession.deviceID)
            
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
                    self.stateMachine.processEvent(.createdUserSession)
                case .clearAllData:
                    self.stateMachine.processEvent(.signOut(isSoft: false))
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
                self?.stateMachine.processEvent(.signOut(isSoft: false))
            }
        }
        
        userSessionFlowCoordinator.start()
        
        self.userSessionFlowCoordinator = userSessionFlowCoordinator
        
        navigationRootCoordinator.setRootCoordinator(navigationSplitCoordinator)

        if let storedAppRoute {
            DispatchQueue.main.async {
                userSessionFlowCoordinator.handleAppRoute(storedAppRoute)
            }
        }
    }
    
    private func logout(isSoft: Bool) {
        showLoadingIndicator()
        
        defer {
            hideLoadingIndicator()
        }
        
        userSession.clientProxy.stopSync()
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
            
            stateMachine.processEvent(.completedSigningOut(isSoft: isSoft))
        }
    }
    
    private func tearDownUserSession() {
        userSession = nil
        
        userSessionFlowCoordinator = nil
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
        notificationManager.setClientProxy(userSession.clientProxy)
        notificationManager.requestAuth()

        if let appDelegate = AppDelegate.shared {
            appDelegate.callbacks
                .receive(on: DispatchQueue.main)
                .sink { [weak self] callback in
                    switch callback {
                    case .registeredNotifications(let deviceToken):
                        Task { await self?.notificationManager.register(with: deviceToken) }
                    case .failedToRegisteredNotifications(let error):
                        self?.notificationManager.registrationFailed(with: error)
                    }
                }
                .store(in: &cancellables)
        } else {
            MXLog.error("Couldn't register to AppDelegate callbacks")
        }
    }
    
    private func observeUserSessionChanges() {
        userSession.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                guard let self else { return }
                switch callback {
                case .didReceiveAuthError(let isSoftLogout):
                    self.stateMachine.processEvent(.signOut(isSoft: isSoftLogout))
                default:
                    break
                }
            }
            .store(in: &userSessionCancellables)
    }
    
    // MARK: Toasts and loading indicators
    
    static let loadingIndicatorIdentifier = "AppCoordinatorLoading"
    
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
                ServiceLocator.shared.userIndicatorController.retractIndicatorWithId(reachabilityNotificationIdentifier)
            } else {
                ServiceLocator.shared.userIndicatorController.submitIndicator(.init(id: reachabilityNotificationIdentifier,
                                                                                    title: L10n.commonOffline,
                                                                                    persistent: true))
            }
        }.store(in: &cancellables)
    }
}

// MARK: - AuthenticationCoordinatorDelegate

extension AppCoordinator: AuthenticationCoordinatorDelegate {
    func authenticationCoordinator(_ authenticationCoordinator: AuthenticationCoordinator, didLoginWithSession userSession: UserSessionProtocol) {
        self.userSession = userSession
        stateMachine.processEvent(.createdUserSession)
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

        // We store the room identifier into the thread identifier
        guard !content.threadIdentifier.isEmpty,
              let _ = content.receiverId else {
            return
        }

        // Handle here the account switching when available

        handleAppRoute(.room(roomID: content.threadIdentifier))
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
            await service.showLocalNotification(with: "⚠️ " + L10n.commonError,
                                                subtitle: L10n.errorSomeMessagesHaveNotBeenSent)
        }
    }

    private func handleAppRoute(_ appRoute: AppRoute) {
        if let userSessionFlowCoordinator {
            userSessionFlowCoordinator.handleAppRoute(appRoute)
        } else {
            storedAppRoute = appRoute
        }
    }
}
