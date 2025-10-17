//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftState
import SwiftUI

enum RoomMembersFlowCoordinatorAction {
    case dismissFlow
    case presentCallScreen(roomProxy: JoinedRoomProxyProtocol)
    case verifyUser(userID: String)
    case openDirectChat(roomID: String)
}

enum RoomMembersFlowCoordinatorEntryPoint: Equatable {
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
    }
    
    enum Event: EventType {
        case start
        
        case presentRoomMembersList

        case presentRoomMemberDetails(userID: String)
        case dismissRoomMemberDetails
        
        case presentInviteUsersScreen
        case dismissInviteUsersScreen
        
        case presentUserProfile(userID: String)
        case dismissUserProfile
    }
    
    private let entryPoint: RoomMembersFlowCoordinatorEntryPoint
    private let isModallyPresented: Bool
    private let roomProxy: JoinedRoomProxyProtocol
    private let navigationStackCoordinator: NavigationStackCoordinator
    private let flowParameters: CommonFlowParameters
    
    private let stateMachine: StateMachine<State, Event>
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<RoomMembersFlowCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<RoomMembersFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(entryPoint: RoomMembersFlowCoordinatorEntryPoint,
         isModallyPresented: Bool,
         roomProxy: JoinedRoomProxyProtocol,
         navigationStackCoordinator: NavigationStackCoordinator,
         flowParameters: CommonFlowParameters) {
        self.entryPoint = entryPoint
        self.isModallyPresented = isModallyPresented
        self.roomProxy = roomProxy
        self.flowParameters = flowParameters
        self.navigationStackCoordinator = navigationStackCoordinator
        
        stateMachine = .init(state: .initial)
        configureStateMachine()
    }
    
    func start() {
        switch entryPoint {
        case .roomMember(let userID):
            stateMachine.tryEvent(.presentRoomMemberDetails(userID: userID))
        case .roomMembersList:
            stateMachine.tryEvent(.presentRoomMembersList)
        }
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        fatalError("Unavailable")
    }
    
    func clearRoute(animated: Bool) {
        fatalError("Unavailable")
    }
    
    private func configureStateMachine() {
        stateMachine.addRouteMapping { event, fromState, _ in
            switch (fromState, event) {
            case (.initial, .presentRoomMembersList):
                return .roomMembersList
            case (.initial, .presentRoomMemberDetails(let userID)):
                // previous state doesn't matter in this csase
                return .roomMemberDetails(userID: userID, previousState: fromState)
                
            case (.roomMembersList, .presentRoomMemberDetails(let userID)):
                return .roomMemberDetails(userID: userID, previousState: fromState)
            case (.roomMemberDetails, .dismissRoomMemberDetails):
                return .roomMembersList
                
            case (.roomMembersList, .presentInviteUsersScreen):
                return .inviteUsersScreen
            case (.inviteUsersScreen, .dismissInviteUsersScreen):
                return .roomMembersList
                
            case (.roomMemberDetails(_, let previousState), .presentUserProfile(let userID)):
                return .userProfile(userID: userID, previousState: previousState)
            case (.userProfile(_, let previousState), .dismissUserProfile):
                return previousState
                
            default:
                return nil
            }
        }
        
        stateMachine.addAnyHandler(.any => .any) { [weak self] context in
            guard let self else { return }
            switch (context.fromState, context.event, context.toState) {
            case (.initial, .presentRoomMembersList, .roomMembersList):
                presentRoomMembersList()
            case (.initial, .presentRoomMemberDetails, .roomMemberDetails(let userID, _)):
                presentRoomMemberDetails(userID: userID)
                
            case (.roomMembersList, .presentRoomMemberDetails, .roomMemberDetails(let userID, _)):
                presentRoomMemberDetails(userID: userID)
            case (.roomMemberDetails, .dismissRoomMemberDetails, .roomMembersList):
                break
                
            case (.roomMembersList, .presentInviteUsersScreen, .inviteUsersScreen):
                presentInviteUsersScreen()
            case (.inviteUsersScreen, .dismissInviteUsersScreen, .roomMembersList):
                break
                
            case (.roomMemberDetails, .presentUserProfile, .userProfile(let userID, _)):
                replaceRoomMemberDetailsWithUserProfile(userID: userID)
            case (.userProfile, .dismissUserProfile, _):
                break
            default:
                fatalError("Unhandled transition")
            }
        }
    }
    
    private func presentRoomMembersList() {
        let coordinator = RoomMembersListScreenCoordinator(parameters: .init(userSession: flowParameters.userSession,
                                                                             roomProxy: roomProxy,
                                                                             userIndicatorController: flowParameters.userIndicatorController,
                                                                             analytics: flowParameters.analytics,
                                                                             isModallyPresented: true))
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .invite:
                stateMachine.tryEvent(.presentInviteUsersScreen)
            case .selectedMember(let member):
                stateMachine.tryEvent(.presentRoomMemberDetails(userID: member.userID))
            case .dismissModal:
                actionsSubject.send(.dismissFlow)
            }
        }
        .store(in: &cancellables)
        
        if isModallyPresented {
            navigationStackCoordinator.setRootCoordinator(coordinator)
        } else {
            navigationStackCoordinator.push(coordinator)
        }
    }
    
    private func presentRoomMemberDetails(userID: String) {
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
                if isModallyPresented {
                    // We never want a room to start in a modal so we delegate the handling to the presenter coordinator
                    // which should dismiss this flow and then start the room flow.
                    // However I am also realising that if another flow like the SpaceSettings one which is always modal
                    // starts this flow with a push, this flow won't know that is modally presented.
                    // So this logic might need to be revisited.
                    // Maybe we should always delegate to the presenter coordinator the room handling?
                    // And when we reach the Room/Space flow coordinator decide to either do a dismiss
                    // or send back to this coordinator to push the room flow , depending on the flow that is using?
                    actionsSubject.send(.openDirectChat(roomID: roomID))
                } else {
                    // TODO: Implement
                    // This will be required to handle the case where the flow is pushed
                    // if we want to reuse this flow coordinator also in the `RoomFlowCoordinator`
                    // stateMachine.tryEvent(.startRoomFlow(roomID: roomID))
                }
            case .startCall(let roomProxy):
                actionsSubject.send(.presentCallScreen(roomProxy: roomProxy))
            case .verifyUser(let userID):
                actionsSubject.send(.verifyUser(userID: userID))
            }
        }
        .store(in: &cancellables)

        navigationStackCoordinator.push(coordinator) { [weak self] in
            guard let self else { return }
            if entryPoint == .roomMember(userID: userID) {
                actionsSubject.send(.dismissFlow)
            } else {
                stateMachine.tryEvent(.dismissRoomMemberDetails)
            }
        }
    }
    
    private func presentInviteUsersScreen() {
        let selectedUsersSubject: CurrentValueSubject<[UserProfileProxy], Never> = .init([])
        
        let stackCoordinator = NavigationStackCoordinator()
        let inviteParameters = InviteUsersScreenCoordinatorParameters(userSession: flowParameters.userSession,
                                                                      selectedUsers: .init(selectedUsersSubject),
                                                                      roomType: .room(roomProxy: roomProxy),
                                                                      userDiscoveryService: UserDiscoveryService(clientProxy: flowParameters.userSession.clientProxy),
                                                                      userIndicatorController: flowParameters.userIndicatorController)
        
        let coordinator = InviteUsersScreenCoordinator(parameters: inviteParameters)
        stackCoordinator.setRootCoordinator(coordinator)
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .cancel:
                navigationStackCoordinator.setSheetCoordinator(nil)
            case .proceed:
                break
            case .invite(let users):
                inviteUsers(users, in: roomProxy)
            case .toggleUser(let user):
                var selectedUsers = selectedUsersSubject.value
                
                if let index = selectedUsers.firstIndex(where: { $0.userID == user.userID }) {
                    selectedUsers.remove(at: index)
                } else {
                    selectedUsers.append(user)
                }
                
                selectedUsersSubject.send(selectedUsers)
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissInviteUsersScreen)
        }
    }
    
    private func inviteUsers(_ users: [String], in room: JoinedRoomProxyProtocol) {
        if flowParameters.appSettings.enableKeyShareOnInvite {
            showLoadingIndicator(title: L10n.screenRoomDetailsInvitePeoplePreparing,
                                 message: L10n.screenRoomDetailsInvitePeopleDontClose)
        } else {
            showLoadingIndicator()
        }
        
        Task {
            defer {
                navigationStackCoordinator.setSheetCoordinator(nil)
                hideLoadingIndicator()
            }
            
            let result: Result<Void, RoomProxyError> = await withTaskGroup(of: Result<Void, RoomProxyError>.self) { group in
                for user in users {
                    group.addTask {
                        await room.invite(userID: user)
                    }
                }
                
                return await group.first { inviteResult in
                    inviteResult.isFailure
                } ?? .success(())
            }
            
            guard case .failure = result else {
                return
            }
            
            flowParameters.userIndicatorController.alertInfo = .init(id: .init(),
                                                                     title: L10n.commonUnableToInviteTitle,
                                                                     message: L10n.commonUnableToInviteMessage)
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
                if isModallyPresented {
                    // We never want a room to start in a modal flow so we delegate the handling to the
                    // presenter coordinator which should dismiss this flow and then start the room flow
                    actionsSubject.send(.openDirectChat(roomID: roomID))
                } else {
                    // TODO: Implement
                    // This will be required to handle the case where the flow is pushed
                    // if we want to reuse this flow coordinator also in the `RoomFlowCoordinator`
                    // stateMachine.tryEvent(.startRoomFlow(roomID: roomID))
                }
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
                self?.stateMachine.tryEvent(.dismissUserProfile)
            }
        }
    }
        
    private static let loadingIndicatorID = "\(RoomMembersFlowCoordinator.self)-Loading"
    
    private func showLoadingIndicator(delay: Duration? = nil,
                                      title: String = L10n.commonLoading,
                                      message: String? = nil) {
        flowParameters.userIndicatorController.submitIndicator(.init(id: Self.loadingIndicatorID,
                                                                     type: .modal(progress: .indeterminate,
                                                                                  interactiveDismissDisabled: false,
                                                                                  allowsInteraction: false),
                                                                     title: title,
                                                                     message: message,
                                                                     persistent: true),
                                                               delay: delay)
    }
    
    private func hideLoadingIndicator() {
        flowParameters.userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorID)
    }
    
    private func showErrorIndicator() {
        flowParameters.userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
    }
}
