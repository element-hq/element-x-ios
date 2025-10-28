//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AnalyticsEvents
import Combine
import MatrixRustSDK
import SwiftUI

enum ChatsFlowCoordinatorAction {
    case switchToChatsTab
    case showSettings
    case showChatBackupSettings
    case sessionVerification(SessionVerificationScreenFlow)
    case showCallScreen(roomProxy: JoinedRoomProxyProtocol)
    case hideCallScreenOverlay
    case logout
}

class ChatsFlowCoordinator: FlowCoordinatorProtocol {
    private let navigationSplitCoordinator: NavigationSplitCoordinator
    private let flowParameters: CommonFlowParameters
    
    private var userSession: UserSessionProtocol { flowParameters.userSession }
    
    private let stateMachine: ChatsFlowCoordinatorStateMachine
    
    // periphery:ignore - retaining purpose
    private var roomFlowCoordinator: RoomFlowCoordinator?
    // periphery:ignore - retaining purpose
    private var spaceFlowCoordinator: SpaceFlowCoordinator?
    
    // periphery:ignore - retaining purpose
    private var bugReportFlowCoordinator: BugReportFlowCoordinator?
    // periphery:ignore - retaining purpose
    private var encryptionResetFlowCoordinator: EncryptionResetFlowCoordinator?
    // periphery:ignore - retaining purpose
    private var startChatFlowCoordinator: StartChatFlowCoordinator?
    
    // periphery:ignore - retaining purpose
    private var globalSearchScreenCoordinator: GlobalSearchScreenCoordinator?
    
    private var cancellables = Set<AnyCancellable>()
    
    private let sidebarNavigationStackCoordinator: NavigationStackCoordinator
    private let detailNavigationStackCoordinator: NavigationStackCoordinator

    private let selectedRoomSubject = CurrentValueSubject<String?, Never>(nil)
    
    private let actionsSubject: PassthroughSubject<ChatsFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<ChatsFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(isNewLogin: Bool,
         navigationSplitCoordinator: NavigationSplitCoordinator,
         flowParameters: CommonFlowParameters) {
        stateMachine = flowParameters.stateMachineFactory.makeChatsFlowStateMachine()
        self.navigationSplitCoordinator = navigationSplitCoordinator
        self.flowParameters = flowParameters
        
        sidebarNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        detailNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        navigationSplitCoordinator.setSidebarCoordinator(sidebarNavigationStackCoordinator)
        
        setupStateMachine()
        setupObservers()
    }
    
