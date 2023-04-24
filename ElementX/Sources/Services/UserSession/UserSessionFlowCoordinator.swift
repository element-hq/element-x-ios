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
}

class UserSessionFlowCoordinator: CoordinatorProtocol {
    private let stateMachine: UserSessionFlowCoordinatorStateMachine
    private var cancellables: Set<AnyCancellable> = .init()
    
    private let userSession: UserSessionProtocol
    private let navigationSplitCoordinator: NavigationSplitCoordinator
    private let bugReportService: BugReportServiceProtocol
    private let roomTimelineControllerFactory: RoomTimelineControllerFactoryProtocol
    private let emojiProvider: EmojiProviderProtocol = EmojiProvider()
    
    private let sidebarNavigationStackCoordinator: NavigationStackCoordinator
    private let detailNavigationStackCoordinator: NavigationStackCoordinator
    
    var callback: ((UserSessionFlowCoordinatorAction) -> Void)?
    
    init(userSession: UserSessionProtocol,
         navigationSplitCoordinator: NavigationSplitCoordinator,
         bugReportService: BugReportServiceProtocol,
         roomTimelineControllerFactory: RoomTimelineControllerFactoryProtocol) {
        stateMachine = UserSessionFlowCoordinatorStateMachine()
        self.userSession = userSession
        self.navigationSplitCoordinator = navigationSplitCoordinator
        self.bugReportService = bugReportService
        self.roomTimelineControllerFactory = roomTimelineControllerFactory
        
        sidebarNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        detailNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        
        navigationSplitCoordinator.setSidebarCoordinator(sidebarNavigationStackCoordinator)
        
        setupStateMachine()
    }
    
    func start() {
        stateMachine.processEvent(.start)
    }
    
    func stop() { }

