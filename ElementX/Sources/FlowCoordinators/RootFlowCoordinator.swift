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
    /// Authentication completed, the session still needs adding to the `UserSessionManager`.
    case signInComplete(userSession: UserSessionProtocol)
    case logout
    /// Clear the active account's caches. The continuation is used to signal success/failure.
    case clearCache(AsyncStream<Result<Void, ClearCacheError>>.Continuation)
    /// Logout and disable App Lock without any confirmation. The user forgot their PIN.
    case forceLogout
}

enum ClearCacheError: Error {
    /// The account's session wasn't restored after clearing its caches.
    case failedRestoringSession
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
        case userSessionFlow
        /// A placeholder is being shown while clearing caches.
        case clearingCache
    }
    
    enum Event: EventType {
        /// Request presentation of the authentication flow, either with no account signed in or to sign in another one.
        case startAuthentication(isAddingAccount: Bool)
        /// Request presentation of the active account's user session flow.
        case startUserSession
        /// Request clearing the active account's caches.
        case clearCache
    }
    
    private let stateMachine: StateMachine<State, Event>
    
    /// Information about an ``AppRoute`` that can be re-played when ready.
    private struct PendingAppRoute {
        let appRoute: AppRoute
        let userID: String?
        let awaitsRoom: Bool
    }
    
    /// A stored route that was received before the flow was ready.
    private var pendingAppRoute: PendingAppRoute?
    
    /// The web call on the overlay, with everything that belongs to that call alone.
    private struct WebCall {
        let userSession: UserSessionProtocol
        let roomID: String
        let coordinator: CallScreenCoordinator
        var pictureInPictureController: AVPictureInPictureController?
        var cancellables: Set<AnyCancellable>
    }
    
    /// A call to open for an account, from a room, CallKit or Recents.
    private struct PendingCall {
        let userID: String
        let roomID: String
        let isVoiceCall: Bool
        let answeredFromCallKit: Bool
    }
    
    private var webCall: WebCall?
    /// A call waiting for its account's session to be live. One at a time, a newer call drops it.
    private var pendingCall: PendingCall?
    private var pendingCallCancellable: AnyCancellable?
    // TODO: Observe each call's own service once each call builds its own stack.
    /// The active account's service, which runs the native call stack and drives its screen.
    private var nativeCallService: ElementCallServiceProtocol?
    private var nativeCallPresentationCancellable: AnyCancellable?
    /// The active account while it signs out or clears its caches. Its calls are dropped until a user session flow starts.
    private var leavingUserID: String?
    
    private var cancellables = Set<AnyCancellable>()
    private var clearCacheTask: AnyCancellable?
    
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
        configureStateMachine()
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
            case .clearingCache:
                break
            }
        case .oAuthCallback(let url):
            if case .authenticationFlow = stateMachine.state {
                authenticationFlowCoordinator?.handleOAuthCallbackURL(url)
            } else {
                MXLog.error("Received an OAuth callback without an authentication flow.")
            }
        case .roomList:
            if stateMachine.state == .userSessionFlow {
                userSessionFlowCoordinator?.handleAppRoute(appRoute, animated: animated)
            } else {
                stateMachine.tryEvent(.startUserSession)
            }
        case let .call(roomID, isVoiceCall, answeredFromCallKit):
            presentCall(userID: userID, roomID: roomID, isVoiceCall: isVoiceCall, answeredFromCallKit: answeredFromCallKit)
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
            case .clearingCache:
                break
            }
        }
    }
    
    func clearRoute(animated: Bool) {
        switch stateMachine.state {
        case .initial, .clearingCache:
            break
        case .authenticationFlow:
            authenticationFlowCoordinator?.clearRoute(animated: animated)
        case .userSessionFlow:
            userSessionFlowCoordinator?.clearRoute(animated: animated)
        }
        
        navigationRootCoordinator.setRootCoordinator(nil, animated: animated)
    }
    
    // TODO: Take the account too, a room ID alone can't tell accounts' rooms apart.
    func isDisplayingRoomScreen(withRoomID roomID: String) -> Bool {
        guard stateMachine.state == .userSessionFlow else { return false }
        return userSessionFlowCoordinator?.isDisplayingRoomScreen(withRoomID: roomID) ?? false
    }
    
    /// Opens the room's call as the session's account, returning to it when it's already open.
    /// Any other call is replaced.
    func presentCall(roomProxy: JoinedRoomProxyProtocol, isVoiceCall: Bool, answeredFromCallKit: Bool, userSession: UserSessionProtocol) {
        if let heldCall = pendingCall.take() {
            pendingCallCancellable = nil
            drop(heldCall, because: "a newer call opened")
        }
        
        // A service with the native call stack runs the call and drives its screen through its presentation publisher.
        if userSession.elementCallService.handleNativeCallRequest(roomProxy: roomProxy, isVoiceCall: isVoiceCall, answeredFromCallKit: answeredFromCallKit) {
            return
        }
        
        // Native calls replace web calls, so with them on a call without a native stack can't open.
        guard !userSession.userSettings.app.nativeCallEnabled else {
            let call = PendingCall(userID: userSession.clientProxy.userID, roomID: roomProxy.id, isVoiceCall: isVoiceCall, answeredFromCallKit: answeredFromCallKit)
            drop(call, because: "there's no native call stack for it")
            return
        }
        
        if let webCall,
           webCall.userSession.clientProxy.userID == userSession.clientProxy.userID,
           webCall.roomID == roomProxy.id {
            MXLog.info("Returning to the ongoing call.")
            webCall.pictureInPictureController?.stopPictureInPicture()
            return
        }
        
        presentWebCall(roomProxy: roomProxy, isVoiceCall: isVoiceCall, userSession: userSession)
    }
    
    /// Hides the call screen: a native call minimizes, a web call moves to picture in picture or ends without it.
    func minimizeCall() {
        if navigationRootCoordinator.overlayCoordinator is NativeCallScreenCoordinator {
            nativeCallService?.minimizeNativeCall()
            return
        }
        
        guard let webCall else { return }
        
        guard let pictureInPictureController = webCall.pictureInPictureController else {
            MXLog.warning("Picture in picture isn't available, dismissing the call screen.")
            navigationRootCoordinator.setOverlayCoordinator(nil)
            return
        }
        
        MXLog.info("Starting picture in picture to hide the call screen.")
        pictureInPictureController.startPictureInPicture()
        navigationRootCoordinator.setOverlayPresentationMode(.minimized)
    }
    
    // MARK: - Private
    
    private func configureStateMachine() {
        stateMachine.addRouteMapping { event, fromState, _ in
            switch (fromState, event) {
            case (.initial, .startAuthentication(isAddingAccount: false)):
                .authenticationFlow(isAddingAccount: false)
            case (.initial, .startUserSession):
                .userSessionFlow
                
            case (.authenticationFlow, .startUserSession):
                .userSessionFlow
                
            case (.userSessionFlow, .startAuthentication(let isAddingAccount)):
                .authenticationFlow(isAddingAccount: isAddingAccount)
            case (.userSessionFlow, .clearCache):
                .clearingCache
                
            case (.clearingCache, .startAuthentication(isAddingAccount: false)):
                .authenticationFlow(isAddingAccount: false)
            case (.clearingCache, .startUserSession):
                .userSessionFlow
                
            default:
                nil
            }
        }
        
        stateMachine.addAnyHandler(.any => .any) { [weak self] context in
            guard let self else { return }
            
            MXLog.info("Transitioning from `\(context.fromState)` to `\(context.toState)` with event `\(String(describing: context.event))`.")
            
            switch (context.fromState, context.event, context.toState) {
            case (.initial, .startAuthentication(let isAddingAccount), .authenticationFlow),
                 (.clearingCache, .startAuthentication(let isAddingAccount), .authenticationFlow):
                startAuthenticationFlow(isAddingAccount: isAddingAccount)
            case (.userSessionFlow, .startAuthentication(let isAddingAccount), .authenticationFlow):
                stopUserSessionFlow()
                if !isAddingAccount {
                    closeCallOfLeavingAccount()
                }
                startAuthenticationFlow(isAddingAccount: isAddingAccount)
            case (.initial, .startUserSession, .userSessionFlow):
                startUserSessionFlow(isNewLogin: false)
            case (.authenticationFlow, .startUserSession, .userSessionFlow):
                // TODO: Restore the settings screen when cancelling with isAddingAccount == true .
                authenticationFlowCoordinator = nil
                startUserSessionFlow(isNewLogin: true)
            case (.userSessionFlow, .clearCache, .clearingCache):
                stopUserSessionFlow()
                closeCallOfLeavingAccount()
                clearCache()
            case (.clearingCache, .startUserSession, .userSessionFlow):
                startUserSessionFlow(isNewLogin: false)
            default:
                fatalError("Unhandled transition: \(context)")
            }
        }
        
        stateMachine.addErrorHandler { context in
            fatalError("Unexpected transition: \(context)")
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
                    actionsSubject.send(.signInComplete(userSession: userSession))
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
    
    private func startUserSessionFlow(isNewLogin: Bool) {
        guard let userSession = userSessionManager.activeSession else {
            fatalError("User session not setup")
        }
        
        leavingUserID = nil
        
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
        let userID = userSession.clientProxy.userID
        coordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .logout:
                    actionsSubject.send(.logout)
                case .clearCache:
                    stateMachine.tryEvent(.clearCache)
                case .forceLogout:
                    actionsSubject.send(.forceLogout)
                case .presentCall(let roomProxy, let isVoiceCall):
                    presentCall(roomProxy: roomProxy, isVoiceCall: isVoiceCall, userID: userID)
                case .minimizeCall:
                    minimizeCall()
                }
            }
            .store(in: &cancellables)
        
        userSessionFlowCoordinator = coordinator
        coordinator.start()
        observeNativeCalls(of: userSession.elementCallService)
        
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
        
        userSessionFlowCoordinator?.handleAppRoute(appRoute, animated: animated)
    }
    
    private func stopUserSessionFlow() {
        userSessionFlowCoordinator?.stop()
        stopObservingNativeCalls()
        userSessionFlowCoordinator = nil
    }
    
    private func clearCache() {
        navigationRootCoordinator.setRootCoordinator(PlaceholderScreenCoordinator(hideBrandChrome: appSettings.hideBrandChrome))
        
        let (stream, continuation) = AsyncStream<Result<Void, ClearCacheError>>.makeStream()
        actionsSubject.send(.clearCache(continuation))
        
        clearCacheTask = Task { [weak self] in
            defer { self?.clearCacheTask = nil }
            guard case .success = await stream.first() else { return }
            self?.stateMachine.tryEvent(.startUserSession)
        }
        .asCancellable()
    }
    
    // MARK: - Calls by account
    
    /// Opens a call a room asked for, with its account's session.
    private func presentCall(roomProxy: JoinedRoomProxyProtocol, isVoiceCall: Bool, userID: String) {
        // Looked up, not captured by the flow's sink, which outlives the session.
        guard let userSession = userSessionManager.session(for: userID) else {
            MXLog.error("Cannot present the call, \(userID) has no session.")
            return
        }
        
        presentCall(roomProxy: roomProxy, isVoiceCall: isVoiceCall, answeredFromCallKit: false, userSession: userSession)
    }
    
    /// Opens a call that comes in by account, answered through CallKit or started from Recents,
    /// above every account's screens, whatever the root shows.
    ///
    /// An account with no live session yet has its call held until it has one, one call at a time.
    /// A call that can't open, or whose account is leaving, is dropped.
    private func presentCall(userID: String?, roomID: String, isVoiceCall: Bool, answeredFromCallKit: Bool) {
        guard let userID = userID ?? userSessionManager.userIDs.first else {
            // TODO: Call back once an account signs in again (element-hq/element-meta#3325).
            MXLog.info("Dropping the call in \(roomID), no account is signed in.")
            return
        }
        
        let call = PendingCall(userID: userID, roomID: roomID, isVoiceCall: isVoiceCall, answeredFromCallKit: answeredFromCallKit)
        
        guard userSessionManager.userIDs.contains(userID) else {
            drop(call, because: "\(userID) isn't signed in")
            return
        }
        
        guard userID != leavingUserID else {
            drop(call, because: "\(userID) is leaving")
            return
        }
        
        guard let userSession = userSessionManager.session(for: userID) else {
            hold(call)
            return
        }
        
        Task {
            let room = await userSession.clientProxy.roomForIdentifier(roomID)
            
            guard userID != leavingUserID, userSessionManager.session(for: userID)?.clientProxy === userSession.clientProxy else {
                drop(call, because: "\(userID) left while its room loaded")
                return
            }
            
            guard case let .joined(roomProxy) = room else {
                drop(call, because: "it isn't a joined room")
                return
            }
            
            presentCall(roomProxy: roomProxy, isVoiceCall: isVoiceCall, answeredFromCallKit: answeredFromCallKit, userSession: userSession)
        }
    }
    
    private func hold(_ call: PendingCall) {
        if let replacedCall = pendingCall {
            drop(replacedCall, because: "a newer call replaced it")
        }
        
        MXLog.info("Holding the call in \(call.roomID) until \(call.userID) has a live session")
        pendingCall = call
        
        // Not received on the main queue, so the session is seen in the same step that adds it.
        pendingCallCancellable = userSessionManager.sessionsPublisher
            .sink { [weak self] userSessions in
                guard let self else { return }
                
                guard userSessionManager.userIDs.contains(call.userID) else {
                    pendingCall = nil
                    pendingCallCancellable = nil
                    drop(call, because: "\(call.userID) isn't signed in any more")
                    return
                }
                
                guard userSessions.contains(where: { $0.clientProxy.userID == call.userID }) else { return }
                openPendingCall()
            }
    }
    
    private func openPendingCall() {
        guard let call = pendingCall.take() else { return }
        pendingCallCancellable = nil
        
        // Deferred so the account's state is checked again once the step that published its session is over.
        Task {
            presentCall(userID: call.userID, roomID: call.roomID, isVoiceCall: call.isVoiceCall, answeredFromCallKit: call.answeredFromCallKit)
        }
    }
    
    private func drop(_ call: PendingCall, because reason: String) {
        MXLog.warning("Dropping the call in \(call.roomID): \(reason)")
        
        if call.answeredFromCallKit {
            elementCallManager.dropAnsweredCall(userID: call.userID, roomID: call.roomID)
        }
    }
    
    /// The active account signs out or clears its caches: its web call goes with it, and its new calls are dropped.
    private func closeCallOfLeavingAccount() {
        guard let userID = userSessionManager.activeSession?.clientProxy.userID else { return }
        
        leavingUserID = userID
        
        if webCall?.userSession.clientProxy.userID == userID {
            navigationRootCoordinator.setOverlayCoordinator(nil)
        }
    }
    
    // MARK: - Web calls
    
    private func presentWebCall(roomProxy: JoinedRoomProxyProtocol, isVoiceCall: Bool, userSession: UserSessionProtocol) {
        let colorScheme: ColorScheme = appMediator.windowManager.mainWindow.traitCollection.userInterfaceStyle == .light ? .light : .dark
        let configuration = ElementCallConfiguration(roomProxy: roomProxy,
                                                     clientProxy: userSession.clientProxy,
                                                     clientID: InfoPlistReader.main.bundleIdentifier,
                                                     elementCallBaseURL: userSession.userSettings.app.elementCallBaseURL,
                                                     elementCallBaseURLOverride: userSession.userSettings.app.elementCallBaseURLOverride,
                                                     voiceOnly: isVoiceCall,
                                                     colorScheme: colorScheme)
        
        let coordinator = CallScreenCoordinator(parameters: .init(userSession: userSession,
                                                                  configuration: configuration,
                                                                  allowPictureInPicture: true,
                                                                  analytics: analyticsService))
        
        var callCancellables = Set<AnyCancellable>()
        coordinator.actions
            .sink { [weak self, weak coordinator] action in
                guard let self, let coordinator else { return }
                handleWebCallAction(action, coordinator: coordinator)
            }
            .store(in: &callCancellables)
        
        // Replacing the screen runs its `stop()`, ending the call, and then this callback.
        // It must only ever clear this call's record, never the one replacing it.
        navigationRootCoordinator.setOverlayCoordinator(coordinator) { [weak self, weak coordinator] in
            guard let self, webCall?.coordinator === coordinator else { return }
            webCall = nil
        }
        
        webCall = WebCall(userSession: userSession,
                          roomID: roomProxy.id,
                          coordinator: coordinator,
                          pictureInPictureController: nil,
                          cancellables: callCancellables)
        
        analyticsService.track(screen: .RoomCall)
    }
    
    private func handleWebCallAction(_ action: CallScreenCoordinatorAction, coordinator: CallScreenCoordinator) {
        // A replaced call's late actions must leave the call that replaced it alone.
        guard navigationRootCoordinator.overlayCoordinator === coordinator else { return }
        
        switch action {
        case .pictureInPictureIsAvailable(let controller):
            webCall?.pictureInPictureController = controller
        case .pictureInPictureStarted:
            MXLog.info("Hiding the call for picture in picture.")
            navigationRootCoordinator.setOverlayPresentationMode(.minimized)
        case .pictureInPictureStopped:
            MXLog.info("Restoring the call after picture in picture.")
            navigationRootCoordinator.setOverlayPresentationMode(.fullScreen)
        case .dismiss:
            navigationRootCoordinator.setOverlayCoordinator(nil)
        }
    }
    
    // MARK: - Native calls
    
    private func observeNativeCalls(of service: ElementCallServiceProtocol) {
        nativeCallService = service
        nativeCallPresentationCancellable = service.nativeCallPresentationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] presentation in
                self?.handleNativeCall(presentation)
            }
    }
    
    private func stopObservingNativeCalls() {
        nativeCallService = nil
        nativeCallPresentationCancellable = nil
        // The `.dismiss` the stopped stack sends hops to the main queue, after this sink is gone.
        dismissNativeCall()
    }
    
    private func handleNativeCall(_ presentation: NativeCallPresentation) {
        switch presentation {
        case .present:
            presentNativeCall()
        case .restore:
            restoreNativeCall()
        case .minimize:
            navigationRootCoordinator.setOverlayPresentationMode(.minimized)
        case .dismiss:
            dismissNativeCall()
        }
    }
    
    private func presentNativeCall() {
        guard let controller = nativeCallService?.nativeCallController else {
            MXLog.error("Cannot present a native call without a call stack")
            return
        }
        
        guard !(navigationRootCoordinator.overlayCoordinator is NativeCallScreenCoordinator) else {
            restoreNativeCall()
            return
        }
        
        let coordinator = NativeCallScreenCoordinator(parameters: .init(controller: controller))
        
        if ProcessInfo.processInfo.isiOSAppOnMac {
            appMediator.windowManager.closeSecondaryWindow(forType: .call)
            appMediator.windowManager.registerCoordinator(coordinator, flowCoordinator: nil, forWindowType: .call)
        } else {
            navigationRootCoordinator.setOverlayCoordinator(coordinator)
            analyticsService.track(screen: .RoomCall)
        }
    }
    
    private func restoreNativeCall() {
        nativeCallService?.restoreNativeCall()
        navigationRootCoordinator.setOverlayPresentationMode(.fullScreen)
    }
    
    private func dismissNativeCall() {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            appMediator.windowManager.closeSecondaryWindow(forType: .call)
        } else if navigationRootCoordinator.overlayCoordinator is NativeCallScreenCoordinator {
            navigationRootCoordinator.setOverlayCoordinator(nil)
        }
    }
}
