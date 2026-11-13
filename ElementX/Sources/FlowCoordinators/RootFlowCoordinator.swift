//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVKit
import Combine
import SwiftState
import SwiftUI

enum RootFlowCoordinatorAction {
    /// The shown account was removed, so any secondary windows showing it should close.
    case closeSecondaryWindows
    /// Logout and disable App Lock without any confirmation. The user forgot their PIN.
    case forceLogout
}

/// Switches the app's root between the authentication flow and the user session flow, and shows calls above both.
class RootFlowCoordinator: FlowCoordinatorProtocol {
    private let navigationRootCoordinator: NavigationRootCoordinator
    private let userSessionManager: UserSessionManagerProtocol
    private let elementCallManager: ElementCallManagerProtocol
    private let appLockService: AppLockServiceProtocol
    private let bugReportService: BugReportServiceProtocol
    private let appMediator: AppMediatorProtocol
    private let appSettings: AppSettings
    private let appHooks: AppHooks
    private let analyticsService: AnalyticsServiceProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let authenticationServiceFactory: AuthenticationServiceFactoryProtocol
    
    private var authenticationFlowCoordinator: AuthenticationFlowCoordinator?
    private var userSessionFlowCoordinator: UserSessionFlowCoordinator?
    
    enum State: StateType {
        /// The state machine hasn't started.
        case initial
        /// The authentication flow is the root.
        case authenticationFlow(isAddingAccount: Bool)
        /// A user session flow is the root.
        case userSessionFlow(userID: String)
        /// A placeholder is being shown while clearing caches.
        case clearingCache(userID: String)
        /// A placeholder is being shown while the active account logs out.
        case loggingOut(userID: String)
    }
    
    enum Event: EventType {
        /// Request presentation of the authentication flow, either with no account signed in or to sign in another one.
        case startAuthentication(isAddingAccount: Bool)
        /// Request presentation of the given account's user session flow.
        case startUserSession(userID: String)
        /// Request clearing the active account's caches.
        case clearCache
        /// Request logging out the active account.
        case logout
    }
    
    private let stateMachine: StateMachine<State, Event>
    
    /// A call screen on the overlay, which belongs to one account.
    struct PresentedCallScreen: Hashable {
        let userID: String
        let isNative: Bool
    }
    
    enum CallScreenState: StateType {
        /// No call screen is on the overlay.
        case notPresented
        /// The call screen covers every account's screens.
        case fullScreen(PresentedCallScreen)
        /// The call screen stays on the overlay but is hidden, in picture in picture or the system's call window.
        case minimized(PresentedCallScreen)
    }
    
    enum CallScreenEvent: EventType {
        /// Show a call screen full screen, replacing any other.
        case present(PresentedCallScreen)
        case minimize
        case restore
        case dismiss
    }
    
    private let callScreenStateMachine: StateMachine<CallScreenState, CallScreenEvent>
    
    /// Information about an ``AppRoute`` that can be re-played when ready.
    private struct PendingAppRoute {
        let appRoute: AppRoute
        let userID: String?
        let awaitsRoom: Bool
    }
    
    /// A stored route that was received before the flow was ready.
    private var pendingAppRoute: PendingAppRoute?
    
    private var callScreenPictureInPictureController: AVPictureInPictureController?
    private var callScreenCancellable: AnyCancellable?
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<RootFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<RootFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(navigationRootCoordinator: NavigationRootCoordinator,
         userSessionManager: UserSessionManagerProtocol,
         elementCallManager: ElementCallManagerProtocol,
         appLockService: AppLockServiceProtocol,
         bugReportService: BugReportServiceProtocol,
         appMediator: AppMediatorProtocol,
         appSettings: AppSettings,
         appHooks: AppHooks,
         analyticsService: AnalyticsServiceProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         authenticationServiceFactory: AuthenticationServiceFactoryProtocol = AuthenticationServiceFactory()) {
        self.navigationRootCoordinator = navigationRootCoordinator
        self.userSessionManager = userSessionManager
        self.elementCallManager = elementCallManager
        self.appLockService = appLockService
        self.bugReportService = bugReportService
        self.appMediator = appMediator
        self.appSettings = appSettings
        self.appHooks = appHooks
        self.analyticsService = analyticsService
        self.userIndicatorController = userIndicatorController
        self.authenticationServiceFactory = authenticationServiceFactory
        
        stateMachine = .init(state: .initial)
        callScreenStateMachine = .init(state: .notPresented)
        configureStateMachine()
        configureCallScreenStateMachine()
        
        setupSubscriptions()
    }
    
