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
    
    private let stateMachine: UserSessionFlowCoordinatorStateMachine
    private let roomFlowCoordinator: RoomFlowCoordinator
    
    private var cancellables: Set<AnyCancellable> = .init()
    private var migrationCancellable: AnyCancellable?
    
    private let sidebarNavigationStackCoordinator: NavigationStackCoordinator
    private let detailNavigationStackCoordinator: NavigationStackCoordinator
    
    private let selectedRoomSubject = CurrentValueSubject<String?, Never>(nil)
    
    var callback: ((UserSessionFlowCoordinatorAction) -> Void)?
    
    init(userSession: UserSessionProtocol,
         navigationSplitCoordinator: NavigationSplitCoordinator,
         bugReportService: BugReportServiceProtocol,
         roomTimelineControllerFactory: RoomTimelineControllerFactoryProtocol,
         appSettings: AppSettings) {
        stateMachine = UserSessionFlowCoordinatorStateMachine()
        self.userSession = userSession
        self.navigationSplitCoordinator = navigationSplitCoordinator
        self.bugReportService = bugReportService
        self.roomTimelineControllerFactory = roomTimelineControllerFactory
        self.appSettings = appSettings
        
        sidebarNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        detailNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        
        navigationSplitCoordinator.setSidebarCoordinator(sidebarNavigationStackCoordinator)
        
        roomFlowCoordinator = RoomFlowCoordinator(userSession: userSession,
                                                  roomTimelineControllerFactory: roomTimelineControllerFactory,
                                                  navigationStackCoordinator: detailNavigationStackCoordinator,
                                                  navigationSplitCoordinator: navigationSplitCoordinator,
                                                  emojiProvider: EmojiProvider(),
                                                  appSettings: ServiceLocator.shared.settings,
                                                  analytics: ServiceLocator.shared.analytics,
                                                  userIndicatorController: ServiceLocator.shared.userIndicatorController)
        
        setupStateMachine()
        
        roomFlowCoordinator.actions.sink { action in
            switch action {
            case .presentedRoom(let roomID):
                self.stateMachine.processEvent(.selectRoom(roomId: roomID))
            case .dismissedRoom:
                self.stateMachine.processEvent(.deselectRoom)
            }
        }
        .store(in: &cancellables)
    }
    
    func start() {
        if appSettings.migratedAccounts[userSession.userID] != true {
            // Show the migration screen for a new account.
            stateMachine.processEvent(.startWithMigration)
        } else {
            // Otherwise go straight to the home screen.
            stateMachine.processEvent(.start)
        }
    }
    
    func stop() { }

    func isDisplayingRoomScreen(withRoomId roomId: String) -> Bool {
        stateMachine.isDisplayingRoomScreen(withRoomId: roomId)
    }
    
    // MARK: - FlowCoordinatorProtocol

    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        // Tidy up any state before applying the new route.
        switch stateMachine.state {
        case .initial, .migration:
            return // Not ready to handle a route.
        case .roomList:
            break // Nothing to tidy up on the home screen.
        case .feedbackScreen, .sessionVerificationScreen, .settingsScreen, .startChatScreen, .invitesScreen:
            navigationSplitCoordinator.setSheetCoordinator(nil, animated: animated)
        }
        
        // Apply the route.
        switch appRoute {
        case .room, .roomDetails, .roomList:
            roomFlowCoordinator.handleAppRoute(appRoute, animated: animated)
        case .invites:
            if UIDevice.current.isPhone {
                roomFlowCoordinator.clearRoute(animated: animated)
            }
            stateMachine.processEvent(.showInvitesScreen, userInfo: .init(animated: animated))
        }
    }

    func clearRoute(animated: Bool) {
        fatalError("not necessary as of right now")
    }

    // MARK: - Private
    
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func setupStateMachine() {
        stateMachine.addTransitionHandler { [weak self] context in
            guard let self else { return }
            let animated = (context.userInfo as? UserSessionFlowCoordinatorStateMachine.EventUserInfo)?.animated ?? true
            switch (context.fromState, context.event, context.toState) {
            case (.initial, .start, .roomList):
                self.presentHomeScreen()
            
            case (.initial, .startWithMigration, .migration):
                self.presentMigrationScreen() // Full screen cover
                self.presentHomeScreen() // Have the home screen ready to show underneath
            case (.migration, .completeMigration, .roomList):
                self.dismissMigrationScreen()
                
            case(.roomList, .selectRoom, .roomList):
                break
            case(.roomList, .deselectRoom, .roomList):
                break
                
            case (.invitesScreen, .selectRoom, .invitesScreen):
                break
            case (.invitesScreen, .deselectRoom, .invitesScreen):
                break

            case (.roomList, .showSessionVerificationScreen, .sessionVerificationScreen):
                self.presentSessionVerification(animated: animated)
            case (.sessionVerificationScreen, .dismissedSessionVerificationScreen, .roomList):
                break
                
            case (.roomList, .showSettingsScreen, .settingsScreen):
                self.presentSettingsScreen(animated: animated)
            case (.settingsScreen, .dismissedSettingsScreen, .roomList):
                break
                
            case (.roomList, .feedbackScreen, .feedbackScreen):
                self.presentFeedbackScreen(animated: animated)
            case (.feedbackScreen, .dismissedFeedbackScreen, .roomList):
                break
                
            case (.roomList, .showStartChatScreen, .startChatScreen):
                self.presentStartChat(animated: animated)
            case (.startChatScreen, .dismissedStartChatScreen, .roomList):
                break
                
            case (.roomList, .showInvitesScreen, .invitesScreen):
                self.presentInvitesList(animated: animated)
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
            case .roomList(let selectedRoomId):
                self?.selectedRoomSubject.send(selectedRoomId)
            default:
                break
            }
        }
        
        stateMachine.addErrorHandler { context in
            fatalError("Failed transition with context: \(context)")
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
    }
    
    // swiftlint:disable:next cyclomatic_complexity
    private func presentHomeScreen() {
        let parameters = HomeScreenCoordinatorParameters(userSession: userSession,
                                                         attributedStringBuilder: AttributedStringBuilder(permalinkBaseURL: ServiceLocator.shared.settings.permalinkBaseURL),
                                                         bugReportService: bugReportService,
                                                         navigationStackCoordinator: detailNavigationStackCoordinator,
                                                         selectedRoomPublisher: selectedRoomSubject.asCurrentValuePublisher())
        let coordinator = HomeScreenCoordinator(parameters: parameters)

        coordinator.callback = { [weak self] action in
            guard let self else { return }

            switch action {
            case .presentRoom(let roomID):
                self.roomFlowCoordinator.handleAppRoute(.room(roomID: roomID), animated: true)
            case .presentRoomDetails(let roomID):
                self.roomFlowCoordinator.handleAppRoute(.roomDetails(roomID: roomID), animated: true)
            case .roomLeft(let roomID):
                if case .roomList(selectedRoomId: let selectedRoomId) = stateMachine.state,
                   selectedRoomId == roomID {
                    self.roomFlowCoordinator.handleAppRoute(.roomList, animated: true)
                }
            case .presentSettingsScreen:
                self.stateMachine.processEvent(.showSettingsScreen)
            case .presentFeedbackScreen:
                self.stateMachine.processEvent(.feedbackScreen)
            case .presentSessionVerificationScreen:
                self.stateMachine.processEvent(.showSessionVerificationScreen)
            case .presentStartChatScreen:
                self.stateMachine.processEvent(.showStartChatScreen)
            case .signOut:
                self.callback?(.signOut)
            case .presentInvitesScreen:
                self.stateMachine.processEvent(.showInvitesScreen)
            }
        }
        
        sidebarNavigationStackCoordinator.setRootCoordinator(coordinator)
    }
    
    // MARK: Settings
    
    private func presentSettingsScreen(animated: Bool) {
        let settingsNavigationStackCoordinator = NavigationStackCoordinator()
        
        let userIndicatorController = UserIndicatorController(rootCoordinator: settingsNavigationStackCoordinator)
        
        let parameters = SettingsScreenCoordinatorParameters(navigationStackCoordinator: settingsNavigationStackCoordinator,
                                                             userIndicatorController: userIndicatorController,
                                                             userSession: userSession,
                                                             bugReportService: bugReportService)
        let settingsScreenCoordinator = SettingsScreenCoordinator(parameters: parameters)
        settingsScreenCoordinator.callback = { [weak self] action in
            guard let self else { return }
            switch action {
            case .dismiss:
                self.navigationSplitCoordinator.setSheetCoordinator(nil)
            case .logout:
                self.navigationSplitCoordinator.setSheetCoordinator(nil)
                self.callback?(.signOut)
            case .clearCache:
                self.callback?(.clearCache)
            }
        }
        
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
        
        coordinator.callback = { [weak self] in
            self?.navigationSplitCoordinator.setSheetCoordinator(nil)
        }
        
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