    func start(animated: Bool) {
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
        showLoadingIndicator(delay: .seconds(0.5))
        defer { hideLoadingIndicator() }
        
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
            if case .room(roomID) = stateMachine.state.detailState {
                roomFlowCoordinator?.handleAppRoute(appRoute, animated: animated)
            } else {
                stateMachine.processEvent(.selectRoom(roomID: roomID, via: [], entryPoint: .roomDetails), userInfo: .init(animated: animated))
            }
        case .roomList:
            roomFlowCoordinator?.clearRoute(animated: animated)
        case .roomMemberDetails:
            roomFlowCoordinator?.handleAppRoute(appRoute, animated: animated)
        case .thread(let roomID, let threadRootEventID, let focusEventID):
            stateMachine.processEvent(.selectRoom(roomID: roomID,
                                                  via: [],
                                                  entryPoint: .thread(rootEventID: threadRootEventID,
                                                                      focusEventID: focusEventID)),
                                      userInfo: .init(animated: animated))
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
        case .share(let payload):
            if let roomID = payload.roomID {
                stateMachine.processEvent(.selectRoom(roomID: roomID,
                                                      via: [],
                                                      entryPoint: .share(payload)),
                                          userInfo: .init(animated: animated))
            } else {
                stateMachine.processEvent(.showShareExtensionRoomList(sharePayload: payload), userInfo: .init(animated: animated))
            }
        case .transferOwnership(let roomID):
            if case .room(roomID) = stateMachine.state.detailState {
                roomFlowCoordinator?.handleAppRoute(appRoute, animated: animated)
            } else {
                stateMachine.processEvent(.selectRoom(roomID: roomID, via: [], entryPoint: .transferOwnership))
            }
        case .accountProvisioningLink, .settings, .chatBackupSettings, .call, .genericCallLink:
            break // These routes cannot be handled.
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
            
            let userInfo = context.userInfo as? ChatsFlowCoordinatorStateMachine.EventUserInfo
            let animated = userInfo?.animated ?? true
            
            switch (context.fromState, context.event, context.toState) {
            case (.initial, .start, .roomList):
                presentHomeScreen()
            case(.roomList(let detailState), .selectRoom(let roomID, let via, let entryPoint), .roomList):
                handleSelectRoomTransition(roomID: roomID, via: via, entryPoint: entryPoint, detailState: detailState, animated: animated)
            case(.roomList, .deselectRoom, .roomList):
                dismissRoomFlow(animated: animated)
            
            case(.roomList, .startSpaceFlow, .roomList):
                guard let spaceRoomListProxy = userInfo?.spaceRoomListProxy else { fatalError("A space room list proxy is required.") }
                startSpaceFlow(spaceRoomListProxy: spaceRoomListProxy, animated: animated)
            case (.roomList, .finishedSpaceFlow, .roomList):
                dismissSpaceFlow(animated: animated)
                
            case (.roomList, .feedbackScreen, .feedbackScreen):
                bugReportFlowCoordinator = BugReportFlowCoordinator(parameters: .init(presentationMode: .sheet(sidebarNavigationStackCoordinator),
                                                                                      userIndicatorController: flowParameters.userIndicatorController,
                                                                                      bugReportService: flowParameters.bugReportService,
                                                                                      userSession: userSession))
                bugReportFlowCoordinator?.start()
            case (.feedbackScreen, .dismissedFeedbackScreen, .roomList):
                break
                
            case (.roomList, .showRecoveryKeyScreen, .recoveryKeyScreen):
                presentRecoveryKeyScreen(animated: animated)
            case (.recoveryKeyScreen, .dismissedRecoveryKeyScreen, .roomList):
                break
                
            case (.roomList, .startEncryptionResetFlow, .encryptionResetFlow):
                startEncryptionResetFlow(animated: animated)
            case (.encryptionResetFlow, .finishedEncryptionResetFlow, .roomList):
                encryptionResetFlowCoordinator = nil
                
            case (.roomList, .startStartChatFlow, .startChatFlow):
                startStartChatFlow(animated: animated)
            case (.startChatFlow, .finishedStartChatFlow, .roomList):
                startChatFlowCoordinator = nil
                
            case (.roomList, .showRoomDirectorySearchScreen, .roomDirectorySearchScreen):
                presentRoomDirectorySearch()
            case (.roomDirectorySearchScreen, .dismissedRoomDirectorySearchScreen, .roomList):
                dismissRoomDirectorySearch()
            
            case (_, .showUserProfileScreen(let userID), .userProfileScreen):
                presentUserProfileScreen(userID: userID, animated: animated)
            case (.userProfileScreen, .dismissedUserProfileScreen, .roomList):
                break
                
            case (.roomList, .presentReportRoomScreen(let roomID), .reportRoomScreen):
                Task { await self.presentReportRoom(for: roomID) }
            case (.reportRoomScreen, .dismissedReportRoomScreen, .roomList):
                break
                
            case (.roomList, .presentDeclineAndBlockScreen(let userID, let roomID), .declineAndBlockUserScreen):
                presentDeclineAndBlockScreen(userID: userID, roomID: roomID)
            case (.declineAndBlockUserScreen, .dismissedDeclineAndBlockScreen, .roomList):
                break
                
            case (.roomList(let roomListSelectedRoomID), .showShareExtensionRoomList, .shareExtensionRoomList(let sharePayload)):
                Task {
                    if roomListSelectedRoomID != nil {
                        self.clearRoute(animated: animated)
                        try? await Task.sleep(for: .seconds(1.5))
                    }
                    
                    self.presentRoomSelectionScreen(sharePayload: sharePayload, animated: animated)
                }
            case (.shareExtensionRoomList, .dismissedShareExtensionRoomList, .roomList):
                dismissRoomSelectionScreen()
                
            default:
                fatalError("Unknown transition: \(context)")
            }
        }
        
