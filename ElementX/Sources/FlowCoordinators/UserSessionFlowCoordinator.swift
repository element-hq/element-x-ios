//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVKit
import Combine
import Compound
import ElementCallAll
import SwiftState
import SwiftUI

enum UserSessionFlowCoordinatorAction {
    case logout
    case clearCache
    /// Logout and disable App Lock without any confirmation. The user forgot their PIN.
    case forceLogout
}

class UserSessionFlowCoordinator: FlowCoordinatorProtocol {
    enum HomeTab: Hashable { case chats, spaces, search }
    
    private let navigationRootCoordinator: NavigationRootCoordinator
    private let navigationTabCoordinator: NavigationTabCoordinator<HomeTab>
    private let appLockService: AppLockServiceProtocol
    private let flowParameters: CommonFlowParameters
    // periphery:ignore - retaining purpose
    private let presenceService: PresenceService
    
    private var userSession: UserSessionProtocol {
        flowParameters.userSession
    }
    
    private let onboardingFlowCoordinator: OnboardingFlowCoordinator
    private let onboardingStackCoordinator: NavigationStackCoordinator
    private let chatsTabFlowCoordinator: ChatsTabFlowCoordinator
    private let chatsTabDetails: NavigationTabCoordinator<HomeTab>.TabDetails
    private let spacesTabFlowCoordinator: SpacesTabFlowCoordinator
    private let spacesTabDetails: NavigationTabCoordinator<HomeTab>.TabDetails
    
    private let searchScreenCoordinator: SearchScreenCoordinator?
    private let searchTabNavigationStackCoordinator: NavigationStackCoordinator?
    private let searchTabDetails: NavigationTabCoordinator<HomeTab>.TabDetails?
    
    private var settingsFlowCoordinator: SettingsFlowCoordinator?
    
    enum State: StateType {
        /// The state machine hasn't started.
        case initial
        /// The root screen for this flow.
        case tabBar
        /// Showing the settings screen.
        case settingsScreen
    }
    
    enum Event: EventType {
        /// The flow is being started.
        case start
        
        /// Request presentation of the settings screen.
        case showSettingsScreen
        /// The settings screen has been dismissed.
        case dismissedSettingsScreen
    }
    
    private let stateMachine: StateMachine<State, Event>
    private var cancellables: Set<AnyCancellable> = []
    
    private let actionsSubject: PassthroughSubject<UserSessionFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<UserSessionFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(isNewLogin: Bool,
         navigationRootCoordinator: NavigationRootCoordinator,
         appLockService: AppLockServiceProtocol,
         flowParameters: CommonFlowParameters) {
        self.navigationRootCoordinator = navigationRootCoordinator
        self.appLockService = appLockService
        self.flowParameters = flowParameters
        presenceService = PresenceService(clientProxy: flowParameters.userSession.clientProxy,
                                          appSettings: flowParameters.appSettings)
        
        navigationTabCoordinator = NavigationTabCoordinator()
        navigationRootCoordinator.setRootCoordinator(navigationTabCoordinator)
        
        let chatsSplitCoordinator = NavigationSplitCoordinator(placeholderCoordinator: PlaceholderScreenCoordinator(hideBrandChrome: flowParameters.appSettings.hideBrandChrome))
        chatsTabFlowCoordinator = ChatsTabFlowCoordinator(navigationSplitCoordinator: chatsSplitCoordinator,
                                                          flowParameters: flowParameters)
        chatsTabDetails = .init(tag: HomeTab.chats, title: L10n.screenHomeTabChats, icon: \.chat, selectedIcon: \.chatSolid)
        chatsTabDetails.navigationSplitCoordinator = chatsSplitCoordinator
        
        let spacesSplitCoordinator = NavigationSplitCoordinator(placeholderCoordinator: PlaceholderScreenCoordinator(hideBrandChrome: flowParameters.appSettings.hideBrandChrome))
        spacesTabFlowCoordinator = SpacesTabFlowCoordinator(navigationSplitCoordinator: spacesSplitCoordinator,
                                                            flowParameters: flowParameters)
        spacesTabDetails = .init(tag: HomeTab.spaces, title: L10n.screenHomeTabSpaces, icon: \.space, selectedIcon: \.spaceSolid)
        spacesTabDetails.navigationSplitCoordinator = spacesSplitCoordinator
        
        if flowParameters.appSettings.globalSearchEnabled, #available(iOS 26.0, *) {
            let searchCoordinator = SearchScreenCoordinator(parameters: .init(roomSummaryProvider: flowParameters.userSession.clientProxy.alternateRoomSummaryProvider,
                                                                              clientProxy: flowParameters.userSession.clientProxy,
                                                                              mediaProvider: flowParameters.userSession.mediaProvider,
                                                                              userIndicatorController: flowParameters.userIndicatorController))
            let searchStackCoordinator = NavigationStackCoordinator()
            searchStackCoordinator.setRootCoordinator(searchCoordinator)
            
            searchScreenCoordinator = searchCoordinator
            searchTabNavigationStackCoordinator = searchStackCoordinator
            searchTabDetails = .init(tag: HomeTab.search, title: UntranslatedL10n.screenHomeTabSearch, icon: \.search, selectedIcon: \.search, isSearch: true)
        } else {
            searchScreenCoordinator = nil
            searchTabNavigationStackCoordinator = nil
            searchTabDetails = nil
        }
        
