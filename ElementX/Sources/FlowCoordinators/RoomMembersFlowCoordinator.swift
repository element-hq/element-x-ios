//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftState
import SwiftUI

enum RoomMembersFlowCoordinatorAction {
    case finished
    case presentCallScreen(roomProxy: JoinedRoomProxyProtocol)
    case verifyUser(userID: String)
}

enum RoomMembersFlowCoordinatorEntryPoint: Hashable {
    /// To be used in a room when a member name is tapped
    case roomMember(userID: String)
    /// To be used in the context of room details, space details etc.
    case roomMembersList
}

final class RoomMembersFlowCoordinator: FlowCoordinatorProtocol {
    indirect enum State: StateType {
        /// The state machine hasn't started.
        case initial
        /// The room members list
        case roomMembersList
        /// The details for a member of the room
        case roomMemberDetails(userID: String, previousState: State)
        /// In case the details won't load because the user has left the room we load the profile
        case userProfile(userID: String, previousState: State)
        /// The invite users screen
        case inviteUsersScreen
        /// A room flow has been started
        case roomFlow(roomID: String, previousState: State)
    }
    
    enum Event: EventType {
        case start
        
        case presentRoomMembersList

        case presentRoomMemberDetails(userID: String)
        case dismissedRoomMemberDetails
        
        case presentInviteUsersScreen
        case dismissedInviteUsersScreen
        
        case presentUserProfile(userID: String)
        case dismissedUserProfile
        
        case startRoomFlow(roomID: String, via: [String], eventID: String?)
        case stopRoomFlow
    }
    
    private let entryPoint: RoomMembersFlowCoordinatorEntryPoint
    private let roomProxy: JoinedRoomProxyProtocol
    private let navigationStackCoordinator: NavigationStackCoordinator
    private let flowParameters: CommonFlowParameters
    
    private let stateMachine: StateMachine<State, Event>
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<RoomMembersFlowCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<RoomMembersFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var roomFlowCoordinator: RoomFlowCoordinator?
    
    init(entryPoint: RoomMembersFlowCoordinatorEntryPoint,
         roomProxy: JoinedRoomProxyProtocol,
         navigationStackCoordinator: NavigationStackCoordinator,
         flowParameters: CommonFlowParameters) {
        self.entryPoint = entryPoint
        self.roomProxy = roomProxy
        self.flowParameters = flowParameters
        self.navigationStackCoordinator = navigationStackCoordinator
        
        stateMachine = .init(state: .initial)
        configureStateMachine()
    }
    
    func start(animated: Bool) {
        switch entryPoint {
        case .roomMember(let userID):
            stateMachine.tryEvent(.presentRoomMemberDetails(userID: userID), userInfo: animated)
        case .roomMembersList:
            stateMachine.tryEvent(.presentRoomMembersList, userInfo: animated)
        }
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        switch appRoute {
        case .roomMemberDetails(let userID):
            if case .roomFlow = stateMachine.state, let roomFlowCoordinator {
                roomFlowCoordinator.handleAppRoute(appRoute, animated: animated)
            } else {
                stateMachine.tryEvent(.presentRoomMemberDetails(userID: userID), userInfo: animated)
            }
        case .childRoom(let roomID, let via):
            if case .roomFlow = stateMachine.state, let roomFlowCoordinator {
                roomFlowCoordinator.handleAppRoute(appRoute, animated: animated)
            } else {
                stateMachine.tryEvent(.startRoomFlow(roomID: roomID, via: via, eventID: nil), userInfo: animated)
            }
        case .childEvent(let eventID, let roomID, let via):
            if case .roomFlow = stateMachine.state, let roomFlowCoordinator {
                roomFlowCoordinator.handleAppRoute(appRoute, animated: animated)
            } else {
                stateMachine.tryEvent(.startRoomFlow(roomID: roomID, via: via, eventID: eventID), userInfo: animated)
            }
        case .roomAlias, .childRoomAlias, .eventOnRoomAlias, .childEventOnRoomAlias:
            break // These are converted to a room ID route one level above.
        case .accountProvisioningLink, .roomList, .room, .roomDetails, .event,
             .userProfile, .call, .genericCallLink, .settings, .chatBackupSettings,
             .share, .transferOwnership, .thread:
            break
        }
    }
    