    func start(animated: Bool) {
        fatalError("This flow coordinator expects a route")
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        handleAppRoute(appRoute, userID: nil, awaitsRoom: false, animated: animated)
    }
    
    func handleAppRoute(_ appRoute: AppRoute, userID: String?, awaitsRoom: Bool, animated: Bool) {
        switch appRoute {
        case .authentication:
            stateMachine.tryEvent(.startAuthentication(isAddingAccount: false))
        case .accountProvisioningLink:
            switch stateMachine.state {
            case .initial:
                pendingAppRoute = .init(appRoute: appRoute, userID: userID, awaitsRoom: awaitsRoom)
            case .authenticationFlow:
                authenticationFlowCoordinator?.handleAppRoute(appRoute, animated: animated)
            case .userSessionFlow:
                break // TODO: Start a flow to add a new account?
            case .clearingCache, .loggingOut:
                break
            }
        case .oAuthCallback(let url):
            if case .authenticationFlow = stateMachine.state {
                authenticationFlowCoordinator?.handleOAuthCallbackURL(url)
            } else {
                MXLog.error("Received an OAuth callback without an authentication flow.")
            }
        case .roomList:
            if case .userSessionFlow = stateMachine.state {
                minimizeFullScreenCall()
                userSessionFlowCoordinator?.handleAppRoute(appRoute, animated: animated)
            } else if let userID = userSessionManager.activeSession?.clientProxy.userID {
                stateMachine.tryEvent(.startUserSession(userID: userID))
            }
        case let .call(roomID, isVoiceCall, answeredFromCallKit):
            handleCallRoute(roomID: roomID, isVoiceCall: isVoiceCall, answeredFromCallKit: answeredFromCallKit, userID: userID)
        case .room, .roomAlias, .childRoom, .childRoomAlias,
             .roomDetails, .roomMemberDetails, .userProfile,
             .event, .eventOnRoomAlias, .childEvent, .childEventOnRoomAlias,
             .settings, .chatBackupSettings, .share, .transferOwnership, .thread, .search:
            switch stateMachine.state {
            case .initial:
                pendingAppRoute = .init(appRoute: appRoute, userID: userID, awaitsRoom: awaitsRoom)
            case .authenticationFlow:
                MXLog.info("Ignoring app route, an authentication flow is in progress.")
            case .userSessionFlow:
                handleUserSessionRoute(appRoute, userID: userID, awaitsRoom: awaitsRoom, animated: animated)
            case .clearingCache, .loggingOut:
                break
            }
        }
    }
    
    func clearRoute(animated: Bool) {
        switch stateMachine.state {
        case .initial, .clearingCache, .loggingOut:
            break
        case .authenticationFlow:
            authenticationFlowCoordinator?.clearRoute(animated: animated)
        case .userSessionFlow:
            userSessionFlowCoordinator?.clearRoute(animated: animated)
        }
        
        navigationRootCoordinator.setRootCoordinator(nil, animated: animated)
    }
    
    func isDisplayingRoomScreen(withRoomID roomID: String) -> Bool {
        guard case .userSessionFlow = stateMachine.state else { return false }
        
        // The call screen covers the room.
        if case .fullScreen = callScreenStateMachine.state {
            return false
        }
        
        return userSessionFlowCoordinator?.isDisplayingRoomScreen(withRoomID: roomID) ?? false
    }
    
