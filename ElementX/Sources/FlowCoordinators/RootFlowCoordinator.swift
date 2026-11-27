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
    private let sessionVerificationManager: SessionVerificationManagerProtocol
    private let appLockService: AppLockServiceProtocol
    private let bugReportService: BugReportServiceProtocol
    private let appMediator: AppMediatorProtocol
    private let appSettings: AppSettings
    private let appHooks: AppHooks
    private let analyticsService: AnalyticsServiceProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let targetContext: Target.Context
    private let authenticationServiceFactory: AuthenticationServiceFactoryProtocol
    
    private var authenticationFlowCoordinator: AuthenticationFlowCoordinator?
    private var userSessionFlowCoordinator: UserSessionFlowCoordinator?
    
    enum State: StateType {
        /// The state machine hasn't started.
        case initial(presented: PresentedState?)
        /// The authentication flow is the root.
        case authenticationFlow(isAddingAccount: Bool, presented: PresentedState?)
        /// A user session flow is the root.
        case userSessionFlow(userID: String, presented: PresentedState?)
        /// A placeholder is being shown while clearing caches.
        case clearingCache(userID: String, presented: PresentedState?)
        /// A placeholder is being shown while the active account logs out.
        case loggingOut(userID: String, presented: PresentedState?)
    }
    
    /// Something presented above the root, along with whatever was presented before it.
    indirect enum PresentedState: Hashable {
        /// The share sheet is picking the room that a share without one is sent to.
        case shareRoomSelection(previousState: PresentedState?)
        /// The session verification sheet is verifying the given account, which may not be the shown one.
        case sessionVerification(userID: String, previousState: PresentedState?)
        /// The permalink sheet is shown. Not built yet.
        case permalink(previousState: PresentedState?)
        /// The full screen cover is telling the user that the server logged out one or more accounts.
        case remoteLogout(previousState: PresentedState?)
        
        /// The call screen covers every account's screens, or when minimized stays on the
        /// overlay but is hidden, in picture in picture or the system's call window.
        case callScreen(PresentedCallScreen, isMinimized: Bool, previousState: PresentedState?)
    }
    
    enum Event: EventType {
        /// Request presentation of the authentication flow, either with no account signed in or to sign in another one.
        case startAuthentication(isAddingAccount: Bool)
        /// Request presentation of the given account's user session flow.
        case startUserSession(userID: String)
        /// Return to the given account's settings flow after cancelling adding another account.
        case cancelAddingAccount(userID: String)
        /// Request clearing the active account's caches.
        case clearCache
        /// Request logging out the active account.
        case logout
        
        case presentShareRoomSelection
        case dismissedShareRoomSelection
        case presentSessionVerification(userID: String)
        case dismissedSessionVerification
        case presentPermalink
        case dismissedPermalink
        case startRemoteLogoutFlow
        case stopRemoteLogoutFlow
        
        /// Show a call screen full screen, replacing any other.
        case presentCallScreen(PresentedCallScreen)
        case minimizeCallScreen
        case restoreCallScreen
        case dismissCallScreen
    }
    
    struct EventUserInfo {
        let animated: Bool
        var sharePayload: ShareExtensionPayload?
        var sessionVerificationRequest: SessionVerificationRequest?
        var userSessionDetails: UserSessionDetails?
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
    
    private var remoteLogoutFlowCoordinator: RemoteLogoutFlowCoordinator?
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<RootFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<RootFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(navigationRootCoordinator: NavigationRootCoordinator,
         userSessionManager: UserSessionManagerProtocol,
         elementCallManager: ElementCallManagerProtocol,
         sessionVerificationManager: SessionVerificationManagerProtocol,
         appLockService: AppLockServiceProtocol,
         bugReportService: BugReportServiceProtocol,
         appMediator: AppMediatorProtocol,
         appSettings: AppSettings,
         appHooks: AppHooks,
         analyticsService: AnalyticsServiceProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         targetContext: Target.Context,
         authenticationServiceFactory: AuthenticationServiceFactoryProtocol = AuthenticationServiceFactory()) {
        self.navigationRootCoordinator = navigationRootCoordinator
        self.userSessionManager = userSessionManager
        self.elementCallManager = elementCallManager
        self.sessionVerificationManager = sessionVerificationManager
        self.appLockService = appLockService
        self.bugReportService = bugReportService
        self.appMediator = appMediator
        self.appSettings = appSettings
        self.appHooks = appHooks
        self.analyticsService = analyticsService
        self.userIndicatorController = userIndicatorController
        self.targetContext = targetContext
        self.authenticationServiceFactory = authenticationServiceFactory
        
        stateMachine = .init(state: .initial(presented: nil))
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
    
    // swiftlint:disable:next function_body_length
    private func configureStateMachine() {
        stateMachine.addRouteMapping { event, fromState, _ in
            guard let event else { return nil }
            
            return switch (fromState, event) {
            case (.initial(let presented), .startAuthentication(isAddingAccount: false)):
                .authenticationFlow(isAddingAccount: false, presented: presented)
            case (.initial(let presented), .startUserSession(let userID)):
                .userSessionFlow(userID: userID, presented: presented)
                
            case (.authenticationFlow(_, let presented), .startUserSession(let userID)):
                .userSessionFlow(userID: userID, presented: presented)
            case (.authenticationFlow(isAddingAccount: true, let presented), .cancelAddingAccount(let userID)):
                .userSessionFlow(userID: userID, presented: presented)
            case (.authenticationFlow(isAddingAccount: true, let presented), .startAuthentication(isAddingAccount: false)):
                .authenticationFlow(isAddingAccount: false, presented: presented)
                
            case (.userSessionFlow(_, let presented), .startAuthentication(let isAddingAccount)):
                .authenticationFlow(isAddingAccount: isAddingAccount, presented: presented)
            case (.userSessionFlow(let userID, let presented), .clearCache):
                .clearingCache(userID: userID, presented: presented)
            case (.userSessionFlow(let userID, let presented), .logout):
                .loggingOut(userID: userID, presented: presented)
            case (.userSessionFlow(_, let presented), .startUserSession(let userID)):
                .userSessionFlow(userID: userID, presented: presented)
                
            case (.clearingCache(_, let presented), .startAuthentication(isAddingAccount: false)):
                .authenticationFlow(isAddingAccount: false, presented: presented)
            case (.clearingCache(_, let presented), .startUserSession(let userID)):
                .userSessionFlow(userID: userID, presented: presented)
                
            case (.loggingOut(_, let presented), .startAuthentication(isAddingAccount: false)):
                .authenticationFlow(isAddingAccount: false, presented: presented)
            case (.loggingOut(_, let presented), .startUserSession(let userID)):
                .userSessionFlow(userID: userID, presented: presented)
                
            // Not while a verification is shown, which takes priority over any share,
            // or while another share is shown, which must be dismissed first.
            case (.userSessionFlow(let userID, let presented), .presentShareRoomSelection)
                where !fromState.isPresenting(.sessionVerification) && !fromState.isPresenting(.shareRoomSelection):
                .userSessionFlow(userID: userID, presented: .shareRoomSelection(previousState: presented))
            case (_, .dismissedShareRoomSelection) where fromState.isPresenting(.shareRoomSelection):
                fromState.removingPresented(.shareRoomSelection)
                
            // A second request would cut off the verification in progress.
            case (_, .presentSessionVerification(let userID)) where !fromState.isPresenting(.sessionVerification):
                fromState.presenting(.sessionVerification(userID: userID, previousState: fromState.presented))
            case (_, .dismissedSessionVerification) where fromState.isPresenting(.sessionVerification):
                fromState.removingPresented(.sessionVerification)
                
            case (.userSessionFlow(let userID, let presented), .presentPermalink)
                where !fromState.isPresenting(.sessionVerification) && !fromState.isPresenting(.permalink):
                .userSessionFlow(userID: userID, presented: .permalink(previousState: presented))
            case (_, .dismissedPermalink) where fromState.isPresenting(.permalink):
                fromState.removingPresented(.permalink)
                
            // Further logged out accounts are appended to the cover that's already shown.
            case (_, .startRemoteLogoutFlow) where !fromState.isPresenting(.remoteLogout):
                fromState.presenting(.remoteLogout(previousState: fromState.presented))
            case (_, .stopRemoteLogoutFlow) where fromState.isPresenting(.remoteLogout):
                fromState.removingPresented(.remoteLogout)
                
            // Another call is replaced where it is, otherwise the call goes on top.
            case (_, .presentCallScreen(let callScreen)) where fromState.isPresenting(.callScreen):
                fromState.replacingCallScreen(with: callScreen, isMinimized: false)
            case (_, .presentCallScreen(let callScreen)):
                fromState.presenting(.callScreen(callScreen, isMinimized: false, previousState: fromState.presented))
            case (_, .minimizeCallScreen) where fromState.presented?.isCallScreenMinimized == false:
                fromState.replacingCallScreen(isMinimized: true)
            case (_, .restoreCallScreen) where fromState.presented?.isCallScreenMinimized == true:
                fromState.replacingCallScreen(isMinimized: false)
            case (_, .dismissCallScreen) where fromState.isPresenting(.callScreen):
                fromState.removingPresented(.callScreen)
                
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
                authenticationFlowCoordinator = nil
                targetContext.finishAuthentication()
                startUserSessionFlow(isNewLogin: true)
            case (.authenticationFlow, .cancelAddingAccount, .userSessionFlow):
                authenticationFlowCoordinator = nil
                targetContext.finishAuthentication()
                startUserSessionFlow(isNewLogin: false, showing: .settings)
            case (.authenticationFlow, .startAuthentication(isAddingAccount: false), .authenticationFlow):
                authenticationFlowCoordinator = nil
                startAuthenticationFlow(isAddingAccount: false)
            case (.userSessionFlow, .clearCache, .clearingCache(let userID, _)):
                stopUserSessionFlow()
                clearCache(userID: userID)
            case (.userSessionFlow, .logout, .loggingOut(let userID, _)):
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
                
            case (_, .presentShareRoomSelection, _):
                guard let userInfo = context.userInfo as? EventUserInfo, let payload = userInfo.sharePayload else {
                    fatalError("The share payload is missing.")
                }
                presentShareRoomSelection(for: payload, animated: userInfo.animated)
            case (_, .dismissedShareRoomSelection, _):
                break
                
            case (_, .presentSessionVerification, _):
                guard let userInfo = context.userInfo as? EventUserInfo, let request = userInfo.sessionVerificationRequest else {
                    fatalError("The session verification request is missing.")
                }
                presentSessionVerificationScreen(for: request, animated: userInfo.animated)
            case (_, .dismissedSessionVerification, _):
                break
                
            case (_, .presentPermalink, _):
                break // Not built yet.
            case (_, .dismissedPermalink, _):
                break
                
            case (_, .startRemoteLogoutFlow, _):
                guard let userInfo = context.userInfo as? EventUserInfo, let userSessionDetails = userInfo.userSessionDetails else {
                    fatalError("The logged out session is missing.")
                }
                startRemoteLogoutFlow(userSessionDetails: userSessionDetails, animated: userInfo.animated)
            case (_, .stopRemoteLogoutFlow, _):
                navigationRootCoordinator.setFullScreenCoverCoordinator(nil)
                
            case (_, .presentCallScreen, _), (_, .minimizeCallScreen, _), (_, .restoreCallScreen, _), (_, .dismissCallScreen, _):
                break // To replace the call state machine
                
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
                case .didSelectAccount(let userID):
                    handleSelectedAccount(userID: userID)
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
        
        sessionVerificationManager.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .receivedRequest(let request):
                    guard !stateMachine.state.isPresenting(.sessionVerification) else {
                        MXLog.info("Ignoring the session verification, another verification is in progress.")
                        return
                    }
                    stateMachine.tryEvent(.presentSessionVerification(userID: request.userSession.clientProxy.userID),
                                          userInfo: EventUserInfo(animated: true, sessionVerificationRequest: request))
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleRestoredSession(userID: String) {
        switch stateMachine.state {
        case .initial where userID == userSessionManager.activeSession?.clientProxy.userID,
             .clearingCache(userID, _):
            stateMachine.tryEvent(.startUserSession(userID: userID))
        default:
            break
        }
    }
    
    private func handleSelectedAccount(userID: String) {
        guard case .userSessionFlow = stateMachine.state else {
            return // Wait for the next user session flow, which will show the selected account.
        }
        
        stateMachine.tryEvent(.startUserSession(userID: userID))
    }
    
    private func handleRemovedAccount(userID: String, error: UserSessionManagerError?) {
        targetContext.update()
        
        // Will be handled elsewhere when the manager is fleshed out.
        if stateMachine.state.presented?.sessionVerificationUserID == userID {
            navigationRootCoordinator.setSheetCoordinator(nil)
        }
        
        switch stateMachine.state {
        case .initial:
            if userSessionManager.userIDs.isEmpty {
                stateMachine.tryEvent(.startAuthentication(isAddingAccount: false))
            } else {
                // Continue waiting while other accounts are restoring.
            }
        case .userSessionFlow(userID, _), .clearingCache(userID, _), .loggingOut(userID, _):
            actionsSubject.send(.closeSecondaryWindows)
            if let activeUserID = userSessionManager.activeSession?.clientProxy.userID {
                stateMachine.tryEvent(.startUserSession(userID: activeUserID))
            } else if userSessionManager.userIDs.isEmpty {
                for presentedState in stateMachine.state.presentedStates {
                    switch presentedState {
                    case .shareRoomSelection, .permalink:
                        navigationRootCoordinator.setSheetCoordinator(nil) // There's no accounts to select!
                    case .sessionVerification, .remoteLogout, .callScreen:
                        break // These are dismissed by their session's removal.
                    }
                }
                
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
        case .remoteLogout(let userSessionDetails):
            if let remoteLogoutFlowCoordinator {
                remoteLogoutFlowCoordinator.appendAdditionalSession(userSessionDetails)
            } else {
                stateMachine.tryEvent(.startRemoteLogoutFlow, userInfo: EventUserInfo(animated: true, userSessionDetails: userSessionDetails))
            }
        case .failedRestoringSession:
            showLoginErrorToast()
        case .none:
            break
        }
    }
    
    private func startAuthenticationFlow(isAddingAccount: Bool) {
        targetContext.startAuthentication()
        appHooks.rootFlowHook.configure(for: .authentication)
        
        let navigationStackCoordinator = NavigationStackCoordinator()
        let authenticationService = authenticationServiceFactory.makeAuthenticationService(userSessionManager: userSessionManager,
                                                                                           encryptionKeyProvider: EncryptionKeyProvider(),
                                                                                           classicAppManager: ClassicAppManager(),
                                                                                           appSettings: appSettings,
                                                                                           appHooks: appHooks,
                                                                                           targetContext: targetContext)
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
                case .cancelAddingAccount:
                    if let userID = userSessionManager.activeSession?.clientProxy.userID {
                        stateMachine.tryEvent(.cancelAddingAccount(userID: userID))
                    } else {
                        MXLog.error("Cancelled adding account without a session to return to.")
                        stateMachine.tryEvent(.startAuthentication(isAddingAccount: false))
                    }
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
    
    private func startUserSessionFlow(isAppLaunch: Bool = false, isNewLogin: Bool, showing appRoute: AppRoute? = nil) {
        guard let userSession = userSessionManager.activeSession else {
            fatalError("User session not setup")
        }
        
        appHooks.rootFlowHook.configure(for: .userSession(userSession))
        
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
                case .addAccount:
                    stateMachine.tryEvent(.startAuthentication(isAddingAccount: true))
                case .switchAccount(let userID):
                    userSessionManager.selectAccount(userID: userID)
                case .verifyUser(let userID):
                    guard !stateMachine.state.isPresenting(.sessionVerification) else {
                        MXLog.info("Ignoring the session verification, another verification is in progress.")
                        return
                    }
                    stateMachine.tryEvent(.presentSessionVerification(userID: userSession.clientProxy.userID),
                                          userInfo: EventUserInfo(animated: true, sessionVerificationRequest: .init(userSession: userSession,
                                                                                                                    kind: .toUser(userID: userID))))
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
        
        if let appRoute {
            userSessionFlowCoordinator?.handleAppRoute(appRoute, animated: false)
        } else if let pending = pendingAppRoute.take() {
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
        
        for presentedState in stateMachine.state.presentedStates {
            switch presentedState {
            case .sessionVerification:
                MXLog.info("Ignoring an app route while session verification is in progress.")
                return
            case .shareRoomSelection, .permalink:
                navigationRootCoordinator.setSheetCoordinator(nil) // The route replaces it.
            case .callScreen:
                break // To replace the call state machine
            case .remoteLogout:
                break
            }
        }
        
        if awaitsRoom, case .room(let roomID, _) = appRoute {
            userSession.clientProxy.roomsToAwait.insert(roomID)
        }
        
        minimizeFullScreenCall()
        
        if case .share(let payload) = appRoute, payload.roomID == nil {
            stateMachine.tryEvent(.presentShareRoomSelection, userInfo: EventUserInfo(animated: animated, sharePayload: payload))
            return
        }
        
        userSessionFlowCoordinator?.handleAppRoute(appRoute, animated: animated)
    }
    
    private func stopUserSessionFlow() {
        actionsSubject.send(.closeSecondaryWindows)
        userIndicatorController.retractAllIndicators()
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
    
    /// Shows the accounts that the server logged out in a fullscreen cover above every account's screens.
    private func startRemoteLogoutFlow(userSessionDetails: UserSessionDetails, animated: Bool) {
        let rootCoordinator = NavigationRootCoordinator()
        let coordinator = RemoteLogoutFlowCoordinator(userSessionDetails: userSessionDetails, navigationRootCoordinator: rootCoordinator)
        coordinator.actionsPublisher
            .sink { [weak self] action in
                switch action {
                case .complete:
                    self?.stateMachine.tryEvent(.stopRemoteLogoutFlow)
                }
            }
            .store(in: &cancellables)
        
        remoteLogoutFlowCoordinator = coordinator
        coordinator.start()
        
        navigationRootCoordinator.setFullScreenCoverCoordinator(rootCoordinator, animated: animated) { [weak self] in
            self?.remoteLogoutFlowCoordinator = nil
        }
    }
    
    // MARK: - Session Verification
    
    /// Shows the session verification screen above every account's screens, with the session of the account being verified.
    private func presentSessionVerificationScreen(for request: SessionVerificationRequest, animated: Bool) {
        let flow = request.screenFlow
        
        if flow.isResponder {
            // Any sheet from the shown account's screens would block this one.
            userSessionFlowCoordinator?.clearRoute(animated: animated)
        }
        
        guard let sessionVerificationController = request.userSession.clientProxy.sessionVerificationController else {
            fatalError("The sessionVerificationController should aways be valid at this point")
        }
        
        let stackCoordinator = NavigationStackCoordinator()
        let coordinator = SessionVerificationScreenCoordinator(parameters: .init(sessionVerificationControllerProxy: sessionVerificationController,
                                                                                 flow: flow,
                                                                                 userSession: request.userSession))
        coordinator.actions
            .sink { [weak self] action in
                switch action {
                case .done:
                    self?.navigationRootCoordinator.setSheetCoordinator(nil)
                }
            }
            .store(in: &cancellables)
        
        stackCoordinator.setRootCoordinator(coordinator)
        
        navigationRootCoordinator.setSheetCoordinator(stackCoordinator, animated: animated) { [weak self] in
            self?.stateMachine.tryEvent(.dismissedSessionVerification)
        }
    }
    
    // MARK: - Sharing
    
    /// Shows the share sheet above the shown account's screens, to pick the room the payload is shared to.
    private func presentShareRoomSelection(for payload: ShareExtensionPayload, animated: Bool) {
        userSessionFlowCoordinator?.clearRoute(animated: animated)
        
        guard let userSession = userSessionManager.activeSession else {
            MXLog.error("Cannot present the share sheet without an active session.")
            return
        }
        
        let coordinator = RoomSelectionScreenCoordinator(parameters: .init(userSession: userSession,
                                                                           roomSummaryProvider: userSession.clientProxy.alternateRoomSummaryProvider))
        coordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .dismiss:
                    navigationRootCoordinator.setSheetCoordinator(nil)
                case .confirm(let roomID):
                    completeShare(payload, roomID: roomID, animated: animated)
                }
            }
            .store(in: &cancellables)
        
        let stackCoordinator = NavigationStackCoordinator()
        stackCoordinator.setRootCoordinator(coordinator)
        
        navigationRootCoordinator.setSheetCoordinator(stackCoordinator, animated: animated) { [weak self] in
            self?.stateMachine.tryEvent(.dismissedShareRoomSelection)
        }
    }
    
    /// Finishes a share once its room is known, handing it to the shown account's screens.
    private func completeShare(_ payload: ShareExtensionPayload, roomID: String, animated: Bool) {
        navigationRootCoordinator.setSheetCoordinator(nil)
        userSessionFlowCoordinator?.handleAppRoute(.share(payload.withRoomID(roomID)), animated: animated)
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

private extension RootFlowCoordinator.State {
    /// Everything presented above the root.
    var presented: RootFlowCoordinator.PresentedState? {
        switch self {
        case .initial(let presented),
             .authenticationFlow(_, let presented),
             .userSessionFlow(_, let presented),
             .clearingCache(_, let presented),
             .loggingOut(_, let presented):
            presented
        }
    }
    
    /// Whether anything of the given kind is presented above the root.
    func isPresenting(_ kind: RootFlowCoordinator.PresentedState.Kind) -> Bool {
        presented?.contains(kind) ?? false
    }
    
    /// Everything presented above the root, from the top down.
    var presentedStates: [RootFlowCoordinator.PresentedState] {
        guard let presented else { return [] }
        return Array(sequence(first: presented) { $0.previousState })
    }
    
    /// This state with the same root, but something else presented above it.
    func presenting(_ presented: RootFlowCoordinator.PresentedState?) -> Self {
        switch self {
        case .initial:
            .initial(presented: presented)
        case .authenticationFlow(let isAddingAccount, _):
            .authenticationFlow(isAddingAccount: isAddingAccount, presented: presented)
        case .userSessionFlow(let userID, _):
            .userSessionFlow(userID: userID, presented: presented)
        case .clearingCache(let userID, _):
            .clearingCache(userID: userID, presented: presented)
        case .loggingOut(let userID, _):
            .loggingOut(userID: userID, presented: presented)
        }
    }
    
    /// This state with the topmost presentation of the given kind taken out, keeping everything presented after it.
    func removingPresented(_ kind: RootFlowCoordinator.PresentedState.Kind) -> Self {
        presenting(presented?.transforming(kind) { $0.previousState })
    }
    
    /// This state with its call screen updated where it is, and optionally replaced by another call screen.
    func replacingCallScreen(with callScreen: RootFlowCoordinator.PresentedCallScreen? = nil, isMinimized: Bool) -> Self {
        presenting(presented?.transforming(.callScreen) { presented in
            guard case .callScreen(let currentCallScreen, _, let previousState) = presented else { return presented }
            return .callScreen(callScreen ?? currentCallScreen, isMinimized: isMinimized, previousState: previousState)
        })
    }
}

private extension RootFlowCoordinator.PresentedState {
    enum Kind { case shareRoomSelection, sessionVerification, permalink, remoteLogout, callScreen }
    
    var kind: Kind {
        switch self {
        case .shareRoomSelection: .shareRoomSelection
        case .sessionVerification: .sessionVerification
        case .permalink: .permalink
        case .remoteLogout: .remoteLogout
        case .callScreen: .callScreen
        }
    }
    
    /// The account being verified, or `nil` when there's no session verification.
    var sessionVerificationUserID: String? {
        switch self {
        case .sessionVerification(let userID, _): userID
        default: previousState?.sessionVerificationUserID
        }
    }
    
    /// Whether the call screen is minimized, or `nil` when there isn't one.
    var isCallScreenMinimized: Bool? {
        switch self {
        case .callScreen(_, let isMinimized, _): isMinimized
        default: previousState?.isCallScreenMinimized
        }
    }
    
    /// Whether this or anything presented before it is of the given kind.
    func contains(_ kind: Kind) -> Bool {
        self.kind == kind || previousState?.contains(kind) == true
    }
    
    /// What was presented before this.
    var previousState: Self? {
        switch self {
        case .shareRoomSelection(let previousState),
             .sessionVerification(_, let previousState),
             .permalink(let previousState),
             .remoteLogout(let previousState),
             .callScreen(_, _, let previousState):
            previousState
        }
    }
    
    /// This presented after something else instead.
    func replacingPreviousState(with previousState: Self?) -> Self {
        switch self {
        case .shareRoomSelection:
            .shareRoomSelection(previousState: previousState)
        case .sessionVerification(let userID, _):
            .sessionVerification(userID: userID, previousState: previousState)
        case .permalink:
            .permalink(previousState: previousState)
        case .remoteLogout:
            .remoteLogout(previousState: previousState)
        case .callScreen(let callScreen, let isMinimized, _):
            .callScreen(callScreen, isMinimized: isMinimized, previousState: previousState)
        }
    }
    
    /// This with the topmost presentation of the given kind transformed, keeping everything presented after it.
    /// Unchanged when there's nothing of that kind.
    func transforming(_ kind: Kind, _ transform: (Self) -> Self?) -> Self? {
        if self.kind == kind {
            return transform(self)
        }
        
        return replacingPreviousState(with: previousState?.transforming(kind, transform))
    }
}

private extension SessionVerificationRequest {
    var screenFlow: SessionVerificationScreenFlow {
        switch kind {
        case .fromOwnDevice(let details): .deviceResponder(requestDetails: details)
        case .fromOtherUser(let details): .userResponder(requestDetails: details)
        case .toUser(let userID): .userInitiator(userID: userID)
        }
    }
}