        stateMachine.addTransitionHandler { [weak self] context in
            switch context.toState {
            case .roomList(detailState: .room(let detailStateRoomID)):
                self?.selectedRoomSubject.send(detailStateRoomID)
            case .roomList(detailState: nil):
                self?.selectedRoomSubject.send(nil)
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
    
    private func handleSelectRoomTransition(roomID: String, via: [String], entryPoint: RoomFlowCoordinatorEntryPoint, detailState: ChatsFlowCoordinatorStateMachine.DetailState?, animated: Bool) {
        if case .room(roomID) = detailState,
           !entryPoint.isEventID, // Don't reuse the existing room so the live timeline is hidden while the detached timeline is loading.
           let roomFlowCoordinator {
            let route: AppRoute = switch entryPoint {
            case .room: .room(roomID: roomID, via: via)
            case .roomDetails: .roomDetails(roomID: roomID)
            case .eventID(let eventID): .event(eventID: eventID, roomID: roomID, via: via) // ignored.
            case .share(let payload): .share(payload)
            case .transferOwnership: .transferOwnership(roomID: roomID)
            case .thread(let rootEventID, let focusEventID): .thread(roomID: roomID, threadRootEventID: rootEventID, focusEventID: focusEventID)
            }
            roomFlowCoordinator.handleAppRoute(route, animated: animated)
        } else {
            if case .space = detailState {
                dismissRoomFlow(animated: animated)
            }
            startRoomFlow(roomID: roomID, via: via, entryPoint: entryPoint, animated: animated)
        }
        actionsSubject.send(.hideCallScreenOverlay) // Turn any active call into a PiP so that navigation from a notification is visible to the user.
    }
    
    private func setupObservers() {
        userSession.clientProxy.actionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .receivedDecryptionError(let info):
                    processDecryptionError(info)
                case .receivedSyncUpdate:
                    Task {
                        let roomSummaries = self.userSession.clientProxy.staticRoomSummaryProvider.roomListPublisher.value
                        await self.flowParameters.notificationManager.removeDeliveredNotificationsForFullyReadRooms(roomSummaries)
                    }
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    private func processDecryptionError(_ info: UnableToDecryptInfo) {
        let timeToDecryptMs: Int
        if let unsignedTimeToDecryptMs = info.timeToDecryptMs {
            timeToDecryptMs = Int(unsignedTimeToDecryptMs)
        } else {
            timeToDecryptMs = -1
        }
        
        let errorName: AnalyticsEvent.Error.Name = switch info.cause {
        case .unknown: .OlmKeysNotSentError
        case .unknownDevice, .unsignedDevice: .ExpectedSentByInsecureDevice
        case .verificationViolation: .ExpectedVerificationViolation
        case .sentBeforeWeJoined: .ExpectedDueToMembership
        case .historicalMessageAndBackupIsDisabled, .historicalMessageAndDeviceIsUnverified: .HistoricalMessage
        case .withheldForUnverifiedOrInsecureDevice: .RoomKeysWithheldForUnverifiedDevice
        case .withheldBySender: .OlmKeysNotSentError
        }
        
        flowParameters.analytics.trackError(context: nil,
                                            domain: .E2EE,
                                            name: errorName,
                                            timeToDecryptMillis: timeToDecryptMs,
                                            eventLocalAgeMillis: Int(truncatingIfNeeded: info.eventLocalAgeMillis),
                                            isFederated: info.ownHomeserver != info.senderHomeserver,
                                            isMatrixDotOrg: info.ownHomeserver == "matrix.org",
                                            userTrustsOwnIdentity: info.userTrustsOwnIdentity,
                                            wasVisibleToUser: nil)
    }
    
    private func presentHomeScreen() {
        let parameters = HomeScreenCoordinatorParameters(userSession: userSession,
                                                         bugReportService: flowParameters.bugReportService,
                                                         selectedRoomPublisher: selectedRoomSubject.asCurrentValuePublisher(),
                                                         appSettings: flowParameters.appSettings,
                                                         analyticsService: flowParameters.analytics,
                                                         notificationManager: flowParameters.notificationManager,
                                                         userIndicatorController: flowParameters.userIndicatorController)
        let coordinator = HomeScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .presentRoom(let roomID):
                    handleAppRoute(.room(roomID: roomID, via: []), animated: true)
                case .presentRoomDetails(let roomID):
                    handleAppRoute(.roomDetails(roomID: roomID), animated: true)
                case .presentReportRoom(let roomID):
                    stateMachine.processEvent(.presentReportRoomScreen(roomID: roomID))
                case .presentSpace(let spaceRoomListProxy):
                    stateMachine.processEvent(.startSpaceFlow, userInfo: .init(animated: true, spaceRoomListProxy: spaceRoomListProxy))
                case .roomLeft(let roomID):
                    if case .roomList(detailState: .room(let detailStateRoomID)) = stateMachine.state,
                       detailStateRoomID == roomID {
                        clearRoute(animated: true)
                    }
                case .presentSettingsScreen:
                    actionsSubject.send(.showSettings)
                case .presentFeedbackScreen:
                    stateMachine.processEvent(.feedbackScreen)
                case .presentSecureBackupSettings:
                    actionsSubject.send(.showChatBackupSettings)
                case .presentRecoveryKeyScreen:
                    stateMachine.processEvent(.showRecoveryKeyScreen)
                case .presentEncryptionResetScreen:
                    stateMachine.processEvent(.startEncryptionResetFlow)
                case .presentStartChatScreen:
                    stateMachine.processEvent(.startStartChatFlow)
                case .presentGlobalSearch:
                    presentGlobalSearch()
                case .logout:
                    actionsSubject.send(.logout)
                case .presentDeclineAndBlock(let userID, let roomID):
                    stateMachine.processEvent(.presentDeclineAndBlockScreen(userID: userID, roomID: roomID))
                case .transferOwnership(let roomIdentifier):
                    handleAppRoute(.transferOwnership(roomID: roomIdentifier), animated: true)
                }
            }
            .store(in: &cancellables)
        
        sidebarNavigationStackCoordinator.setRootCoordinator(coordinator)
    }
    
    private func presentReportRoom(for roomID: String) async {
        guard let roomProxyType = await userSession.clientProxy.roomForIdentifier(roomID),
              case let .joined(roomProxy) = roomProxyType else {
            MXLog.error("Failed to get room proxy for room: \(roomID)")
            return
        }
        
        let navigationStackCoordinator = NavigationStackCoordinator()
        let coordinator = ReportRoomScreenCoordinator(parameters: .init(roomProxy: roomProxy,
                                                                        userIndicatorController: flowParameters.userIndicatorController))
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .dismiss(let shouldLeaveRoom):
                if shouldLeaveRoom,
                   case .roomList(detailState: .room(let detailStateRoomID)) = stateMachine.state,
                   detailStateRoomID == roomID {
                    clearRoute(animated: true)
                }
                navigationSplitCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        navigationStackCoordinator.setRootCoordinator(coordinator)
        navigationSplitCoordinator.setSheetCoordinator(navigationStackCoordinator) { [weak self] in
            self?.stateMachine.processEvent(.dismissedReportRoomScreen)
        }
    }
    
    private func presentDeclineAndBlockScreen(userID: String, roomID: String) {
        let stackCoordinator = NavigationStackCoordinator()
        let coordinator = DeclineAndBlockScreenCoordinator(parameters: .init(userID: userID,
                                                                             roomID: roomID,
                                                                             clientProxy: userSession.clientProxy,
                                                                             userIndicatorController: flowParameters.userIndicatorController))
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .dismiss:
                navigationSplitCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        
        stackCoordinator.setRootCoordinator(coordinator)
        navigationSplitCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.stateMachine.processEvent(.dismissedDeclineAndBlockScreen)
        }
    }
    