    // MARK: - Private
    
    private func configureStateMachine() {
        stateMachine.addRouteMapping { event, fromState, _ in
            switch (fromState, event) {
            case (.initial, .startAuthentication(isAddingAccount: false)):
                .authenticationFlow(isAddingAccount: false)
            case (.initial, .startUserSession(let userID)):
                .userSessionFlow(userID: userID)
                
            case (.authenticationFlow, .startUserSession(let userID)):
                .userSessionFlow(userID: userID)
                
            case (.userSessionFlow, .startAuthentication(let isAddingAccount)):
                .authenticationFlow(isAddingAccount: isAddingAccount)
            case (.userSessionFlow(let userID), .clearCache):
                .clearingCache(userID: userID)
            case (.userSessionFlow(let userID), .logout):
                .loggingOut(userID: userID)
            case (.userSessionFlow, .startUserSession(let userID)):
                .userSessionFlow(userID: userID)
                
            case (.clearingCache, .startAuthentication(isAddingAccount: false)):
                .authenticationFlow(isAddingAccount: false)
            case (.clearingCache, .startUserSession(let userID)):
                .userSessionFlow(userID: userID)
                
            case (.loggingOut, .startAuthentication(isAddingAccount: false)):
                .authenticationFlow(isAddingAccount: false)
            case (.loggingOut, .startUserSession(let userID)):
                .userSessionFlow(userID: userID)
                
            default:
                nil
            }
        }
        
        stateMachine.addAnyHandler(.any => .any) { [weak self] context in
            guard let self else { return }
            
            MXLog.info("Transitioning from `\(context.fromState)` to `\(context.toState)` with event `\(String(describing: context.event))`.")
            
            switch (context.fromState, context.event, context.toState) {
            case (.initial, .startAuthentication(let isAddingAccount), .authenticationFlow):
                startAuthenticationFlow(isAddingAccount: isAddingAccount)
            case (.userSessionFlow, .startAuthentication(let isAddingAccount), .authenticationFlow):
                stopUserSessionFlow()
                startAuthenticationFlow(isAddingAccount: isAddingAccount)
            case (.initial, .startUserSession, .userSessionFlow):
                startUserSessionFlow(isAppLaunch: true, isNewLogin: false)
            case (.authenticationFlow, .startUserSession, .userSessionFlow):
                // TODO: Restore the settings screen when cancelling with isAddingAccount == true.
                authenticationFlowCoordinator = nil
                startUserSessionFlow(isNewLogin: true)
            case (.userSessionFlow, .clearCache, .clearingCache(let userID)):
                stopUserSessionFlow()
                clearCache(userID: userID)
            case (.userSessionFlow, .logout, .loggingOut(let userID)):
                stopUserSessionFlow()
                logout(userID: userID)
            case (.userSessionFlow, .startUserSession, .userSessionFlow):
                stopUserSessionFlow()
                startUserSessionFlow(isNewLogin: false)
            case (.clearingCache, .startAuthentication(let isAddingAccount), .authenticationFlow),
                 (.loggingOut, .startAuthentication(let isAddingAccount), .authenticationFlow):
                hideLoadingIndicator()
                startAuthenticationFlow(isAddingAccount: isAddingAccount)
            case (.clearingCache, .startUserSession, .userSessionFlow),
                 (.loggingOut, .startUserSession, .userSessionFlow):
                hideLoadingIndicator()
                startUserSessionFlow(isNewLogin: false)
            default:
                fatalError("Unhandled transition: \(context)")
            }
        }
        
        stateMachine.addErrorHandler { context in
            fatalError("Unexpected transition: \(context)")
        }
    }
    