    func isDisplayingRoomScreen(withRoomId roomId: String) -> Bool {
        stateMachine.isDisplayingRoomScreen(withRoomId: roomId)
    }

    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        switch stateMachine.state {
        case .feedbackScreen, .sessionVerificationScreen, .settingsScreen, .startChatScreen, .invitesScreen:
            navigationSplitCoordinator.setSheetCoordinator(nil, animated: animated)
        case .roomList, .initial:
            break
        }
        switch appRoute {
        case .room(let roomID):
            stateMachine.processEvent(.selectRoom(roomId: roomID), userInfo: .init(animated: animated))
        }
    }

    // MARK: - Private
    
    // swiftlint:disable:next cyclomatic_complexity
    private func setupStateMachine() {
        stateMachine.addTransitionHandler { [weak self] context in
            guard let self else { return }
            let animated = (context.userInfo as? EventUserInfo)?.animated ?? true
            switch (context.fromState, context.event, context.toState) {
            case (.initial, .start, .roomList):
                self.presentHomeScreen()
                
            case(.roomList(let currentRoomId), .selectRoom, .roomList(let selectedRoomId)):
                guard let selectedRoomId,
                      selectedRoomId != currentRoomId else {
                    return
                }
                
                self.presentRoomWithIdentifier(selectedRoomId, animated: animated)
            case(.roomList, .deselectRoom, .roomList):
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
            case (.invitesScreen, .closedInvitesScreen, .roomList):
                break
            case (.invitesScreen, .selectRoom(let roomId), .invitesScreen(let selectedRoomId)) where roomId == selectedRoomId:
                self.presentRoomWithIdentifier(roomId)
            case (.invitesScreen, .deselectRoom, .invitesScreen):
                break
            
            default:
                fatalError("Unknown transition: \(context)")
            }
        }
        
        stateMachine.addErrorHandler { context in
            fatalError("Failed transition with context: \(context)")
        }
    }
    
    private func presentHomeScreen() {
        userSession.clientProxy.startSync()

        let parameters = HomeScreenCoordinatorParameters(userSession: userSession,
                                                         attributedStringBuilder: AttributedStringBuilder(),
                                                         bugReportService: bugReportService,
                                                         navigationStackCoordinator: detailNavigationStackCoordinator)
        let coordinator = HomeScreenCoordinator(parameters: parameters)

        coordinator.callback = { [weak self] action in
            guard let self else { return }

            switch action {
            case .presentRoom(let roomIdentifier):
                self.stateMachine.processEvent(.selectRoom(roomId: roomIdentifier))
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
    
    // MARK: Rooms

    private func presentRoomWithIdentifier(_ roomIdentifier: String, animated: Bool = true) {
        Task { @MainActor in
            guard let roomProxy = await userSession.clientProxy.roomForIdentifier(roomIdentifier) else {
                MXLog.error("Invalid room identifier: \(roomIdentifier)")
                return
            }
            let userId = userSession.clientProxy.userID

            let timelineItemFactory = RoomTimelineItemFactory(userID: userId,
                                                              mediaProvider: userSession.mediaProvider,
                                                              attributedStringBuilder: AttributedStringBuilder(),
                                                              stateEventStringBuilder: RoomStateEventStringBuilder(userID: userId))
            
            let timelineController = roomTimelineControllerFactory.buildRoomTimelineController(userId: userId,
                                                                                               roomProxy: roomProxy,
                                                                                               timelineItemFactory: timelineItemFactory,
                                                                                               mediaProvider: userSession.mediaProvider)

            let parameters = RoomScreenCoordinatorParameters(navigationStackCoordinator: detailNavigationStackCoordinator,
                                                             roomProxy: roomProxy,
                                                             timelineController: timelineController,
                                                             mediaProvider: userSession.mediaProvider,
                                                             emojiProvider: emojiProvider)
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            coordinator.callback = { [weak self] action in
                switch action {
                case .leftRoom:
                    self?.dismissRoom()
                }
            }
            
            detailNavigationStackCoordinator.setRootCoordinator(coordinator, animated: animated) { [weak self, roomIdentifier] in
                guard let self else { return }
                
                // Move the state machine to no room selected if the room currently being dismissed
                // is the same as the one selected in the state machine.
                // This generally happens when popping the room screen while in a compact layout
                switch self.stateMachine.state {
                case
                    let .roomList(selectedRoomId) where selectedRoomId == roomIdentifier,
                    let .invitesScreen(selectedRoomId) where selectedRoomId == roomIdentifier:
                    
                    self.stateMachine.processEvent(.deselectRoom)
                    self.detailNavigationStackCoordinator.setRootCoordinator(nil)
                default:
                    break
                }
            }
            
            if navigationSplitCoordinator.detailCoordinator == nil {
                navigationSplitCoordinator.setDetailCoordinator(detailNavigationStackCoordinator, animated: animated)
            }
        }
    }

    private func dismissRoom() {
        detailNavigationStackCoordinator.popToRoot(animated: true)
        navigationSplitCoordinator.setDetailCoordinator(nil)
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
        let parameters = StartChatCoordinatorParameters(userSession: userSession, userIndicatorController: userIndicatorController, navigationStackCoordinator: startChatNavigationStackCoordinator, userDiscoveryService: userDiscoveryService)
        let coordinator = StartChatCoordinator(parameters: parameters)
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .close:
                self.navigationSplitCoordinator.setSheetCoordinator(nil)
            case .openRoom(let identifier):
                self.navigationSplitCoordinator.setSheetCoordinator(nil)
                self.stateMachine.processEvent(.selectRoom(roomId: identifier))
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
        
        let parameters = BugReportCoordinatorParameters(bugReportService: bugReportService,
                                                        userID: userSession.userID,
                                                        deviceID: userSession.deviceID,
                                                        userIndicatorController: userIndicatorController,
                                                        screenshot: image,
                                                        isModallyPresented: true)
        let coordinator = BugReportCoordinator(parameters: parameters)
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
        let parameters = InvitesCoordinatorParameters(userSession: userSession)
        let coordinator = InvitesCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                switch action {
                case .openRoom(let roomId):
                    self?.stateMachine.processEvent(.selectRoom(roomId: roomId))
                }
            }
            .store(in: &cancellables)
        
        sidebarNavigationStackCoordinator.push(coordinator, animated: animated) { [weak self] in
            self?.stateMachine.processEvent(.closedInvitesScreen)
        }
    }
}