    // MARK: Room Flow
    
    private func startRoomFlow(roomID: String,
                               via: [String],
                               entryPoint: RoomFlowCoordinatorEntryPoint,
                               animated: Bool) {
        let coordinator = RoomFlowCoordinator(roomID: roomID,
                                              isChildFlow: false,
                                              navigationStackCoordinator: detailNavigationStackCoordinator,
                                              flowParameters: flowParameters)
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .presentCallScreen(let roomProxy):
                actionsSubject.send(.showCallScreen(roomProxy: roomProxy))
            case .verifyUser(let userID):
                actionsSubject.send(.sessionVerification(.userInitiator(userID: userID)))
            case .continueWithSpaceFlow(let spaceRoomListProxy):
                stateMachine.processEvent(.startSpaceFlow, userInfo: .init(animated: false, spaceRoomListProxy: spaceRoomListProxy))
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
        case .share(let payload):
            coordinator.handleAppRoute(.share(payload), animated: animated)
        case .transferOwnership:
            coordinator.handleAppRoute(.transferOwnership(roomID: roomID), animated: animated)
        case .thread(let rootEventID, let focusEventID):
            coordinator.handleAppRoute(.thread(roomID: roomID, threadRootEventID: rootEventID, focusEventID: focusEventID), animated: animated)
        }
                