    private func setupSubscriptions() {
        userSessionManager.callbacksPublisher
            .sink { [weak self] callback in
                guard let self else { return }
                
                switch callback {
                case .didRestoreSession(let userID):
                    handleRestoredSession(userID: userID)
                case .didRemoveAccount(let userID, let error):
                    handleRemovedAccount(userID: userID, error: error)
                }
            }
            .store(in: &cancellables)
        
        elementCallManager.actionsPublisher
            .sink { [weak self] action in
                guard let self, case .callScreen(let presentation) = action else { return }
                handleCallScreen(presentation)
            }
            .store(in: &cancellables)
    }
    
    private func handleRestoredSession(userID: String) {
        switch stateMachine.state {
        case .initial where userID == userSessionManager.activeSession?.clientProxy.userID,
             .clearingCache(userID):
            stateMachine.tryEvent(.startUserSession(userID: userID))
        default:
            break
        }
    }
    
    private func handleRemovedAccount(userID: String, error: UserSessionManagerError?) {
        switch stateMachine.state {
        case .initial:
            if userSessionManager.userIDs.isEmpty {
                stateMachine.tryEvent(.startAuthentication(isAddingAccount: false))
            } else {
                // Continue waiting while other accounts are restoring.
            }
        case .userSessionFlow(userID), .clearingCache(userID), .loggingOut(userID):
            actionsSubject.send(.closeSecondaryWindows)
            if let activeUserID = userSessionManager.activeSession?.clientProxy.userID {
                stateMachine.tryEvent(.startUserSession(userID: activeUserID))
            } else if userSessionManager.userIDs.isEmpty {
                stateMachine.tryEvent(.startAuthentication(isAddingAccount: false))
            } else {
                // Continue waiting while other accounts are restoring.
                // Nothing shows the next account once it restores yet, however if we were to build
                // account switching by observing the active session then this would come for free.
            }
        default:
            break
        }
        
        // Shown after the transition, as stopping a user session flow retracts every indicator.
        switch error {
        case .remoteLogout:
            break // Show the Device Removed Remotely screen.
        case .failedRestoringSession:
            showLoginErrorToast()
        case .none:
            break
        }
    }
    
