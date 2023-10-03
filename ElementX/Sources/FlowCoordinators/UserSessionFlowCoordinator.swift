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
    case signOut
    case clearCache
}

class UserSessionFlowCoordinator: FlowCoordinatorProtocol {
    private let userSession: UserSessionProtocol
    private let navigationSplitCoordinator: NavigationSplitCoordinator
    private let bugReportService: BugReportServiceProtocol
    private let roomTimelineControllerFactory: RoomTimelineControllerFactoryProtocol
    private let appSettings: AppSettings
    private let analytics: AnalyticsService
    private let actionsSubject: PassthroughSubject<UserSessionFlowCoordinatorAction, Never> = .init()
    
    private let stateMachine: UserSessionFlowCoordinatorStateMachine
    private let roomFlowCoordinator: RoomFlowCoordinator
    
    private var cancellables = Set<AnyCancellable>()
    private var migrationCancellable: AnyCancellable?
    
    private let sidebarNavigationStackCoordinator: NavigationStackCoordinator
    private let detailNavigationStackCoordinator: NavigationStackCoordinator

    private let selectedRoomSubject = CurrentValueSubject<String?, Never>(nil)
    
    var actions: AnyPublisher<UserSessionFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userSession: UserSessionProtocol,
         navigationSplitCoordinator: NavigationSplitCoordinator,
         bugReportService: BugReportServiceProtocol,
         roomTimelineControllerFactory: RoomTimelineControllerFactoryProtocol,
         appSettings: AppSettings,
         analytics: AnalyticsService) {
        stateMachine = UserSessionFlowCoordinatorStateMachine()
        self.userSession = userSession
        self.navigationSplitCoordinator = navigationSplitCoordinator
        self.bugReportService = bugReportService
        self.roomTimelineControllerFactory = roomTimelineControllerFactory
        self.appSettings = appSettings
        self.analytics = analytics
        
        sidebarNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        detailNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        
        navigationSplitCoordinator.setSidebarCoordinator(sidebarNavigationStackCoordinator)
        
        roomFlowCoordinator = RoomFlowCoordinator(userSession: userSession,
                                                  roomTimelineControllerFactory: roomTimelineControllerFactory,
                                                  navigationStackCoordinator: detailNavigationStackCoordinator,
                                                  navigationSplitCoordinator: navigationSplitCoordinator,
                                                  emojiProvider: EmojiProvider(),
                                                  appSettings: appSettings,
                                                  analytics: analytics,
                                                  userIndicatorController: ServiceLocator.shared.userIndicatorController)
        
        setupStateMachine()
        
        roomFlowCoordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .presentedRoom(let roomID):
                analytics.signpost.beginRoomFlow(roomID)
                stateMachine.processEvent(.selectRoom(roomID: roomID))
            case .dismissedRoom:
                stateMachine.processEvent(.deselectRoom)
                analytics.signpost.endRoomFlow()
            }
        }
        .store(in: &cancellables)
    }
    
    func start() {
        if appSettings.migratedAccounts[userSession.userID] != true {
            // Show the migration screen for a new account.
            stateMachine.processEvent(.startWithMigration)
        } else if !appSettings.hasShownWelcomeScreen {
            stateMachine.processEvent(.startWithWelcomeScreen)
        } else {
            // Otherwise go straight to the home screen.
            stateMachine.processEvent(.start)
        }
    }
    
    func stop() { }

    func isDisplayingRoomScreen(withRoomID roomID: String) -> Bool {
        stateMachine.isDisplayingRoomScreen(withRoomID: roomID)
    }
    
    // MARK: - FlowCoordinatorProtocol
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        clearPresentedSheets(animated: animated) { [weak self] in
            guard let self else { return }
            
            switch appRoute {
            case .room, .roomDetails, .roomList, .roomMemberDetails:
                self.roomFlowCoordinator.handleAppRoute(appRoute, animated: animated)
            case .invites:
                if UIDevice.current.isPhone {
                    self.roomFlowCoordinator.clearRoute(animated: animated)
                }
                self.stateMachine.processEvent(.showInvitesScreen, userInfo: .init(animated: animated))
            case .genericCallLink(let url):
                self.navigationSplitCoordinator.setSheetCoordinator(GenericCallLinkCoordinator(parameters: .init(url: url)), animated: animated)
            case .oidcCallback:
                break
            }
        }
    }

    func clearRoute(animated: Bool) {
        fatalError("not necessary as of right now")
    }

    // MARK: - Private
    
    private func clearPresentedSheets(animated: Bool, completion: @escaping () -> Void) {
        if navigationSplitCoordinator.sheetCoordinator == nil {
            completion()
            return
        }
        
        navigationSplitCoordinator.setSheetCoordinator(nil, animated: animated)
        
        // Prevents system crashes when presenting a sheet if another one was already shown
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            completion()
        }
    }
    
    private func setupStateMachine() {
        stateMachine.addTransitionHandler { [weak self] context in
            guard let self else { return }
            let animated = (context.userInfo as? UserSessionFlowCoordinatorStateMachine.EventUserInfo)?.animated ?? true
            switch (context.fromState, context.event, context.toState) {
            case (.initial, .start, .roomList):
                presentHomeScreen()
            
            case (.initial, .startWithMigration, .migration):
                presentMigrationScreen() // Full screen cover
                presentHomeScreen() // Have the home screen ready to show underneath
            case (.migration, .completeMigration, .roomList):
                dismissMigrationScreen()

            case (.initial, .startWithWelcomeScreen, .welcomeScreen):
                presentHomeScreen()
                presentWelcomeScreen()
            case (.roomList, .presentWelcomeScreen, .welcomeScreen):
                presentWelcomeScreen()
            case (.welcomeScreen, .dismissedWelcomeScreen, .roomList):
                break
                
            case(.roomList, .selectRoom, .roomList):
                break
            case(.roomList, .deselectRoom, .roomList):
                break
                
            case (.invitesScreen, .selectRoom, .invitesScreen):
                break
            case (.invitesScreen, .deselectRoom, .invitesScreen):
                break

            case (.roomList, .showSessionVerificationScreen, .sessionVerificationScreen):
                presentSessionVerification(animated: animated)
            case (.sessionVerificationScreen, .dismissedSessionVerificationScreen, .roomList):
                break
                
            case (.roomList, .showSettingsScreen, .settingsScreen):
                presentSettingsScreen(animated: animated)
            case (.settingsScreen, .dismissedSettingsScreen, .roomList):
                break
                
            case (.roomList, .feedbackScreen, .feedbackScreen):
                presentFeedbackScreen(animated: animated)
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
            case (.invitesScreen, .closedInvitesScreen, .roomList):
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
    
    private func presentMigrationScreen() {
        // Listen for the first sync to finish.
        migrationCancellable = userSession.clientProxy.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                guard let self, stateMachine.state == .migration, case .receivedSyncUpdate = callback else { return }
                migrationCancellable = nil
                appSettings.migratedAccounts[userSession.userID] = true
                stateMachine.processEvent(.completeMigration)
            }
        
        let coordinator = MigrationScreenCoordinator()
        navigationSplitCoordinator.setFullScreenCoverCoordinator(coordinator)
    }
    
    private func dismissMigrationScreen() {
        navigationSplitCoordinator.setFullScreenCoverCoordinator(nil)

        // Not sure why but the full screen closure dismissal closure doesn't seem to work properly
        // And not using the DispatchQueue.main results in the the screen getting presented as full screen too.
        if !appSettings.hasShownWelcomeScreen {
            DispatchQueue.main.async {
                self.stateMachine.processEvent(.presentWelcomeScreen)
            }
        }
    }
    
    private func presentHomeScreen() {
        let parameters = HomeScreenCoordinatorParameters(userSession: userSession,
                                                         attributedStringBuilder: AttributedStringBuilder(permalinkBaseURL: ServiceLocator.shared.settings.permalinkBaseURL,
                                                                                                          mentionBuilder: MentionBuilder(mentionsEnabled: ServiceLocator.shared.settings.mentionsEnabled)),
                                                         bugReportService: bugReportService,
                                                         navigationStackCoordinator: detailNavigationStackCoordinator,
                                                         selectedRoomPublisher: selectedRoomSubject.asCurrentValuePublisher())
        let coordinator = HomeScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .presentRoom(let roomID):
                    roomFlowCoordinator.handleAppRoute(.room(roomID: roomID), animated: true)
                case .presentRoomDetails(let roomID):
                    roomFlowCoordinator.handleAppRoute(.roomDetails(roomID: roomID), animated: true)
                case .roomLeft(let roomID):
                    if case .roomList(selectedRoomID: let selectedRoomID) = stateMachine.state,
                       selectedRoomID == roomID {
                        roomFlowCoordinator.handleAppRoute(.roomList, animated: true)
                    }
                case .presentSettingsScreen:
                    stateMachine.processEvent(.showSettingsScreen)
                case .presentFeedbackScreen:
                    stateMachine.processEvent(.feedbackScreen)
                case .presentSessionVerificationScreen:
                    stateMachine.processEvent(.showSessionVerificationScreen)
                case .presentStartChatScreen:
                    stateMachine.processEvent(.showStartChatScreen)
                case .signOut:
                    actionsSubject.send(.signOut)
                case .presentInvitesScreen:
                    stateMachine.processEvent(.showInvitesScreen)
                }
            }
            .store(in: &cancellables)
        
        sidebarNavigationStackCoordinator.setRootCoordinator(coordinator)
    }

    private func presentWelcomeScreen() {
        let welcomeScreenCoordinator = WelcomeScreenScreenCoordinator()
        welcomeScreenCoordinator.actions.sink { [weak self] action in
            switch action {
            case .dismiss:
                self?.navigationSplitCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)

        navigationSplitCoordinator.setSheetCoordinator(welcomeScreenCoordinator) { [weak self] in
            self?.stateMachine.processEvent(.dismissedWelcomeScreen)
        }
    }
    
    // MARK: Settings
    
    private func presentSettingsScreen(animated: Bool) {
        let settingsNavigationStackCoordinator = NavigationStackCoordinator()
        
        let userIndicatorController = UserIndicatorController(rootCoordinator: settingsNavigationStackCoordinator)
        
        let parameters = SettingsScreenCoordinatorParameters(navigationStackCoordinator: settingsNavigationStackCoordinator,
                                                             userIndicatorController: userIndicatorController,
                                                             userSession: userSession,
                                                             bugReportService: bugReportService,
                                                             notificationSettings: userSession.clientProxy.notificationSettings,
                                                             appSettings: appSettings)
        let settingsScreenCoordinator = SettingsScreenCoordinator(parameters: parameters)
        
        settingsScreenCoordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .dismiss:
                    navigationSplitCoordinator.setSheetCoordinator(nil)
                case .logout:
                    navigationSplitCoordinator.setSheetCoordinator(nil)
                    actionsSubject.send(.signOut)
                case .clearCache:
                    actionsSubject.send(.clearCache)
                }
            }
            .store(in: &cancellables)
        
        settingsNavigationStackCoordinator.setRootCoordinator(settingsScreenCoordinator, animated: animated)
        
        navigationSplitCoordinator.setSheetCoordinator(userIndicatorController) { [weak self] in
            self?.stateMachine.processEvent(.dismissedSettingsScreen)
        }
    }
    
    // MARK: Session verification
    
    private func presentSessionVerification(animated: Bool) {
        guard let sessionVerificationController = userSession.sessionVerificationController else {
            fatalError("The sessionVerificationController should aways be valid at this point")
        }
        
        let parameters = SessionVerificationScreenCoordinatorParameters(sessionVerificationControllerProxy: sessionVerificationController)
        
        let coordinator = SessionVerificationScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .done:
                    navigationSplitCoordinator.setSheetCoordinator(nil)
                }
            }
            .store(in: &cancellables)
        
        navigationSplitCoordinator.setSheetCoordinator(coordinator, animated: animated) { [weak self] in
            self?.stateMachine.processEvent(.dismissedSessionVerificationScreen)
        }
    }
    
    // MARK: Start Chat
    
    private func presentStartChat(animated: Bool) {
        let startChatNavigationStackCoordinator = NavigationStackCoordinator()
        
        let userIndicatorController = UserIndicatorController(rootCoordinator: startChatNavigationStackCoordinator)
        let userDiscoveryService = UserDiscoveryService(clientProxy: userSession.clientProxy)
        let parameters = StartChatScreenCoordinatorParameters(userSession: userSession, userIndicatorController: userIndicatorController, navigationStackCoordinator: startChatNavigationStackCoordinator, userDiscoveryService: userDiscoveryService)
        let coordinator = StartChatScreenCoordinator(parameters: parameters)
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .close:
                self.navigationSplitCoordinator.setSheetCoordinator(nil)
            case .openRoom(let roomID):
                self.navigationSplitCoordinator.setSheetCoordinator(nil)
                self.roomFlowCoordinator.handleAppRoute(.room(roomID: roomID), animated: true)
            }
        }
        .store(in: &cancellables)

        startChatNavigationStackCoordinator.setRootCoordinator(coordinator)
        
        navigationSplitCoordinator.setSheetCoordinator(userIndicatorController, animated: animated) { [weak self] in
            self?.stateMachine.processEvent(.dismissedStartChatScreen)
        }
    }
    
    // MARK: Bug reporting
    
    private func presentFeedbackScreen(animated: Bool, for image: UIImage? = nil) {
        let feedbackNavigationStackCoordinator = NavigationStackCoordinator()
        
        let userIndicatorController = UserIndicatorController(rootCoordinator: feedbackNavigationStackCoordinator)
        
        let parameters = BugReportScreenCoordinatorParameters(bugReportService: bugReportService,
                                                              userID: userSession.userID,
                                                              deviceID: userSession.deviceID,
                                                              userIndicatorController: userIndicatorController,
                                                              screenshot: image,
                                                              isModallyPresented: true)
        let coordinator = BugReportScreenCoordinator(parameters: parameters)
        coordinator.completion = { [weak self] _ in
            self?.navigationSplitCoordinator.setSheetCoordinator(nil)
        }

        feedbackNavigationStackCoordinator.setRootCoordinator(coordinator)
        
        navigationSplitCoordinator.setSheetCoordinator(userIndicatorController, animated: animated) { [weak self] in
            self?.stateMachine.processEvent(.dismissedFeedbackScreen)
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
                    self?.roomFlowCoordinator.handleAppRoute(.room(roomID: roomID), animated: true)
                }
            }
            .store(in: &cancellables)
        
        sidebarNavigationStackCoordinator.push(coordinator, animated: animated) { [weak self] in
            self?.stateMachine.processEvent(.closedInvitesScreen)
        }
    }
}