    func clearRoute(animated: Bool) {
        if stateMachine.state == .inviteUsersScreen {
            navigationStackCoordinator.setSheetCoordinator(nil, animated: animated)
        } else if let roomFlowCoordinator {
            roomFlowCoordinator.clearRoute(animated: animated)
        }
        // We don't support dismissing a sub flow by itself, only the entire chain.
        // The presenter flow will take care of dismissing it
        actionsSubject.send(.finished)
    }
    
    private func configureStateMachine() {
        stateMachine.addRouteMapping { event, fromState, _ in
            switch (fromState, event) {
            case (.initial, .presentRoomMembersList):
                return .roomMembersList
                
            case (_, .presentRoomMemberDetails(let userID)):
                return .roomMemberDetails(userID: userID, previousState: fromState)
            case (.roomMemberDetails(_, let previousState), .dismissedRoomMemberDetails):
                return previousState
                
            case (.roomMembersList, .presentInviteUsersScreen):
                return .inviteUsersScreen
            case (.inviteUsersScreen, .dismissedInviteUsersScreen):
                return .roomMembersList
                
            case (.roomMemberDetails(_, let previousState), .presentUserProfile(let userID)):
                return .userProfile(userID: userID, previousState: previousState)
            case (.userProfile(_, let previousState), .dismissedUserProfile):
                return previousState
                
            case (_, .startRoomFlow(let roomID, _, _)):
                return .roomFlow(roomID: roomID, previousState: fromState)
            case (.roomFlow(_, let previousState), .stopRoomFlow):
                return previousState
                
            default:
                return nil
            }
        }
        
        stateMachine.addAnyHandler(.any => .any) { [weak self] context in
            guard let self else { return }
            let animated = context.userInfo as? Bool ?? true
            switch (context.fromState, context.event, context.toState) {
            case (.initial, .presentRoomMembersList, .roomMembersList):
                presentRoomMembersList()
                
            case (_, .presentRoomMemberDetails, .roomMemberDetails(let userID, _)):
                presentRoomMemberDetails(userID: userID, animated: animated)
            case (.roomMemberDetails, .dismissedRoomMemberDetails, .roomMembersList):
                break
                
            case (.roomMembersList, .presentInviteUsersScreen, .inviteUsersScreen):
                presentInviteUsersScreen()
            case (.inviteUsersScreen, .dismissedInviteUsersScreen, .roomMembersList):
                break
                
            case (.roomMemberDetails, .presentUserProfile, .userProfile(let userID, _)):
                replaceRoomMemberDetailsWithUserProfile(userID: userID)
            case (.userProfile, .dismissedUserProfile, _):
                break
                
            case (_, .startRoomFlow(let roomID, let via, let eventID), .roomFlow):
                startRoomFlow(roomID: roomID, via: via, eventID: eventID, animated: animated)
            case (.roomFlow, .stopRoomFlow, _):
                roomFlowCoordinator = nil
                
            default:
                fatalError("Unhandled transition")
            }
        }
    }
    