    private func startAuthenticationFlow(isAddingAccount: Bool) {
        let navigationStackCoordinator = NavigationStackCoordinator()
        let authenticationService = authenticationServiceFactory.makeAuthenticationService(userSessionManager: userSessionManager,
                                                                                           encryptionKeyProvider: EncryptionKeyProvider(),
                                                                                           classicAppManager: ClassicAppManager(),
                                                                                           appSettings: appSettings,
                                                                                           appHooks: appHooks)
        Task { await authenticationService.setupClassicAppAccountState() }
        
        let coordinator = AuthenticationFlowCoordinator(authenticationService: authenticationService,
                                                        isAddingAccount: isAddingAccount,
                                                        navigationStackCoordinator: navigationStackCoordinator,
                                                        bugReportService: bugReportService,
                                                        appMediator: appMediator,
                                                        appSettings: appSettings,
                                                        appHooks: appHooks,
                                                        userIndicatorController: userIndicatorController)
        coordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .signInComplete(let userSession):
                    userSessionManager.addNewSession(userSession)
                    stateMachine.tryEvent(.startUserSession(userID: userSession.clientProxy.userID))
                }
            }
            .store(in: &cancellables)
        
        authenticationFlowCoordinator = coordinator
        coordinator.start()
        
        navigationRootCoordinator.setRootCoordinator(navigationStackCoordinator)
        
        if let pending = pendingAppRoute.take() {
            if pending.appRoute.isAuthenticationRoute {
                coordinator.handleAppRoute(pending.appRoute, animated: false)
            } else {
                MXLog.info("Ignoring user session app route during authentication.")
            }
        }
    }
    
    private func startUserSessionFlow(isAppLaunch: Bool = false, isNewLogin: Bool) {
        guard let userSession = userSessionManager.activeSession else {
            fatalError("User session not setup")
        }
        
        if let serverName = userSession.clientProxy.userIDServerName {
            analyticsService.signpost.addGlobalTag(.homeserver, value: serverName)
        }
        
        if isAppLaunch {
            analyticsService.signpost.startTransaction(.cachedRoomList)
        }
        
        let flowParameters = CommonFlowParameters(userSession: userSession,
                                                  availableSessionsPublisher: userSessionManager.sessionsPublisher.map { $0.map(UserSessionDetails.init) },
                                                  bugReportService: bugReportService,
                                                  timelineControllerFactory: TimelineControllerFactory(userSettings: userSession.userSettings),
                                                  emojiProvider: EmojiProvider(userSettings: userSession.userSettings),
                                                  linkMetadataProvider: LinkMetadataProvider(),
                                                  appMediator: appMediator,
                                                  analytics: analyticsService,
                                                  userIndicatorController: userIndicatorController,
                                                  stateMachineFactory: StateMachineFactory())
        
        let coordinator = UserSessionFlowCoordinator(isNewLogin: isNewLogin,
                                                     navigationRootCoordinator: navigationRootCoordinator,
                                                     appLockService: appLockService,
                                                     flowParameters: flowParameters)
        coordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .logout, .accountDeactivated:
                    stateMachine.tryEvent(.logout)
                case .clearCache:
                    stateMachine.tryEvent(.clearCache)
                case .forceLogout:
                    actionsSubject.send(.forceLogout)
                }
            }
            .store(in: &cancellables)
        
        userSessionFlowCoordinator = coordinator
        coordinator.start()
        
        if let pending = pendingAppRoute.take() {
            if pending.appRoute.isAuthenticationRoute {
                // TODO: Start a flow to add a new account?
            } else {
                handleUserSessionRoute(pending.appRoute, userID: pending.userID, awaitsRoom: pending.awaitsRoom, animated: false)
            }
        }
    }
    
    private func handleUserSessionRoute(_ appRoute: AppRoute, userID: String?, awaitsRoom: Bool, animated: Bool) {
        guard let userSession = userSessionManager.activeSession else {
            fatalError("User session not setup")
        }
        
        if let userID, userID != userSession.clientProxy.userID {
            // TODO: Switch to the route's account (element-hq/element-meta#3328).
            MXLog.info("Ignoring an app route for \(userID), it isn't the active account.")
            return
        }
        
        if awaitsRoom, case .room(let roomID, _) = appRoute {
            userSession.clientProxy.roomsToAwait.insert(roomID)
        }
        
        minimizeFullScreenCall()
        userSessionFlowCoordinator?.handleAppRoute(appRoute, animated: animated)
    }
    
    private func stopUserSessionFlow() {
        userIndicatorController.retractAllIndicators()
        userSessionFlowCoordinator?.stop()
        userSessionFlowCoordinator = nil
    }
    
    private func logout(userID: String) {
        navigationRootCoordinator.setRootCoordinator(PlaceholderScreenCoordinator(hideBrandChrome: appSettings.hideBrandChrome))
        showLoadingIndicator()
        
        // The account's removal moves on to the next account or authentication.
        Task { await userSessionManager.logout(userID: userID) }
    }
    
    private func clearCache(userID: String) {
        navigationRootCoordinator.setRootCoordinator(PlaceholderScreenCoordinator(hideBrandChrome: appSettings.hideBrandChrome))
        showLoadingIndicator()
        
        // The account's restoration moves on to its flow again, or its removal to the next account or authentication.
        Task { await userSessionManager.clearCaches(userID: userID) }
    }
    
    // MARK: - Calls
    
    /// Hands the call to the `ElementCallManager`, which keeps it pending until its account's session is live.
    private func handleCallRoute(roomID: String, isVoiceCall: Bool, answeredFromCallKit: Bool, userID: String?) {
        switch stateMachine.state {
        case .initial, .userSessionFlow:
            break
        case .authenticationFlow, .clearingCache, .loggingOut:
            MXLog.info("Ignoring the call in \(roomID), no account's screens are showing.")
            return
        }
        
        guard let callUserID = userID ?? userSessionManager.userIDs.first else {
            MXLog.info("Ignoring the call in \(roomID), no account is signed in.")
            return
        }
        
        guard userSessionManager.userIDs.contains(callUserID) else {
            MXLog.info("Ignoring the call for \(callUserID), it isn't signed in.")
            return
        }
        
        elementCallManager.requestCall(userID: callUserID, roomID: roomID, isVoiceCall: isVoiceCall, answeredFromCallKit: answeredFromCallKit)
    }
    
    /// Minimizes a full screen call, which would hide the screen a route leads to.
    private func minimizeFullScreenCall() {
        guard case .fullScreen(let callScreen) = callScreenStateMachine.state else { return }
        userSessionManager.session(for: callScreen.userID)?.elementCallService.minimizeCall()
    }
    
    private func configureCallScreenStateMachine() {
        callScreenStateMachine.addRouteMapping { event, fromState, _ in
            switch (fromState, event) {
            case (_, .present(let callScreen)):
                .fullScreen(callScreen)
            case (.fullScreen(let callScreen), .minimize):
                .minimized(callScreen)
            case (.minimized(let callScreen), .restore):
                .fullScreen(callScreen)
            case (.fullScreen, .dismiss), (.minimized, .dismiss):
                .notPresented
            default:
                nil
            }
        }
        
        callScreenStateMachine.addAnyHandler(.any => .any) { [weak self] context in
            guard let self else { return }
            
            MXLog.info("Call screen transitioning from `\(context.fromState)` to `\(context.toState)` with event `\(String(describing: context.event))`.")
            
            switch context.toState {
            case .fullScreen:
                navigationRootCoordinator.setOverlayPresentationMode(.fullScreen)
            case .minimized:
                navigationRootCoordinator.setOverlayPresentationMode(.minimized)
            case .notPresented:
                callScreenCancellable = nil
                callScreenPictureInPictureController = nil
                navigationRootCoordinator.setOverlayCoordinator(nil)
            }
        }
        
        callScreenStateMachine.addErrorHandler { context in
            // These events can be redundant, e.g. a call screen that is asked to go away twice.
            MXLog.info("Call screen ignoring event `\(String(describing: context.event))` in state `\(context.fromState)`.")
        }
    }
    
    /// Shows the call screen above every account's screens, with the session of the call's account.
    private func handleCallScreen(_ presentation: CallScreenPresentation) {
        switch presentation {
        case .present(let userID, let kind):
            guard let userSession = userSessionManager.session(for: userID) else {
                MXLog.error("Cannot present the call screen, \(userID) has no session.")
                return
            }
            
            switch kind {
            case .webView(let call):
                presentWebCallScreen(for: call, userSession: userSession)
            case .native:
                presentNativeCallScreen(userSession: userSession)
            }
        case .minimize:
            minimizeCallScreen()
        case .restore:
            restoreCallScreen()
        case .dismiss:
            dismissCallScreen()
        }
    }
    
    private func presentWebCallScreen(for call: ElementCallServiceAction.RoomCall, userSession: UserSessionProtocol) {
        let colorScheme: ColorScheme = appMediator.windowManager.mainWindow.traitCollection.userInterfaceStyle == .light ? .light : .dark
        let configuration = ElementCallConfiguration(roomProxy: call.roomProxy,
                                                     clientProxy: userSession.clientProxy,
                                                     clientID: InfoPlistReader.main.bundleIdentifier,
                                                     elementCallBaseURL: userSession.userSettings.app.elementCallBaseURL,
                                                     elementCallBaseURLOverride: userSession.userSettings.app.elementCallBaseURLOverride,
                                                     voiceOnly: call.isVoiceCall,
                                                     colorScheme: colorScheme)
        
        let callScreenCoordinator = CallScreenCoordinator(parameters: .init(userSession: userSession,
                                                                            configuration: configuration,
                                                                            allowPictureInPicture: true,
                                                                            analytics: analyticsService))
        
        // Subscribed before the overlay changes: a replaced call hangs up as it goes, and its late actions must leave this call alone.
        callScreenCancellable = callScreenCoordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .pictureInPictureIsAvailable(let controller):
                    callScreenPictureInPictureController = controller
                case .pictureInPictureStarted:
                    callScreenStateMachine.tryEvent(.minimize)
                case .pictureInPictureStopped:
                    callScreenStateMachine.tryEvent(.restore)
                case .dismiss:
                    callScreenStateMachine.tryEvent(.dismiss)
                }
            }
        
        callScreenPictureInPictureController = nil
        navigationRootCoordinator.setOverlayCoordinator(callScreenCoordinator, animated: true)
        callScreenStateMachine.tryEvent(.present(.init(userID: userSession.clientProxy.userID, isNative: false)))
        
        analyticsService.track(screen: .RoomCall)
    }
    
    private func presentNativeCallScreen(userSession: UserSessionProtocol) {
        guard let controller = userSession.elementCallService.nativeCallController else {
            MXLog.error("Cannot present a native call without a call stack")
            return
        }
        
        let callScreen = PresentedCallScreen(userID: userSession.clientProxy.userID, isNative: true)
        
        if case .minimized(callScreen) = callScreenStateMachine.state {
            callScreenStateMachine.tryEvent(.restore)
            return
        }
        
        guard callScreenStateMachine.state != .fullScreen(callScreen) else { return }
        
        let coordinator = NativeCallScreenCoordinator(parameters: .init(controller: controller))
        
        if ProcessInfo.processInfo.isiOSAppOnMac {
            // The call gets its own window, leaving the overlay alone.
            appMediator.windowManager.registerCoordinator(coordinator, flowCoordinator: nil, forWindowType: .call)
        } else {
            callScreenCancellable = nil
            navigationRootCoordinator.setOverlayCoordinator(coordinator, animated: true)
            callScreenStateMachine.tryEvent(.present(callScreen))
            analyticsService.track(screen: .RoomCall)
        }
    }
    
    private func minimizeCallScreen() {
        guard case .fullScreen(let callScreen) = callScreenStateMachine.state else { return }
        
        guard !callScreen.isNative else {
            callScreenStateMachine.tryEvent(.minimize)
            return
        }
        
        guard let callScreenPictureInPictureController else {
            MXLog.warning("Picture in picture isn't available, dismissing the call screen.")
            callScreenStateMachine.tryEvent(.dismiss)
            return
        }
        
        MXLog.info("Starting picture in picture to hide the call screen.")
        callScreenPictureInPictureController.startPictureInPicture()
        callScreenStateMachine.tryEvent(.minimize)
    }
    
    private func restoreCallScreen() {
        switch callScreenStateMachine.state {
        case .notPresented:
            break
        case .fullScreen(let callScreen), .minimized(let callScreen):
            if !callScreen.isNative, let callScreenPictureInPictureController, callScreenPictureInPictureController.isPictureInPictureActive {
                MXLog.info("Returning to the call on screen.")
                // Stopping comes back as `.pictureInPictureStopped`, which restores the screen.
                callScreenPictureInPictureController.stopPictureInPicture()
            } else {
                // Nothing would come back when picture in picture isn't running, e.g. when it failed to start.
                callScreenStateMachine.tryEvent(.restore)
            }
        }
    }
    
    private func dismissCallScreen() {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            appMediator.windowManager.closeSecondaryWindow(forType: .call)
        }
        
        callScreenStateMachine.tryEvent(.dismiss)
    }
    
    // MARK: - User Indicators
    
    private var loadingIndicatorID: String {
        "\(Self.self)-Loading"
    }
    
    private func showLoadingIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: loadingIndicatorID,
                                                              type: .modal,
                                                              title: L10n.commonLoading,
                                                              persistent: true))
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(loadingIndicatorID)
    }
    
    private func showLoginErrorToast() {
        userIndicatorController.submitIndicator(UserIndicator(title: "Failed logging in"))
    }
}