        onboardingStackCoordinator = NavigationStackCoordinator()
        onboardingFlowCoordinator = OnboardingFlowCoordinator(isNewLogin: isNewLogin,
                                                              appLockService: appLockService,
                                                              navigationStackCoordinator: onboardingStackCoordinator,
                                                              flowParameters: flowParameters)
        
        var tabs: [NavigationTabCoordinator<HomeTab>.Tab] = [
            .init(coordinator: chatsSplitCoordinator, details: chatsTabDetails),
            .init(coordinator: spacesSplitCoordinator, details: spacesTabDetails)
        ]
        if let searchTabNavigationStackCoordinator, let searchTabDetails {
            tabs.append(.init(coordinator: searchTabNavigationStackCoordinator, details: searchTabDetails))
        }
        navigationTabCoordinator.setTabs(tabs)
        
        stateMachine = flowParameters.stateMachineFactory.makeUserSessionFlowStateMachine(state: .initial)
        configureStateMachine()
        
        setupObservers()
    }
    
    func start(animated: Bool) {
        stateMachine.tryEvent(.start)
    }
    
    func stop() {
        chatsTabFlowCoordinator.stop()
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        MXLog.info("Handling app route: \(appRoute)")
        
        switch appRoute {
        case .accountProvisioningLink, .oAuthCallback:
            break // We always ignore these flows when logged in.
        case .settings, .chatBackupSettings:
            if ProcessInfo.processInfo.isiOSAppOnMac, flowParameters.windowManager.secondaryWindowsEnabled {
                startSettingsFlow(detached: true)
            } else {
                if stateMachine.state != .settingsScreen {
                    stateMachine.tryEvent(.showSettingsScreen)
                }
                settingsFlowCoordinator?.handleAppRoute(appRoute, animated: animated)
            }
        case .call(let roomID, let isVoiceCall):
            Task { await presentCallScreen(roomID: roomID, isVoiceCall: isVoiceCall) }
        case .roomList, .room, .roomAlias, .childRoom, .childRoomAlias,
             .roomDetails, .roomMemberDetails, .userProfile,
             .event, .eventOnRoomAlias, .childEvent, .childEventOnRoomAlias,
             .share, .transferOwnership, .thread:
            clearPresentedSheets(animated: animated) // Make sure the presented route is visible.
            chatsTabFlowCoordinator.handleAppRoute(appRoute, animated: animated)
            if navigationTabCoordinator.selectedTab != .chats {
                navigationTabCoordinator.selectedTab = .chats
            }
        case .search:
            // Switch to the dedicated search tab when it's available (iOS 26 + flag), otherwise ignore.
            if searchTabNavigationStackCoordinator != nil {
                navigationTabCoordinator.selectedTab = .search
            }
        }
    }
    
    func clearRoute(animated: Bool) {
        clearPresentedSheets(animated: animated)
        chatsTabFlowCoordinator.clearRoute(animated: animated)
    }
    
    /// Clearing routes is more complicated than it first seems. When passing routes
    /// to the chats flow we can't clear all routes as e.g. childRoom/childEvent etc
    /// expect to push into the existing stack. But we do need to hide any sheets that
    /// might cover up the presented route. BUT! We probably shouldn't dismiss onboarding
    /// or verification flows until they're complete… This needs more thought before we
    /// codify it all into the state machine.
    private func clearPresentedSheets(animated: Bool) {
        switch stateMachine.state {
        case .initial, .tabBar:
            break
        case .settingsScreen:
            navigationTabCoordinator.setSheetCoordinator(nil, animated: animated)
        }
    }
    
    func isDisplayingRoomScreen(withRoomID roomID: String) -> Bool {
        guard navigationTabCoordinator.selectedTab == .chats else { return false }
        return chatsTabFlowCoordinator.isDisplayingRoomScreen(withRoomID: roomID)
    }
    
    // MARK: - Private
    
    private func configureStateMachine() {
        stateMachine.addRoutes(event: .start, transitions: [.initial => .tabBar]) { [weak self] _ in
            guard let self else { return }
            
            chatsTabFlowCoordinator.start()
            spacesTabFlowCoordinator.start()
            attemptStartingOnboarding()
        }
        
        stateMachine.addRoutes(event: .showSettingsScreen, transitions: [.tabBar => .settingsScreen]) { [weak self] _ in
            self?.startSettingsFlow(detached: false)
        }
        stateMachine.addRoutes(event: .dismissedSettingsScreen, transitions: [.settingsScreen => .tabBar]) { [weak self] _ in
            self?.settingsFlowCoordinator = nil
        }
        
        stateMachine.addErrorHandler { context in
            fatalError("Unexpected transition: \(context)")
        }
    }
    
    private func setupObservers() {
        chatsTabFlowCoordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .switchToChatsTab:
                    navigationTabCoordinator.selectedTab = .chats
                case .showSettings:
                    handleAppRoute(.settings, animated: true)
                case .showChatBackupSettings:
                    handleAppRoute(.chatBackupSettings, animated: true)
                case .sessionVerification(let flow):
                    presentSessionVerificationScreen(flow: flow)
                case .showCallScreen(let roomProxy, let isVoiceCall):
                    presentCallScreen(roomProxy: roomProxy, voiceOnly: isVoiceCall)
                case .hideCallScreenOverlay:
                    hideCallScreenOverlay()
                case .logout:
                    Task { await self.runLogoutFlow() }
                }
            }
            .store(in: &cancellables)
        
        spacesTabFlowCoordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .presentCallScreen(let roomProxy, let isVoiceCall):
                    presentCallScreen(roomProxy: roomProxy, voiceOnly: isVoiceCall)
                case .verifyUser(let userID):
                    presentSessionVerificationScreen(flow: .userInitiator(userID: userID))
                case .showSettings:
                    stateMachine.tryEvent(.showSettingsScreen)
                }
            }
            .store(in: &cancellables)
        
        userSession.sessionSecurityStatePublisher
            .map(\.verificationState)
            .filter { $0 != .unknown }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                
                attemptStartingOnboarding()
                setupSessionVerificationRequestsObserver()
            }
            .store(in: &cancellables)
        
        let reachabilityNotificationID = "io.element.elementx.reachability.notification"
        userSession.clientProxy.homeserverReachabilityPublisher.removeDuplicates()
            .combineLatest(flowParameters.appMediator.networkMonitor.reachabilityPublisher.removeDuplicates())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] homeserverReachability, networkReachability in
                MXLog.info("Homeserver reachability: \(homeserverReachability)")
                
                guard let self else { return }
                switch (networkReachability, homeserverReachability) {
                case (.unreachable, _):
                    flowParameters.userIndicatorController.submitIndicator(.init(id: reachabilityNotificationID,
                                                                                 title: L10n.commonOffline,
                                                                                 persistent: true))
                case (.reachable, .unreachable):
                    flowParameters.userIndicatorController.submitIndicator(.init(id: reachabilityNotificationID,
                                                                                 title: L10n.commonServerUnreachable,
                                                                                 persistent: true))
                // Don't alarm the user while we've intentionally suspended the client.
                case (.reachable, .reachable), (.reachable, .suspended):
                    flowParameters.userIndicatorController.retractIndicatorWithId(reachabilityNotificationID)
                }
            }
            .store(in: &cancellables)
        
        onboardingFlowCoordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .requestPresentation(let animated):
                    navigationTabCoordinator.setFullScreenCoverCoordinator(onboardingStackCoordinator, animated: animated)
                case .dismiss:
                    navigationTabCoordinator.setFullScreenCoverCoordinator(nil)
                case .logoutConfirmed:
                    actionsSubject.send(.logout)
                }
            }
            .store(in: &cancellables)
        
        setupCallObservers()
        
        searchScreenCoordinator?.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .presentRoom(let roomID, let eventID):
                    if let eventID {
                        handleAppRoute(.event(eventID: eventID, roomID: roomID, via: []), animated: true)
                    } else {
                        handleAppRoute(.room(roomID: roomID, via: []), animated: true)
                    }
                case .cancel:
                    // Return to the tab the user came from, but never back into search.
                    navigationTabCoordinator.selectedTab = navigationTabCoordinator.previousTab == .search ? .chats : navigationTabCoordinator.previousTab ?? .chats
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Onboarding
    
    private func attemptStartingOnboarding() {
        MXLog.info("Attempting to start onboarding")
        
        if onboardingFlowCoordinator.shouldStart {
            clearRoute(animated: false)
            onboardingFlowCoordinator.start()
        }
    }
    
    // MARK: - Settings
    
    private func startSettingsFlow(detached: Bool) {
        let navigationStackCoordinator = NavigationStackCoordinator()
        let coordinator = SettingsFlowCoordinator(appLockService: appLockService,
                                                  isInSecondaryWindow: detached,
                                                  navigationStackCoordinator: navigationStackCoordinator,
                                                  flowParameters: flowParameters)
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .dismiss:
                navigationTabCoordinator.setSheetCoordinator(nil)
            case .clearCache:
                actionsSubject.send(.clearCache)
            case .runLogoutFlow:
                Task {
                    self.navigationTabCoordinator.setSheetCoordinator(nil)
                    
                    // The sheet needs to be dismissed before the alert can be shown
                    try await Task.sleep(for: .milliseconds(100))
                    await self.runLogoutFlow()
                }
            case .forceLogout:
                actionsSubject.send(.forceLogout)
            }
        }
        .store(in: &cancellables)
        
        coordinator.handleAppRoute(.settings, animated: false)
        
        if detached {
            flowParameters.windowManager.registerCoordinator(navigationStackCoordinator,
                                                             flowCoordinator: coordinator,
                                                             forWindowType: .settings)
        } else {
            settingsFlowCoordinator = coordinator
            
            navigationTabCoordinator.setSheetCoordinator(navigationStackCoordinator) { [weak self] in
                self?.stateMachine.tryEvent(.dismissedSettingsScreen)
            }
        }
    }
    
    // MARK: - Session Verification
    
    private func setupSessionVerificationRequestsObserver() {
        userSession.clientProxy.sessionVerificationController?.actions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                guard let self, case .receivedVerificationRequest(let details) = action else {
                    return
                }
                
                MXLog.info("Received session verification request")
                
                if details.senderProfile.id == userSession.clientProxy.userID {
                    presentSessionVerificationScreen(flow: .deviceResponder(requestDetails: details))
                } else {
                    presentSessionVerificationScreen(flow: .userResponder(requestDetails: details))
                }
            }
            .store(in: &cancellables)
    }
    
    private func presentSessionVerificationScreen(flow: SessionVerificationScreenFlow) {
        guard let sessionVerificationController = userSession.clientProxy.sessionVerificationController else {
            fatalError("The sessionVerificationController should aways be valid at this point")
        }
        
        let navigationStackCoordinator = NavigationStackCoordinator()
        
        let parameters = SessionVerificationScreenCoordinatorParameters(sessionVerificationControllerProxy: sessionVerificationController,
                                                                        flow: flow,
                                                                        appSettings: flowParameters.appSettings,
                                                                        mediaProvider: userSession.mediaProvider)
        
        let coordinator = SessionVerificationScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                switch action {
                case .done:
                    self?.navigationTabCoordinator.setSheetCoordinator(nil)
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.setRootCoordinator(coordinator)
        
        navigationTabCoordinator.setSheetCoordinator(navigationStackCoordinator)
    }
    
    // MARK: - Calls
    
    private func presentCallScreen(roomID: String, isVoiceCall: Bool) async {
        guard case let .joined(roomProxy) = await userSession.clientProxy.roomForIdentifier(roomID) else {
            // An answered call is left up for the native stack, so it has to be ended here rather
            // than leaving the system with a call this room can no longer serve.
            MXLog.error("Cannot present the call screen, \(roomID) isn't a joined room")
            flowParameters.elementCallService.endNativeCallSession(roomID: roomID)
            return
        }
        
        presentCallScreen(roomProxy: roomProxy, voiceOnly: isVoiceCall)
    }
    
    private func presentCallScreen(roomProxy: JoinedRoomProxyProtocol, voiceOnly: Bool) {
        let colorScheme: ColorScheme = flowParameters.windowManager.mainWindow.traitCollection.userInterfaceStyle == .light ? .light : .dark
        presentCallScreen(configuration: .init(roomProxy: roomProxy,
                                               clientProxy: userSession.clientProxy,
                                               clientID: InfoPlistReader.main.bundleIdentifier,
                                               elementCallBaseURL: flowParameters.appSettings.elementCallBaseURL,
                                               elementCallBaseURLOverride: flowParameters.appSettings.elementCallBaseURLOverride,
                                               voiceOnly: voiceOnly,
                                               colorScheme: colorScheme))
    }
    
    private var callScreenPictureInPictureController: AVPictureInPictureController?
    private func presentCallScreen(configuration: ElementCallConfiguration) {
        guard flowParameters.ongoingCallRoomIDPublisher.value != configuration.callRoomID else {
            MXLog.info("Returning to existing call.")
            if let nativeCallController, nativeCallController.isInCall {
                restoreNativeCallScreen()
            } else {
                callScreenPictureInPictureController?.stopPictureInPicture()
            }
            return
        }
        
        if flowParameters.appSettings.nativeCallEnabled {
            presentNativeCallScreen(configuration: configuration)
            return
        }
        
        let callScreenCoordinator = CallScreenCoordinator(parameters: .init(elementCallService: flowParameters.elementCallService,
                                                                            configuration: configuration,
                                                                            allowPictureInPicture: true,
                                                                            appSettings: flowParameters.appSettings,
                                                                            analytics: flowParameters.analytics))
        
        callScreenCoordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .pictureInPictureIsAvailable(let controller):
                    callScreenPictureInPictureController = controller
                case .pictureInPictureStarted:
                    MXLog.info("Hiding call for PiP presentation.")
                    navigationTabCoordinator.setOverlayPresentationMode(.minimized)
                case .pictureInPictureStopped:
                    MXLog.info("Restoring call after PiP presentation.")
                    navigationTabCoordinator.setOverlayPresentationMode(.fullScreen)
                case .dismiss:
                    callScreenPictureInPictureController = nil
                    navigationTabCoordinator.setOverlayCoordinator(nil)
                }
            }
            .store(in: &cancellables)
        
        navigationTabCoordinator.setOverlayCoordinator(callScreenCoordinator, animated: true)
        
        flowParameters.analytics.track(screen: .RoomCall)
    }
    
    private func hideCallScreenOverlay() {
        if let nativeCallController, nativeCallController.isInCall,
           navigationTabCoordinator.overlayCoordinator is NativeCallScreenCoordinator {
            // The controller decides whether a system window is available and says so through its
            // actions, so the screen only comes down once one has actually started.
            nativeCallController.requestMinimize()
            return
        }
        
        guard let callScreenPictureInPictureController else {
            MXLog.warning("Picture in picture isn't available, dismissing the call screen.")
            dismissCallScreenIfNeeded()
            return
        }
        
        MXLog.info("Starting picture in picture to hide the call screen overlay.")
        callScreenPictureInPictureController.startPictureInPicture()
        navigationTabCoordinator.setOverlayPresentationMode(.minimized)
    }
    
    // MARK: - Native calls
    
    private func setupCallObservers() {
        flowParameters.elementCallService.actions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .endCall:
                    // The native controller hears this through its own system port and tears the
                    // call down itself, so only the web-view screen needs dismissing here.
                    if nativeCallController?.isInCall != true {
                        dismissCallScreenIfNeeded()
                    }
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // The stack is created with the session rather than with the first call: to-device delivery
        // has no catch-up, so subscribing only after our own membership goes out can miss keys sent
        // in that window. Peers re-distribute on join, so it recovers, but avoiding the race means
        // the first frames decrypt rather than arriving black for a moment.
        flowParameters.appSettings.nativeCallEnabledPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in
                guard let self else { return }
                flowParameters.elementCallService.setNativeCallModeEnabled(isEnabled)
                if isEnabled, nativeCallStack == nil {
                    startNativeCallStack()
                }
            }
            .store(in: &cancellables)
    }
    
    private var nativeCallStack: ElementCallStack?
    
    private var nativeCallController: ElementCallController? {
        nativeCallStack?.controller
    }
    
    /// Builds the call stack for this session. Everything the package needs is supplied here, which
    /// is the whole of the integration surface: a transport, the system call provider, settings, the
    /// look, and a log sink.
    private func startNativeCallStack() {
        MatrixRTCLogBridge.install()
        
        guard let transport = userSession.clientProxy.nativeCallTransport else {
            MXLog.error("Cannot start the native call stack without a transport")
            return
        }
        
        let style = ElementCallStyle(theme: NativeCallCompoundTheme(),
                                     icons: NativeCallCompoundIcons(),
                                     avatars: NativeCallCompoundAvatars(mediaProvider: userSession.mediaProvider),
                                     strings: .init(you: L10n.commonYou,
                                                    error: L10n.commonError,
                                                    stop: L10n.actionStop,
                                                    back: L10n.actionBack))
        
        let stack = ElementCallStack(transport: transport,
                                     system: NativeCallSystemAdapter(service: flowParameters.elementCallService),
                                     options: NativeCallOptionsAdapter(appSettings: flowParameters.appSettings),
                                     style: style,
                                     logger: NativeCallLoggerAdapter())
        nativeCallStack = stack
        
        stack.controller.actions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .minimizeRequested:
                    // Nothing to do until we know what the call is minimizing into: the controller
                    // follows this with either window or no window.
                    break
                case .restoreRequested:
                    restoreNativeCallScreen()
                case .ended:
                    navigationTabCoordinator.setOverlayCoordinator(nil)
                    stack.controller.reset()
                    presentPendingNativeCallScreen()
                case .pictureInPictureStarted:
                    // Also reached when the system started the window on backgrounding, so this
                    // isn't necessarily a minimize we asked for.
                    navigationTabCoordinator.setOverlayPresentationMode(.minimized)
                case .pictureInPictureUnavailable:
                    // Without a window there is nothing to minimize into, and hiding the screen
                    // anyway would leave the call running with no way back to mute or hang up. The
                    // bar that belongs here comes with its own PR.
                    MXLog.info("Staying on the call screen: no system window is available.")
                    restoreNativeCallScreen()
                }
            }
            .store(in: &cancellables)
        
        Task { await stack.start() }
    }
    
    /// A call requested while another one was still running, started once that one has ended.
    private var pendingNativeCallConfiguration: ElementCallConfiguration?
    
    private func presentNativeCallScreen(configuration: ElementCallConfiguration) {
        if nativeCallStack == nil {
            startNativeCallStack()
        }
        guard let controller = nativeCallController else {
            MXLog.error("Cannot present a native call without a call stack")
            flowParameters.elementCallService.endNativeCallSession(roomID: configuration.callRoomID)
            return
        }
        
        if controller.isInCall {
            guard controller.room?.roomID != configuration.callRoomID else {
                // Reached while the call is still joining, before the service has an ongoing call
                // for the guard in `presentCallScreen` to match against.
                MXLog.info("Returning to the call already starting in this room.")
                restoreNativeCallScreen()
                return
            }
            
            // The controller ignores a second call, so this one waits for the running call to
            // leave its room properly rather than being dropped the way the web view drops it.
            MXLog.info("Leaving the ongoing call to start the one requested in another room.")
            pendingNativeCallConfiguration = configuration
            controller.hangUp()
            return
        }
        
        let roomProxy = configuration.roomProxy
        // Starting rings the room; joining one already running happens quietly.
        let callData = ElementCallData(isAudioCall: configuration.voiceOnly,
                                       isStartingCall: !roomProxy.infoPublisher.value.hasRoomCall)
        controller.startCall(callData, room: NativeCallRoomContextAdapter(roomProxy: roomProxy))
        
        let coordinator = NativeCallScreenCoordinator(parameters: .init(controller: controller))
        navigationTabCoordinator.setOverlayCoordinator(coordinator, animated: true)
        flowParameters.analytics.track(screen: .RoomCall)
    }
    
    private func presentPendingNativeCallScreen() {
        guard let configuration = pendingNativeCallConfiguration else { return }
        pendingNativeCallConfiguration = nil
        presentNativeCallScreen(configuration: configuration)
    }
    
    private func restoreNativeCallScreen() {
        nativeCallController?.restore()
        navigationTabCoordinator.setOverlayPresentationMode(.fullScreen)
    }
    
    private func dismissCallScreenIfNeeded() {
        guard navigationTabCoordinator.overlayCoordinator is CallScreenCoordinator
            || navigationTabCoordinator.overlayCoordinator is NativeCallScreenCoordinator else {
            return
        }
        
        navigationTabCoordinator.setOverlayCoordinator(nil)
    }
    
    // MARK: - Logout
    
    private func runLogoutFlow() async {
        let secureBackupController = userSession.clientProxy.secureBackupController
        
        guard case let .success(isLastDevice) = await userSession.clientProxy.isOnlyDeviceLeft() else {
            navigationRootCoordinator.alertInfo = .init(id: .init())
            return
        }
        
        guard isLastDevice else {
            navigationRootCoordinator.alertInfo = .init(id: .init(),
                                                        title: L10n.screenSignoutConfirmationDialogTitle,
                                                        message: L10n.screenSignoutConfirmationDialogContent,
                                                        primaryButton: .init(title: L10n.screenSignoutConfirmationDialogSubmit, role: .destructive) { [weak self] in
                                                            self?.actionsSubject.send(.logout)
                                                        })
            return
        }
        
        guard secureBackupController.recoveryState.value == .enabled else {
            navigationRootCoordinator.alertInfo = .init(id: .init(),
                                                        title: L10n.screenSignoutRecoveryDisabledTitle,
                                                        message: L10n.screenSignoutRecoveryDisabledSubtitle,
                                                        primaryButton: .init(title: L10n.screenSignoutConfirmationDialogSubmit, role: .destructive) { [weak self] in
                                                            self?.actionsSubject.send(.logout)
                                                        }, secondaryButton: .init(title: L10n.commonSettings, role: .cancel) { [weak self] in
                                                            self?.chatsTabFlowCoordinator.handleAppRoute(.chatBackupSettings, animated: true)
                                                        })
            return
        }
        
        guard secureBackupController.keyBackupState.value == .enabled else {
            navigationRootCoordinator.alertInfo = .init(id: .init(),
                                                        title: L10n.screenSignoutKeyBackupDisabledTitle,
                                                        message: L10n.screenSignoutKeyBackupDisabledSubtitle,
                                                        primaryButton: .init(title: L10n.screenSignoutConfirmationDialogSubmit, role: .destructive) { [weak self] in
                                                            self?.actionsSubject.send(.logout)
                                                        }, secondaryButton: .init(title: L10n.commonSettings, role: .cancel) { [weak self] in
                                                            self?.chatsTabFlowCoordinator.handleAppRoute(.chatBackupSettings, animated: true)
                                                        })
            return
        }
        
        presentSecureBackupLogoutConfirmationScreen()
    }
    
    private func presentSecureBackupLogoutConfirmationScreen() {
        let coordinator = SecureBackupLogoutConfirmationScreenCoordinator(parameters: .init(secureBackupController: userSession.clientProxy.secureBackupController,
                                                                                            homeserverReachabilityPublisher: userSession.clientProxy.homeserverReachabilityPublisher))
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .cancel:
                    navigationTabCoordinator.setSheetCoordinator(nil)
                case .settings:
                    chatsTabFlowCoordinator.handleAppRoute(.chatBackupSettings, animated: true)
                    navigationTabCoordinator.setSheetCoordinator(nil)
                case .logout:
                    actionsSubject.send(.logout)
                }
            }
            .store(in: &cancellables)
        
        navigationTabCoordinator.setSheetCoordinator(coordinator, animated: true)
    }
}
