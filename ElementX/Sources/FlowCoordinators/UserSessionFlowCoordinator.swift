//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import AVKit
import Combine
import SwiftUI

enum UserSessionFlowCoordinatorAction {
    case logout
    case clearCache
    /// Logout without a confirmation. The user forgot their PIN.
    case forceLogout
}

class UserSessionFlowCoordinator: FlowCoordinatorProtocol {
    private let userSession: UserSessionProtocol
    private let navigationRootCoordinator: NavigationRootCoordinator
    private let navigationSplitCoordinator: NavigationSplitCoordinator
    private let bugReportService: BugReportServiceProtocol
    private let elementCallService: ElementCallServiceProtocol
    private let appMediator: AppMediatorProtocol
    private let appSettings: AppSettings
    private let appHooks: AppHooks
    private let analytics: AnalyticsService
    private let notificationManager: NotificationManagerProtocol
    
    private let stateMachine: UserSessionFlowCoordinatorStateMachine
    
    // periphery:ignore - retaining purpose
    private var roomFlowCoordinator: RoomFlowCoordinator?
    private let roomTimelineControllerFactory: RoomTimelineControllerFactoryProtocol
    
    private let settingsFlowCoordinator: SettingsFlowCoordinator
    
    private let onboardingFlowCoordinator: OnboardingFlowCoordinator
    
    // periphery:ignore - retaining purpose
    private var bugReportFlowCoordinator: BugReportFlowCoordinator?
    
    // periphery:ignore - retaining purpose
    private var globalSearchScreenCoordinator: GlobalSearchScreenCoordinator?
    
    private var cancellables = Set<AnyCancellable>()
    
    private let sidebarNavigationStackCoordinator: NavigationStackCoordinator
    private let detailNavigationStackCoordinator: NavigationStackCoordinator

    private let selectedRoomSubject = CurrentValueSubject<String?, Never>(nil)
    
    private let actionsSubject: PassthroughSubject<UserSessionFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<UserSessionFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    /// For testing purposes.
    var statePublisher: AnyPublisher<UserSessionFlowCoordinatorStateMachine.State, Never> { stateMachine.statePublisher }
    
    init(userSession: UserSessionProtocol,
         navigationRootCoordinator: NavigationRootCoordinator,
         appLockService: AppLockServiceProtocol,
         bugReportService: BugReportServiceProtocol,
         elementCallService: ElementCallServiceProtocol,
         roomTimelineControllerFactory: RoomTimelineControllerFactoryProtocol,
         appMediator: AppMediatorProtocol,
         appSettings: AppSettings,
         appHooks: AppHooks,
         analytics: AnalyticsService,
         notificationManager: NotificationManagerProtocol,
         isNewLogin: Bool) {
        stateMachine = UserSessionFlowCoordinatorStateMachine()
        self.userSession = userSession
        self.navigationRootCoordinator = navigationRootCoordinator
        self.bugReportService = bugReportService
        self.elementCallService = elementCallService
        self.roomTimelineControllerFactory = roomTimelineControllerFactory
        self.appMediator = appMediator
        self.appSettings = appSettings
        self.appHooks = appHooks
        self.analytics = analytics
        self.notificationManager = notificationManager
        
        navigationSplitCoordinator = NavigationSplitCoordinator(placeholderCoordinator: PlaceholderScreenCoordinator())
        
        sidebarNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        detailNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        
        navigationSplitCoordinator.setSidebarCoordinator(sidebarNavigationStackCoordinator)
                
        settingsFlowCoordinator = SettingsFlowCoordinator(parameters: .init(userSession: userSession,
                                                                            windowManager: appMediator.windowManager,
                                                                            appLockService: appLockService,
                                                                            bugReportService: bugReportService,
                                                                            notificationSettings: userSession.clientProxy.notificationSettings,
                                                                            secureBackupController: userSession.clientProxy.secureBackupController,
                                                                            appSettings: appSettings,
                                                                            navigationSplitCoordinator: navigationSplitCoordinator,
                                                                            userIndicatorController: ServiceLocator.shared.userIndicatorController))
        
        onboardingFlowCoordinator = OnboardingFlowCoordinator(userSession: userSession,
                                                              appLockService: appLockService,
                                                              analyticsService: analytics,
                                                              appSettings: appSettings,
                                                              notificationManager: notificationManager,
                                                              navigationStackCoordinator: detailNavigationStackCoordinator,
                                                              userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                              windowManager: appMediator.windowManager,
                                                              isNewLogin: isNewLogin)
        
        setupStateMachine()
        
        userSession.sessionSecurityStatePublisher
            .map(\.verificationState)
            .filter { $0 != .unknown }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                
                attemptStartingOnboarding()
            }
            .store(in: &cancellables)
        
        settingsFlowCoordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .presentedSettings:
                stateMachine.processEvent(.showSettingsScreen)
            case .dismissedSettings:
                stateMachine.processEvent(.dismissedSettingsScreen)
            case .runLogoutFlow:
                Task { await self.runLogoutFlow() }
            case .clearCache:
                actionsSubject.send(.clearCache)
            case .forceLogout:
                actionsSubject.send(.forceLogout)
            }
        }
        .store(in: &cancellables)
        
        userSession.clientProxy.actionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { action in
                guard case let .receivedDecryptionError(info) = action else {
                    return
                }
                
                let timeToDecryptMs: Int
                if let unsignedTimeToDecryptMs = info.timeToDecryptMs {
                    timeToDecryptMs = Int(unsignedTimeToDecryptMs)
                } else {
                    timeToDecryptMs = -1
                }
                
                switch info.cause {
                case .unknown:
                    analytics.trackError(context: nil, domain: .E2EE, name: .OlmKeysNotSentError, timeToDecryptMillis: timeToDecryptMs)
                case .membership:
                    analytics.trackError(context: nil, domain: .E2EE, name: .HistoricalMessage, timeToDecryptMillis: timeToDecryptMs)
                }
            }
            .store(in: &cancellables)
        
        elementCallService.actions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                switch action {
                case .endCall:
                    self?.dismissCallScreenIfNeeded()
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        onboardingFlowCoordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .logout:
                    logout()
                }
            }
            .store(in: &cancellables)
    }
    
    func start() {
        stateMachine.processEvent(.start)
    }
    
    func stop() { }

    func isDisplayingRoomScreen(withRoomID roomID: String) -> Bool {
        stateMachine.isDisplayingRoomScreen(withRoomID: roomID)
    }
    
    // MARK: - FlowCoordinatorProtocol
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        Task {
            await asyncHandleAppRoute(appRoute, animated: animated)
        }
    }
    
    func clearRoute(animated: Bool) {
        roomFlowCoordinator?.clearRoute(animated: animated)
    }

    // MARK: - Private
    
    func asyncHandleAppRoute(_ appRoute: AppRoute, animated: Bool) async {
        showLoadingIndicator(delay: .seconds(0.25))
        defer {
            hideLoadingIndicator()
        }
        
        await clearPresentedSheets(animated: animated)
        
        switch appRoute {
        case .room(let roomID, let via):
            stateMachine.processEvent(.selectRoom(roomID: roomID, via: via, entryPoint: .room), userInfo: .init(animated: animated))
        case .roomAlias(let alias):
            switch await userSession.clientProxy.resolveRoomAlias(alias) {
            case .success(let resolved): await asyncHandleAppRoute(.room(roomID: resolved.roomId, via: resolved.servers), animated: animated)
            case .failure: showFailureIndicator()
            }
        case .childRoom(let roomID, let via):
            if let roomFlowCoordinator {
                roomFlowCoordinator.handleAppRoute(appRoute, animated: animated)
            } else {
                stateMachine.processEvent(.selectRoom(roomID: roomID, via: via, entryPoint: .room), userInfo: .init(animated: animated))
            }
        case .childRoomAlias(let alias):
            switch await userSession.clientProxy.resolveRoomAlias(alias) {
            case .success(let resolved): await asyncHandleAppRoute(.childRoom(roomID: resolved.roomId, via: resolved.servers), animated: animated)
            case .failure: showFailureIndicator()
            }
            
        case .roomDetails(let roomID):
            if stateMachine.state.selectedRoomID == roomID {
                roomFlowCoordinator?.handleAppRoute(appRoute, animated: animated)
            } else {
                stateMachine.processEvent(.selectRoom(roomID: roomID, via: [], entryPoint: .roomDetails), userInfo: .init(animated: animated))
            }
        case .roomList:
            roomFlowCoordinator?.clearRoute(animated: animated)
        case .roomMemberDetails:
            roomFlowCoordinator?.handleAppRoute(appRoute, animated: animated)
        case .event(let eventID, let roomID, let via):
            stateMachine.processEvent(.selectRoom(roomID: roomID, via: via, entryPoint: .eventID(eventID)), userInfo: .init(animated: animated))
        case .eventOnRoomAlias(let eventID, let alias):
            switch await userSession.clientProxy.resolveRoomAlias(alias) {
            case .success(let resolved): await asyncHandleAppRoute(.event(eventID: eventID, roomID: resolved.roomId, via: resolved.servers), animated: animated)
            case .failure: showFailureIndicator()
            }
            
        case .childEvent:
            roomFlowCoordinator?.handleAppRoute(appRoute, animated: animated)
        case .childEventOnRoomAlias(let eventID, let alias):
            switch await userSession.clientProxy.resolveRoomAlias(alias) {
            case .success(let resolved): await asyncHandleAppRoute(.childEvent(eventID: eventID, roomID: resolved.roomId, via: resolved.servers), animated: animated)
            case .failure: showFailureIndicator()
            }
            
        case .userProfile(let userID):
            stateMachine.processEvent(.showUserProfileScreen(userID: userID), userInfo: .init(animated: animated))
        case .call(let roomID):
            Task { await presentCallScreen(roomID: roomID) }
        case .genericCallLink(let url):
            presentCallScreen(genericCallLink: url)
        case .settings, .chatBackupSettings:
            settingsFlowCoordinator.handleAppRoute(appRoute, animated: animated)
        case .oidcCallback:
            break
        }
    }
    
    func attemptStartingOnboarding() {
        if onboardingFlowCoordinator.shouldStart {
            clearRoute(animated: false)
            onboardingFlowCoordinator.start()
        }
    }
    
    private func clearPresentedSheets(animated: Bool) async {
        if navigationSplitCoordinator.sheetCoordinator == nil {
            return
        }
        
        navigationSplitCoordinator.setSheetCoordinator(nil, animated: animated)
        
        // Prevents system crashes when presenting a sheet if another one was already shown
        try? await Task.sleep(for: .seconds(0.25))
    }
    
    private func setupStateMachine() {
        stateMachine.addTransitionHandler { [weak self] context in
            guard let self else { return }
            let animated = (context.userInfo as? UserSessionFlowCoordinatorStateMachine.EventUserInfo)?.animated ?? true
            switch (context.fromState, context.event, context.toState) {
            case (.initial, .start, .roomList):
                presentHomeScreen()
                attemptStartingOnboarding()
            case(.roomList(let selectedRoomID), .selectRoom(let roomID, let via, let entryPoint), .roomList):
                if selectedRoomID == roomID,
                   !entryPoint.isEventID, // Don't reuse the existing room so the live timeline is hidden while the detached timeline is loading.
                   let roomFlowCoordinator {
                    let route: AppRoute = switch entryPoint {
                    case .room: .room(roomID: roomID, via: via)
                    case .roomDetails: .roomDetails(roomID: roomID)
                    case .eventID(let eventID): .event(eventID: eventID, roomID: roomID, via: via) // ignored.
                    }
                    roomFlowCoordinator.handleAppRoute(route, animated: animated)
                } else {
                    Task { await self.startRoomFlow(roomID: roomID, via: via, entryPoint: entryPoint, animated: animated) }
                }
                hideCallScreenOverlay() // Turn any active call into a PiP so that navigation from a notification is visible to the user.
            case(.roomList, .deselectRoom, .roomList):
                dismissRoomFlow(animated: animated)
                                
            case (.roomList, .showSettingsScreen, .settingsScreen):
                break
            case (.settingsScreen, .dismissedSettingsScreen, .roomList):
                break
                
            case (.roomList, .feedbackScreen, .feedbackScreen):
                bugReportFlowCoordinator = BugReportFlowCoordinator(parameters: .init(presentationMode: .sheet(sidebarNavigationStackCoordinator),
                                                                                      userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                                                      bugReportService: bugReportService,
                                                                                      userSession: userSession))
                bugReportFlowCoordinator?.start()
            case (.feedbackScreen, .dismissedFeedbackScreen, .roomList):
                break
                
            case (.roomList, .showStartChatScreen, .startChatScreen):
                presentStartChat(animated: animated)
            case (.startChatScreen, .dismissedStartChatScreen, .roomList):
                break
                
            case (.roomList, .showLogoutConfirmationScreen, .logoutConfirmationScreen):
                presentSecureBackupLogoutConfirmationScreen()
            case (.logoutConfirmationScreen, .dismissedLogoutConfirmationScreen, .roomList):
                break
                
            case (.roomList, .showRoomDirectorySearchScreen, .roomDirectorySearchScreen):
                presentRoomDirectorySearch()
            case (.roomDirectorySearchScreen, .dismissedRoomDirectorySearchScreen, .roomList):
                dismissRoomDirectorySearch()
            
            case (_, .showUserProfileScreen(let userID), .userProfileScreen):
                presentUserProfileScreen(userID: userID, animated: animated)
            case (.userProfileScreen, .dismissedUserProfileScreen, .roomList):
                break
                
            default:
                fatalError("Unknown transition: \(context)")
            }
        }
        
        stateMachine.addTransitionHandler { [weak self] context in
            switch context.toState {
            case .roomList(let selectedRoomID):
                self?.selectedRoomSubject.send(selectedRoomID)
            default:
                break
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
    
    private func presentHomeScreen() {
        let parameters = HomeScreenCoordinatorParameters(userSession: userSession,
                                                         bugReportService: bugReportService,
                                                         selectedRoomPublisher: selectedRoomSubject.asCurrentValuePublisher())
        let coordinator = HomeScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .presentRoom(let roomID):
                    handleAppRoute(.room(roomID: roomID, via: []), animated: true)
                case .presentRoomDetails(let roomID):
                    handleAppRoute(.roomDetails(roomID: roomID), animated: true)
                case .roomLeft(let roomID):
                    if case .roomList(selectedRoomID: let selectedRoomID) = stateMachine.state,
                       selectedRoomID == roomID {
                        clearRoute(animated: true)
                    }
                case .presentSettingsScreen:
                    settingsFlowCoordinator.handleAppRoute(.settings, animated: true)
                case .presentFeedbackScreen:
                    stateMachine.processEvent(.feedbackScreen)
                case .presentSecureBackupSettings:
                    settingsFlowCoordinator.handleAppRoute(.chatBackupSettings, animated: true)
                case .presentStartChatScreen:
                    stateMachine.processEvent(.showStartChatScreen)
                case .presentGlobalSearch:
                    presentGlobalSearch()
                case .presentRoomDirectorySearch:
                    stateMachine.processEvent(.showRoomDirectorySearchScreen)
                case .logoutWithoutConfirmation:
                    self.actionsSubject.send(.logout)
                case .logout:
                    Task { await self.runLogoutFlow() }
                }
            }
            .store(in: &cancellables)
        
        sidebarNavigationStackCoordinator.setRootCoordinator(coordinator)
        
        navigationRootCoordinator.setRootCoordinator(navigationSplitCoordinator)
    }
    
    private func runLogoutFlow() async {
        let secureBackupController = userSession.clientProxy.secureBackupController
        
        guard case let .success(isLastDevice) = await userSession.clientProxy.isOnlyDeviceLeft() else {
            ServiceLocator.shared.userIndicatorController.alertInfo = .init(id: .init())
            return
        }
        
        guard isLastDevice else {
            logout()
            return
        }
        
        guard secureBackupController.recoveryState.value == .enabled else {
            ServiceLocator.shared.userIndicatorController.alertInfo = .init(id: .init(),
                                                                            title: L10n.screenSignoutRecoveryDisabledTitle,
                                                                            message: L10n.screenSignoutRecoveryDisabledSubtitle,
                                                                            primaryButton: .init(title: L10n.screenSignoutConfirmationDialogSubmit, role: .destructive) { [weak self] in
                                                                                self?.actionsSubject.send(.logout)
                                                                            }, secondaryButton: .init(title: L10n.commonSettings, role: .cancel) { [weak self] in
                                                                                self?.settingsFlowCoordinator.handleAppRoute(.chatBackupSettings, animated: true)
                                                                            })
            return
        }
        
        guard secureBackupController.keyBackupState.value == .enabled else {
            ServiceLocator.shared.userIndicatorController.alertInfo = .init(id: .init(),
                                                                            title: L10n.screenSignoutKeyBackupDisabledTitle,
                                                                            message: L10n.screenSignoutKeyBackupDisabledSubtitle,
                                                                            primaryButton: .init(title: L10n.screenSignoutConfirmationDialogSubmit, role: .destructive) { [weak self] in
                                                                                self?.actionsSubject.send(.logout)
                                                                            }, secondaryButton: .init(title: L10n.commonSettings, role: .cancel) { [weak self] in
                                                                                self?.settingsFlowCoordinator.handleAppRoute(.chatBackupSettings, animated: true)
                                                                            })
            return
        }
        
        presentSecureBackupLogoutConfirmationScreen()
    }
    
    private func logout() {
        ServiceLocator.shared.userIndicatorController.alertInfo = .init(id: .init(),
                                                                        title: L10n.screenSignoutConfirmationDialogTitle,
                                                                        message: L10n.screenSignoutConfirmationDialogContent,
                                                                        primaryButton: .init(title: L10n.screenSignoutConfirmationDialogSubmit, role: .destructive) { [weak self] in
                                                                            self?.actionsSubject.send(.logout)
                                                                        })
    }
    
    // MARK: Room Flow
    
    private func startRoomFlow(roomID: String,
                               via: [String],
                               entryPoint: RoomFlowCoordinatorEntryPoint,
                               animated: Bool) async {
        let coordinator = await RoomFlowCoordinator(roomID: roomID,
                                                    userSession: userSession,
                                                    isChildFlow: false,
                                                    roomTimelineControllerFactory: roomTimelineControllerFactory,
                                                    navigationStackCoordinator: detailNavigationStackCoordinator,
                                                    emojiProvider: EmojiProvider(),
                                                    ongoingCallRoomIDPublisher: elementCallService.ongoingCallRoomIDPublisher,
                                                    appMediator: appMediator,
                                                    appSettings: appSettings,
                                                    analytics: analytics,
                                                    userIndicatorController: ServiceLocator.shared.userIndicatorController)
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .presentCallScreen(let roomProxy):
                presentCallScreen(roomProxy: roomProxy)
            case .finished:
                stateMachine.processEvent(.deselectRoom)
            }
        }
        .store(in: &cancellables)
        
        roomFlowCoordinator = coordinator
        
        if navigationSplitCoordinator.detailCoordinator !== detailNavigationStackCoordinator {
            navigationSplitCoordinator.setDetailCoordinator(detailNavigationStackCoordinator, animated: animated)
        }
        
        switch entryPoint {
        case .room:
            coordinator.handleAppRoute(.room(roomID: roomID, via: via), animated: animated)
        case .eventID(let eventID):
            coordinator.handleAppRoute(.event(eventID: eventID, roomID: roomID, via: via), animated: animated)
        case .roomDetails:
            coordinator.handleAppRoute(.roomDetails(roomID: roomID), animated: animated)
        }
                
        Task {
            let _ = await userSession.clientProxy.trackRecentlyVisitedRoom(roomID)
            
            await notificationManager.removeDeliveredMessageNotifications(for: roomID)
        }
    }
    
    private func dismissRoomFlow(animated: Bool) {
        // THIS MUST BE CALLED *AFTER* THE FLOW HAS TIDIED UP THE STACK OR IT CAN CAUSE A CRASH.
        navigationSplitCoordinator.setDetailCoordinator(nil, animated: animated)
        roomFlowCoordinator = nil
    }
    
    // MARK: Start Chat
    
    private func presentStartChat(animated: Bool) {
        let startChatNavigationStackCoordinator = NavigationStackCoordinator()

        let userDiscoveryService = UserDiscoveryService(clientProxy: userSession.clientProxy)
        let parameters = StartChatScreenCoordinatorParameters(orientationManager: appMediator.windowManager,
                                                              userSession: userSession,
                                                              userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                              navigationStackCoordinator: startChatNavigationStackCoordinator,
                                                              userDiscoveryService: userDiscoveryService)
        
        let coordinator = StartChatScreenCoordinator(parameters: parameters)
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .close:
                self.navigationSplitCoordinator.setSheetCoordinator(nil)
            case .openRoom(let roomID):
                self.navigationSplitCoordinator.setSheetCoordinator(nil)
                self.stateMachine.processEvent(.selectRoom(roomID: roomID, via: [], entryPoint: .room))
            }
        }
        .store(in: &cancellables)

        startChatNavigationStackCoordinator.setRootCoordinator(coordinator)

        navigationSplitCoordinator.setSheetCoordinator(startChatNavigationStackCoordinator, animated: animated) { [weak self] in
            self?.stateMachine.processEvent(.dismissedStartChatScreen)
        }
    }
        
    // MARK: Calls
    
    private func presentCallScreen(genericCallLink url: URL) {
        presentCallScreen(configuration: .init(genericCallLink: url))
    }
    
    private func presentCallScreen(roomID: String) async {
        guard case let .joined(roomProxy) = await userSession.clientProxy.roomForIdentifier(roomID) else {
            return
        }
        
        presentCallScreen(roomProxy: roomProxy)
    }
    
    private func presentCallScreen(roomProxy: JoinedRoomProxyProtocol) {
        let colorScheme: ColorScheme = appMediator.windowManager.mainWindow.traitCollection.userInterfaceStyle == .light ? .light : .dark
        presentCallScreen(configuration: .init(roomProxy: roomProxy,
                                               clientProxy: userSession.clientProxy,
                                               clientID: InfoPlistReader.main.bundleIdentifier,
                                               elementCallBaseURL: appSettings.elementCallBaseURL,
                                               elementCallBaseURLOverride: appSettings.elementCallBaseURLOverride,
                                               colorScheme: colorScheme))
    }
    
    private var callScreenPictureInPictureController: AVPictureInPictureController?
    private func presentCallScreen(configuration: ElementCallConfiguration) {
        guard elementCallService.ongoingCallRoomIDPublisher.value != configuration.callRoomID else {
            MXLog.info("Returning to existing call.")
            callScreenPictureInPictureController?.stopPictureInPicture()
            return
        }
        
        let callScreenCoordinator = CallScreenCoordinator(parameters: .init(elementCallService: elementCallService,
                                                                            configuration: configuration,
                                                                            allowPictureInPicture: true,
                                                                            appHooks: appHooks))
        
        callScreenCoordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .pictureInPictureIsAvailable(let controller):
                    callScreenPictureInPictureController = controller
                case .pictureInPictureStarted:
                    MXLog.info("Hiding call for PiP presentation.")
                    navigationSplitCoordinator.setOverlayPresentationMode(.minimized)
                case .pictureInPictureStopped:
                    MXLog.info("Restoring call after PiP presentation.")
                    navigationSplitCoordinator.setOverlayPresentationMode(.fullScreen)
                case .dismiss:
                    callScreenPictureInPictureController = nil
                    navigationSplitCoordinator.setOverlayCoordinator(nil)
                }
            }
            .store(in: &cancellables)
        
        navigationSplitCoordinator.setOverlayCoordinator(callScreenCoordinator, animated: true)
        
        analytics.track(screen: .RoomCall)
    }
    
    private func hideCallScreenOverlay() {
        guard let callScreenPictureInPictureController else {
            MXLog.warning("Picture in picture isn't available, dismissing the call screen.")
            dismissCallScreenIfNeeded()
            return
        }
        
        MXLog.info("Starting picture in picture to hide the call screen overlay.")
        callScreenPictureInPictureController.startPictureInPicture()
        navigationSplitCoordinator.setOverlayPresentationMode(.minimized)
    }
    
    private func dismissCallScreenIfNeeded() {
        guard navigationSplitCoordinator.overlayCoordinator is CallScreenCoordinator else {
            return
        }
        
        navigationSplitCoordinator.setOverlayCoordinator(nil)
    }
    
    // MARK: Secure backup confirmation
    
    private func presentSecureBackupLogoutConfirmationScreen() {
        let coordinator = SecureBackupLogoutConfirmationScreenCoordinator(parameters: .init(secureBackupController: userSession.clientProxy.secureBackupController,
                                                                                            appMediator: appMediator))
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .cancel:
                    navigationSplitCoordinator.setSheetCoordinator(nil)
                case .settings:
                    settingsFlowCoordinator.handleAppRoute(.chatBackupSettings, animated: true)
                case .logout:
                    actionsSubject.send(.logout)
                }
            }
            .store(in: &cancellables)
        
        navigationSplitCoordinator.setSheetCoordinator(coordinator, animated: true)
    }
    
    // MARK: Global search
    
    private func presentGlobalSearch() {
        guard let roomSummaryProvider = userSession.clientProxy.alternateRoomSummaryProvider else {
            fatalError("Global search room summary provider unavailable")
        }
        
        let coordinator = GlobalSearchScreenCoordinator(parameters: .init(roomSummaryProvider: roomSummaryProvider,
                                                                          mediaProvider: userSession.mediaProvider))
        
        globalSearchScreenCoordinator = coordinator
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .dismiss:
                    dismissGlobalSearch()
                case .select(let roomID):
                    dismissGlobalSearch()
                    handleAppRoute(.room(roomID: roomID, via: []), animated: true)
                }
            }
            .store(in: &cancellables)
        
        let hostingController = UIHostingController(rootView: coordinator.toPresentable())
        hostingController.view.backgroundColor = .clear
        appMediator.windowManager.globalSearchWindow.rootViewController = hostingController

        appMediator.windowManager.showGlobalSearch()
    }
    
    private func dismissGlobalSearch() {
        appMediator.windowManager.globalSearchWindow.rootViewController = nil
        appMediator.windowManager.hideGlobalSearch()
        
        globalSearchScreenCoordinator = nil
    }
    
    // MARK: Room Directory Search
    
    private func presentRoomDirectorySearch() {
        let coordinator = RoomDirectorySearchScreenCoordinator(parameters: .init(clientProxy: userSession.clientProxy,
                                                                                 mediaProvider: userSession.mediaProvider,
                                                                                 userIndicatorController: ServiceLocator.shared.userIndicatorController))
        
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .selectAlias(let alias):
                stateMachine.processEvent(.dismissedRoomDirectorySearchScreen)
                handleAppRoute(.roomAlias(alias), animated: true)
            case .selectRoomID(let roomID):
                stateMachine.processEvent(.dismissedRoomDirectorySearchScreen)
                handleAppRoute(.room(roomID: roomID, via: []), animated: true)
            case .dismiss:
                stateMachine.processEvent(.dismissedRoomDirectorySearchScreen)
            }
        }
        .store(in: &cancellables)
        
        navigationSplitCoordinator.setFullScreenCoverCoordinator(coordinator)
    }
    
    private func dismissRoomDirectorySearch() {
        navigationSplitCoordinator.setFullScreenCoverCoordinator(nil)
    }
    
    // MARK: User Profile
    
    private func presentUserProfileScreen(userID: String, animated: Bool) {
        clearRoute(animated: animated)
        
        let navigationStackCoordinator = NavigationStackCoordinator()
        let parameters = UserProfileScreenCoordinatorParameters(userID: userID,
                                                                isPresentedModally: true,
                                                                clientProxy: userSession.clientProxy,
                                                                mediaProvider: userSession.mediaProvider,
                                                                userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                                analytics: analytics)
        let coordinator = UserProfileScreenCoordinator(parameters: parameters)
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .openDirectChat(let roomID):
                navigationSplitCoordinator.setSheetCoordinator(nil)
                stateMachine.processEvent(.selectRoom(roomID: roomID, via: [], entryPoint: .room))
            case .startCall(let roomID):
                Task { await self.presentCallScreen(roomID: roomID) }
            case .dismiss:
                navigationSplitCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.setRootCoordinator(coordinator, animated: false)
        navigationSplitCoordinator.setSheetCoordinator(navigationStackCoordinator, animated: animated) { [weak self] in
            self?.stateMachine.processEvent(.dismissedUserProfileScreen)
        }
    }
    
    // MARK: Toasts and loading indicators
    
    private static let loadingIndicatorIdentifier = "\(UserSessionFlowCoordinator.self)-Loading"
    private static let failureIndicatorIdentifier = "\(UserSessionFlowCoordinator.self)-Failure"
    
    private func showLoadingIndicator(delay: Duration? = nil) {
        ServiceLocator.shared.userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                                                    type: .modal,
                                                                                    title: L10n.commonLoading,
                                                                                    persistent: true),
                                                                      delay: delay)
    }
    
    private func hideLoadingIndicator() {
        ServiceLocator.shared.userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
    
    private func showFailureIndicator() {
        ServiceLocator.shared.userIndicatorController.submitIndicator(UserIndicator(id: Self.failureIndicatorIdentifier,
                                                                                    type: .toast,
                                                                                    title: L10n.errorUnknown,
                                                                                    iconName: "xmark"))
    }
}