    private func presentRoomMembersList() {
        let coordinator = RoomMembersListScreenCoordinator(parameters: .init(userSession: flowParameters.userSession,
                                                                             roomProxy: roomProxy,
                                                                             userIndicatorController: flowParameters.userIndicatorController,
                                                                             analytics: flowParameters.analytics))
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .invite:
                stateMachine.tryEvent(.presentInviteUsersScreen)
            case .selectedMember(let member):
                stateMachine.tryEvent(.presentRoomMemberDetails(userID: member.userID))
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator) { [weak self] in
            self?.actionsSubject.send(.finished)
        }
    }
    
    private func presentRoomMemberDetails(userID: String, animated: Bool) {
        let params = RoomMemberDetailsScreenCoordinatorParameters(userID: userID,
                                                                  roomProxy: roomProxy,
                                                                  userSession: flowParameters.userSession,
                                                                  userIndicatorController: flowParameters.userIndicatorController,
                                                                  analytics: flowParameters.analytics)
        let coordinator = RoomMemberDetailsScreenCoordinator(parameters: params)
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .openUserProfile:
                stateMachine.tryEvent(.presentUserProfile(userID: userID))
            case .openDirectChat(let roomID):
                stateMachine.tryEvent(.startRoomFlow(roomID: roomID, via: [], eventID: nil))
            case .startCall(let roomProxy):
                actionsSubject.send(.presentCallScreen(roomProxy: roomProxy))
            case .verifyUser(let userID):
                actionsSubject.send(.verifyUser(userID: userID))
            }
        }
        .store(in: &cancellables)

        navigationStackCoordinator.push(coordinator, animated: animated) { [weak self] in
            guard let self else { return }
            if case let .roomMemberDetails(_, previousState) = stateMachine.state,
               previousState == .initial {
                actionsSubject.send(.finished)
            } else {
                stateMachine.tryEvent(.dismissedRoomMemberDetails)
            }
        }
    }
    
    private func presentInviteUsersScreen() {
        let stackCoordinator = NavigationStackCoordinator()
        let inviteParameters = InviteUsersScreenCoordinatorParameters(userSession: flowParameters.userSession,
                                                                      roomProxy: roomProxy,
                                                                      isCreatingRoom: false,
                                                                      userDiscoveryService: UserDiscoveryService(clientProxy: flowParameters.userSession.clientProxy),
                                                                      userIndicatorController: flowParameters.userIndicatorController,
                                                                      appSettings: flowParameters.appSettings)
        
        let coordinator = InviteUsersScreenCoordinator(parameters: inviteParameters)
        stackCoordinator.setRootCoordinator(coordinator)
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .dismiss:
                navigationStackCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissedInviteUsersScreen)
        }
    }
    
    private func replaceRoomMemberDetailsWithUserProfile(userID: String) {
        let parameters = UserProfileScreenCoordinatorParameters(userID: userID,
                                                                isPresentedModally: false,
                                                                userSession: flowParameters.userSession,
                                                                userIndicatorController: flowParameters.userIndicatorController,
                                                                analytics: flowParameters.analytics)
        let coordinator = UserProfileScreenCoordinator(parameters: parameters)
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .openDirectChat(let roomID):
                stateMachine.tryEvent(.startRoomFlow(roomID: roomID, via: [], eventID: nil))
            case .startCall(let roomProxy):
                actionsSubject.send(.presentCallScreen(roomProxy: roomProxy))
            case .dismiss:
                break // Not supported when pushed.
            }
        }
        .store(in: &cancellables)
        
        // Replace the RoomMemberDetailsScreen without any animation.
        // If this pop and push happens before the previous navigation is completed it might break screen presentation logic
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            self.navigationStackCoordinator.pop(animated: false)
            self.navigationStackCoordinator.push(coordinator, animated: false) { [weak self] in
                self?.stateMachine.tryEvent(.dismissedUserProfile)
            }
        }
    }
    
    private func startRoomFlow(roomID: String, via: [String], eventID: String?, animated: Bool) {
        let coordinator = RoomFlowCoordinator(roomID: roomID,
                                              isChildFlow: true,
                                              navigationStackCoordinator: navigationStackCoordinator,
                                              flowParameters: flowParameters)
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .presentCallScreen(let roomProxy):
                    actionsSubject.send(.presentCallScreen(roomProxy: roomProxy))
                case .verifyUser(let userID):
                    actionsSubject.send(.verifyUser(userID: userID))
                case .continueWithSpaceFlow:
                    fatalError("Will never trigger because only direct chats can be displayed in this flow")
                case .finished:
                    stateMachine.tryEvent(.stopRoomFlow)
                }
            }
            .store(in: &cancellables)
        
        roomFlowCoordinator = coordinator
        if let eventID {
            coordinator.handleAppRoute(.event(eventID: eventID, roomID: roomID, via: via), animated: animated)
        } else {
            coordinator.handleAppRoute(.room(roomID: roomID, via: via), animated: animated)
        }
    }
}
