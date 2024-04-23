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
    private let appMediator: AppMediatorProtocol
    private let appSettings: AppSettings
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
         roomTimelineControllerFactory: RoomTimelineControllerFactoryProtocol,
         appMediator: AppMediatorProtocol,
         appSettings: AppSettings,
         analytics: AnalyticsService,
         notificationManager: NotificationManagerProtocol,
         isNewLogin: Bool) {
        stateMachine = UserSessionFlowCoordinatorStateMachine()
        self.userSession = userSession
        self.navigationRootCoordinator = navigationRootCoordinator
        self.bugReportService = bugReportService
        self.roomTimelineControllerFactory = roomTimelineControllerFactory
        self.appMediator = appMediator
        self.appSettings = appSettings
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
            
                analytics.trackError(context: nil, domain: .E2EE, name: .OlmKeysNotSentError, timeToDecryptMillis: timeToDecryptMs)
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
        case .room(let roomID):
            stateMachine.processEvent(.selectRoom(roomID: roomID, showingRoomDetails: false), userInfo: .init(animated: animated))
        case .roomAlias(let alias):
            guard let roomID = await userSession.clientProxy.resolveRoomAlias(alias) else {
                return
            }
            
            stateMachine.processEvent(.selectRoom(roomID: roomID, showingRoomDetails: false), userInfo: .init(animated: animated))
        case .childRoom(let roomID):
            if let roomFlowCoordinator {
                roomFlowCoordinator.handleAppRoute(appRoute, animated: animated)
            } else {
                stateMachine.processEvent(.selectRoom(roomID: roomID, showingRoomDetails: false), userInfo: .init(animated: animated))
            }
        case .childRoomAlias(let alias):
            guard let roomID = await userSession.clientProxy.resolveRoomAlias(alias) else {
                return
            }
            
            if let roomFlowCoordinator {
                roomFlowCoordinator.handleAppRoute(.childRoom(roomID: roomID), animated: animated)
            } else {
                stateMachine.processEvent(.selectRoom(roomID: roomID, showingRoomDetails: false), userInfo: .init(animated: animated))
            }
        case .roomDetails(let roomID):
            if stateMachine.state.selectedRoomID == roomID {
                roomFlowCoordinator?.handleAppRoute(appRoute, animated: animated)
            } else {
                stateMachine.processEvent(.selectRoom(roomID: roomID, showingRoomDetails: true), userInfo: .init(animated: animated))
            }
        case .roomList:
            roomFlowCoordinator?.clearRoute(animated: animated)
        case .roomMemberDetails:
            roomFlowCoordinator?.handleAppRoute(appRoute, animated: animated)
        case .userProfile(let userID):
            stateMachine.processEvent(.showUserProfileScreen(userID: userID), userInfo: .init(animated: animated))
        case .genericCallLink(let url):
            navigationSplitCoordinator.setSheetCoordinator(GenericCallLinkCoordinator(parameters: .init(url: url)), animated: animated)
        case .oidcCallback:
            break
        case .settings, .chatBackupSettings:
            settingsFlowCoordinator.handleAppRoute(appRoute, animated: animated)
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
                
            case(.roomList(let selectedRoomID), .selectRoom(let roomID, let showingRoomDetails), .roomList):
                if selectedRoomID == roomID {
                    if let roomFlowCoordinator {
                        roomFlowCoordinator.handleAppRoute(.room(roomID: roomID), animated: animated)
                    }
                } else {
                    Task { await self.startRoomFlow(roomID: roomID, showingRoomDetails: showingRoomDetails, animated: animated) }
                }
            case(.roomList, .deselectRoom, .roomList):
                dismissRoomFlow(animated: animated)
                
            case (.invitesScreen, .selectRoom, .invitesScreen):
                break
            case (.invitesScreen, .deselectRoom, .invitesScreen):
                dismissRoomFlow(animated: animated)
                
            case (.roomList, .showSettingsScreen, .settingsScreen):
                break
            case (.settingsScreen, .dismissedSettingsScreen, .roomList):
                break
                
            case (.roomList, .feedbackScreen, .feedbackScreen):
                bugReportFlowCoordinator = BugReportFlowCoordinator(parameters: .init(presentationMode: .sheet(sidebarNavigationStackCoordinator),
                                                                                      userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                                                      bugReportService: bugReportService,
                                                                                      userID: userSession.userID,
                                                                                      deviceID: userSession.deviceID))
                bugReportFlowCoordinator?.start()
            case (.feedbackScreen, .dismissedFeedbackScreen, .roomList):
                break
                
            case (.roomList, .showStartChatScreen, .startChatScreen):
                presentStartChat(animated: animated)
            case (.startChatScreen, .dismissedStartChatScreen, .roomList):
                break
                
            case (.roomList, .showInvitesScreen, .invitesScreen):
                presentInvitesList(animated: animated)
            case (.invitesScreen, .showInvitesScreen, .invitesScreen):
                break
            case (.invitesScreen, .dismissedInvitesScreen, .roomList):
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
                                                         attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                                         bugReportService: bugReportService,
                                                         navigationStackCoordinator: detailNavigationStackCoordinator,
                                                         selectedRoomPublisher: selectedRoomSubject.asCurrentValuePublisher())
        let coordinator = HomeScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .presentRoom(let roomID):
                    handleAppRoute(.room(roomID: roomID), animated: true)
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
                case .logout:
                    Task { await self.runLogoutFlow() }
                case .presentInvitesScreen:
                    stateMachine.processEvent(.showInvitesScreen)
                case .presentGlobalSearch:
                    presentGlobalSearch()
                case .presentRoomDirectorySearch:
                    stateMachine.processEvent(.showRoomDirectorySearchScreen)
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
            ServiceLocator.shared.userIndicatorController.alertInfo = .init(id: .init(),
                                                                            title: L10n.screenSignoutConfirmationDialogTitle,
                                                                            message: L10n.screenSignoutConfirmationDialogContent,
                                                                            primaryButton: .init(title: L10n.screenSignoutConfirmationDialogSubmit, role: .destructive) { [weak self] in
                                                                                self?.actionsSubject.send(.logout)
                                                                            })
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
    
    // MARK: Room Flow
    
    private func startRoomFlow(roomID: String, showingRoomDetails: Bool, animated: Bool) async {
        let coordinator = await RoomFlowCoordinator(roomID: roomID,
                                                    userSession: userSession,
                                                    isChildFlow: false,
                                                    roomTimelineControllerFactory: roomTimelineControllerFactory,
                                                    navigationStackCoordinator: detailNavigationStackCoordinator,
                                                    emojiProvider: EmojiProvider(),
                                                    appMediator: appMediator,
                                                    appSettings: appSettings,
                                                    analytics: analytics,
                                                    userIndicatorController: ServiceLocator.shared.userIndicatorController)
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .finished:
                stateMachine.processEvent(.deselectRoom)
            case .presentRoom(let roomID):
                stateMachine.processEvent(.selectRoom(roomID: roomID, showingRoomDetails: false))
            case .presentCallScreen(let roomProxy):
                presentCallScreen(roomProxy: roomProxy)
            }
        }
        .store(in: &cancellables)
        
        roomFlowCoordinator = coordinator
        
        if navigationSplitCoordinator.detailCoordinator !== detailNavigationStackCoordinator {
            navigationSplitCoordinator.setDetailCoordinator(detailNavigationStackCoordinator, animated: animated)
        }
        
        if showingRoomDetails {
            coordinator.handleAppRoute(.roomDetails(roomID: roomID), animated: animated)
        } else {
            coordinator.handleAppRoute(.room(roomID: roomID), animated: animated)
        }
        
        let availableInvitesCount = userSession.clientProxy.inviteSummaryProvider?.roomListPublisher.value.count ?? 0
        if case .invitesScreen = stateMachine.state, availableInvitesCount == 1 {
            dismissInvitesList(animated: true)
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
                self.stateMachine.processEvent(.selectRoom(roomID: roomID, showingRoomDetails: false))
            }
        }
        .store(in: &cancellables)

        startChatNavigationStackCoordinator.setRootCoordinator(coordinator)

        navigationSplitCoordinator.setSheetCoordinator(startChatNavigationStackCoordinator, animated: animated) { [weak self] in
            self?.stateMachine.processEvent(.dismissedStartChatScreen)
        }
    }
        
    // MARK: Invites list
    
    private func presentInvitesList(animated: Bool) {
        let parameters = InvitesScreenCoordinatorParameters(userSession: userSession)
        let coordinator = InvitesScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                switch action {
                case .openRoom(let roomID):
                    self?.stateMachine.processEvent(.selectRoom(roomID: roomID, showingRoomDetails: false))
                }
            }
            .store(in: &cancellables)
        
        sidebarNavigationStackCoordinator.push(coordinator, animated: animated) { [weak self] in
            self?.stateMachine.processEvent(.dismissedInvitesScreen)
        }
        
        Task {
            await notificationManager.removeDeliveredInviteNotifications()
        }
    }
    
    private func dismissInvitesList(animated: Bool) {
        guard case .invitesScreen = stateMachine.state else {
            fatalError()
        }
        
        sidebarNavigationStackCoordinator.pop(animated: animated)
    }
    
    // MARK: Calls
    
    private func presentCallScreen(roomProxy: RoomProxyProtocol) {
        let callScreenCoordinator = CallScreenCoordinator(parameters: .init(roomProxy: roomProxy,
                                                                            callBaseURL: appSettings.elementCallBaseURL,
                                                                            clientID: InfoPlistReader.main.bundleIdentifier))
        
        callScreenCoordinator.actions
            .sink { [weak self] action in
                switch action {
                case .dismiss:
                    self?.navigationSplitCoordinator.setSheetCoordinator(nil)
                }
            }
            .store(in: &cancellables)
        
        navigationSplitCoordinator.setSheetCoordinator(callScreenCoordinator, animated: true)
    }
    
    // MARK: Secure backup confirmation
    
    private func presentSecureBackupLogoutConfirmationScreen() {
        let coordinator = SecureBackupLogoutConfirmationScreenCoordinator(parameters: .init(secureBackupController: userSession.clientProxy.secureBackupController,
                                                                                            networkMonitor: ServiceLocator.shared.networkMonitor))
        
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
                    handleAppRoute(.room(roomID: roomID), animated: true)
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
                                                                                 imageProvider: userSession.mediaProvider,
                                                                                 userIndicatorController: ServiceLocator.shared.userIndicatorController))
        
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .select(let roomID):
                stateMachine.processEvent(.dismissedRoomDirectorySearchScreen)
                handleAppRoute(.room(roomID: roomID), animated: true)
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
                stateMachine.processEvent(.selectRoom(roomID: roomID, showingRoomDetails: false))
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
}