        Task {
            let _ = await userSession.clientProxy.trackRecentlyVisitedRoom(roomID)
            
            await flowParameters.notificationManager.removeDeliveredMessageNotifications(for: roomID)
        }
    }
    
    private func dismissRoomFlow(animated: Bool) {
        // THIS MUST BE CALLED *AFTER* THE FLOW HAS TIDIED UP THE STACK OR IT CAN CAUSE A CRASH.
        navigationSplitCoordinator.setDetailCoordinator(nil, animated: animated)
        roomFlowCoordinator = nil
    }
    
    // MARK: Space Flow
    
    private func startSpaceFlow(spaceRoomListProxy: SpaceRoomListProxyProtocol, animated: Bool) {
        let coordinator = SpaceFlowCoordinator(entryPoint: .space(spaceRoomListProxy),
                                               spaceServiceProxy: userSession.clientProxy.spaceService,
                                               isChildFlow: false,
                                               navigationStackCoordinator: detailNavigationStackCoordinator,
                                               flowParameters: flowParameters)
        coordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .presentCallScreen(let roomProxy):
                    actionsSubject.send(.showCallScreen(roomProxy: roomProxy))
                case .verifyUser(let userID):
                    actionsSubject.send(.sessionVerification(.userInitiator(userID: userID)))
                case .finished:
                    stateMachine.processEvent(.finishedSpaceFlow)
                }
            }
            .store(in: &cancellables)
        
        spaceFlowCoordinator = coordinator
        
        if navigationSplitCoordinator.detailCoordinator !== detailNavigationStackCoordinator {
            navigationSplitCoordinator.setDetailCoordinator(detailNavigationStackCoordinator, animated: animated)
        }
        
        coordinator.start()
    }
    
    private func dismissSpaceFlow(animated: Bool) {
        // Based on dismissRoomFlow, past me was very insistent that this must happen after the flow has tidied the stack 😅.
        navigationSplitCoordinator.setDetailCoordinator(nil, animated: animated)
        roomFlowCoordinator = nil
    }
    
    // MARK: Start Chat
    
    private func startStartChatFlow(animated: Bool) {
        let navigationStackCoordinator = NavigationStackCoordinator()
        let coordinator = StartChatFlowCoordinator(navigationStackCoordinator: navigationStackCoordinator,
                                                   flowParameters: flowParameters)
        
        coordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .finished(let roomID):
                    navigationSplitCoordinator.setSheetCoordinator(nil)
                    
                    if let roomID {
                        stateMachine.processEvent(.selectRoom(roomID: roomID, via: [], entryPoint: .room))
                    }
                case .showRoomDirectory:
                    navigationSplitCoordinator.setSheetCoordinator(nil)
                    stateMachine.processEvent(.showRoomDirectorySearchScreen)
                }
            }
            .store(in: &cancellables)
        
        startChatFlowCoordinator = coordinator
        coordinator.start()
        
        navigationSplitCoordinator.setSheetCoordinator(navigationStackCoordinator, animated: animated) { [weak self] in
            self?.stateMachine.processEvent(.finishedStartChatFlow)
        }
    }
    
    // MARK: Secure backup
    
    private func presentRecoveryKeyScreen(animated: Bool) {
        let sheetNavigationStackCoordinator = NavigationStackCoordinator()
        let parameters = SecureBackupRecoveryKeyScreenCoordinatorParameters(secureBackupController: userSession.clientProxy.secureBackupController,
                                                                            userIndicatorController: flowParameters.userIndicatorController,
                                                                            isModallyPresented: true)
        
        let coordinator = SecureBackupRecoveryKeyScreenCoordinator(parameters: parameters)
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .complete:
                navigationSplitCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        
        sheetNavigationStackCoordinator.setRootCoordinator(coordinator)
        
        navigationSplitCoordinator.setSheetCoordinator(sheetNavigationStackCoordinator, animated: animated) { [weak self] in
            self?.stateMachine.processEvent(.dismissedRecoveryKeyScreen)
        }
    }
    
    private func startEncryptionResetFlow(animated: Bool) {
        let sheetNavigationStackCoordinator = NavigationStackCoordinator()
        let parameters = EncryptionResetFlowCoordinatorParameters(userSession: userSession,
                                                                  appSettings: flowParameters.appSettings,
                                                                  userIndicatorController: flowParameters.userIndicatorController,
                                                                  navigationStackCoordinator: sheetNavigationStackCoordinator,
                                                                  windowManger: flowParameters.windowManager)
        
        let coordinator = EncryptionResetFlowCoordinator(parameters: parameters)
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .resetComplete:
                navigationSplitCoordinator.setSheetCoordinator(nil)
            case .cancel:
                navigationSplitCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        
        coordinator.start()
        encryptionResetFlowCoordinator = coordinator
        
        navigationSplitCoordinator.setSheetCoordinator(sheetNavigationStackCoordinator, animated: animated) { [weak self] in
            self?.stateMachine.processEvent(.finishedEncryptionResetFlow)
        }
    }
    
    // MARK: Global search
    
    private func presentGlobalSearch() {
        let roomSummaryProvider = userSession.clientProxy.alternateRoomSummaryProvider
        
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
                    actionsSubject.send(.switchToChatsTab)
                }
            }
            .store(in: &cancellables)
        
        let hostingController = UIHostingController(rootView: coordinator.toPresentable())
        hostingController.view.backgroundColor = .clear
        flowParameters.windowManager.globalSearchWindow.rootViewController = hostingController

        flowParameters.windowManager.showGlobalSearch()
    }
    
    private func dismissGlobalSearch() {
        flowParameters.windowManager.globalSearchWindow.rootViewController = nil
        flowParameters.windowManager.hideGlobalSearch()
        
        globalSearchScreenCoordinator = nil
    }
    
    // MARK: Room Directory Search
    
    private func presentRoomDirectorySearch() {
        let coordinator = RoomDirectorySearchScreenCoordinator(parameters: .init(userSession: userSession,
                                                                                 userIndicatorController: flowParameters.userIndicatorController))
        
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
                                                                userSession: userSession,
                                                                userIndicatorController: flowParameters.userIndicatorController,
                                                                analytics: flowParameters.analytics)
        let coordinator = UserProfileScreenCoordinator(parameters: parameters)
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .openDirectChat(let roomID):
                navigationSplitCoordinator.setSheetCoordinator(nil)
                stateMachine.processEvent(.selectRoom(roomID: roomID, via: [], entryPoint: .room))
            case .startCall(let roomProxy):
                actionsSubject.send(.showCallScreen(roomProxy: roomProxy))
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
    
    // MARK: Sharing
    
    private func presentRoomSelectionScreen(sharePayload: ShareExtensionPayload, animated: Bool) {
        let roomSummaryProvider = userSession.clientProxy.alternateRoomSummaryProvider
        
        let stackCoordinator = NavigationStackCoordinator()
        
        let coordinator = RoomSelectionScreenCoordinator(parameters: .init(userSession: userSession,
                                                                           roomSummaryProvider: roomSummaryProvider))
        
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .dismiss:
                navigationSplitCoordinator.setSheetCoordinator(nil)
            case .confirm(let roomID):
                let sharePayload = switch sharePayload {
                case .mediaFiles(_, let mediaFiles):
                    ShareExtensionPayload.mediaFiles(roomID: roomID, mediaFiles: mediaFiles)
                case .text(_, let text):
                    ShareExtensionPayload.text(roomID: roomID, text: text)
                }
                
                navigationSplitCoordinator.setSheetCoordinator(nil)
                
                stateMachine.processEvent(.selectRoom(roomID: roomID,
                                                      via: [],
                                                      entryPoint: .share(sharePayload)),
                                          userInfo: .init(animated: animated))
            }
        }
        .store(in: &cancellables)
        
        stackCoordinator.setRootCoordinator(coordinator)
        
        navigationSplitCoordinator.setSheetCoordinator(stackCoordinator, animated: animated) { [weak self] in
            self?.stateMachine.processEvent(.dismissedShareExtensionRoomList)
        }
    }
    
    private func dismissRoomSelectionScreen() {
        navigationSplitCoordinator.setSheetCoordinator(nil)
    }
    
    // MARK: Toasts and loading indicators
    
    private static let loadingIndicatorIdentifier = "\(ChatsFlowCoordinator.self)-Loading"
    private static let failureIndicatorIdentifier = "\(ChatsFlowCoordinator.self)-Failure"
    
    private func showLoadingIndicator(delay: Duration? = nil) {
        flowParameters.userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                                             type: .modal,
                                                                             title: L10n.commonLoading,
                                                                             persistent: true),
                                                               delay: delay)
    }
    
    private func hideLoadingIndicator() {
        flowParameters.userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
    
    private func showFailureIndicator() {
        flowParameters.userIndicatorController.submitIndicator(UserIndicator(id: Self.failureIndicatorIdentifier,
                                                                             type: .toast,
                                                                             title: L10n.errorUnknown,
                                                                             iconName: "xmark"))
    }
}
