//
// Copyright 2024 New Vector Ltd
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
import Foundation
import SwiftState

enum RoomRolesAndPermissionsFlowCoordinatorAction: Equatable {
    /// The flow is complete.
    case complete
}

struct RoomRolesAndPermissionsFlowCoordinatorParameters {
    let roomProxy: RoomProxyProtocol
    let navigationStackCoordinator: NavigationStackCoordinator
    let userIndicatorController: UserIndicatorControllerProtocol
}

class RoomRolesAndPermissionsFlowCoordinator: FlowCoordinatorProtocol {
    private let roomProxy: RoomProxyProtocol
    private let navigationStackCoordinator: NavigationStackCoordinator
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    enum State: StateType {
        /// The state machine hasn't started.
        case initial
        /// The root screen for this flow.
        case rolesAndPermissionsScreen
        /// Changing member roles.
        case changingRoles
        /// Changing room permissions.
        case changingPermissions
    }
    
    enum Event: EventType {
        /// The flow is being started.
        case start
        /// The user would like to change member roles.
        case changeRoles
        /// The user finished changing member roles.
        case finishedChangingRoles
        /// The user would like to change room permissions.
        case changePermissions
        /// The user finished changing room permissions
        case finishedChangingPermissions
    }
    
    private let stateMachine: StateMachine<State, Event>
    private var cancellables: Set<AnyCancellable> = []
    
    private let actionsSubject: PassthroughSubject<RoomRolesAndPermissionsFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<RoomRolesAndPermissionsFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: RoomRolesAndPermissionsFlowCoordinatorParameters) {
        roomProxy = parameters.roomProxy
        navigationStackCoordinator = parameters.navigationStackCoordinator
        userIndicatorController = parameters.userIndicatorController
        
        stateMachine = .init(state: .initial)
        configureStateMachine()
    }
    
    func start() {
        stateMachine.tryEvent(.start)
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        // There aren't any routes to this screen, so always clear the stack.
        clearRoute(animated: animated)
    }
    
    func clearRoute(animated: Bool) {
        // As we push screens on top of an existing stack, popping to root wouldn't be safe.
        switch stateMachine.state {
        case .initial:
            break
        case .rolesAndPermissionsScreen:
            navigationStackCoordinator.pop(animated: animated)
        case .changingRoles, .changingPermissions:
            navigationStackCoordinator.pop(animated: animated) // ChangeRoles or ChangePermissions screen.
            navigationStackCoordinator.pop(animated: animated) // RolesAndPermissions screen.
        }
    }
    
    // MARK: - Private
    
    private func configureStateMachine() {
        stateMachine.addRoutes(event: .start, transitions: [.initial => .rolesAndPermissionsScreen]) { [weak self] _ in
            self?.presentRolesAndPermissionsScreen()
        }
        
        stateMachine.addRoutes(event: .changeRoles, transitions: [.rolesAndPermissionsScreen => .changingRoles]) { [weak self] context in
            guard let role = context.userInfo as? RoomRolesAndPermissionsScreenRole else { fatalError("Expected a role") }
            self?.presentChangeRolesScreen(role: role)
        }
        stateMachine.addRoutes(event: .finishedChangingRoles, transitions: [.changingRoles => .rolesAndPermissionsScreen])
        
        stateMachine.addRoutes(event: .changePermissions, transitions: [.rolesAndPermissionsScreen => .changingPermissions]) { [weak self] context in
            guard let (group, permissions) = context.userInfo as? (RoomRolesAndPermissionsScreenPermissionsGroup, RoomPermissions) else {
                fatalError("Expected a group and the current permissions")
            }
            self?.presentChangePermissionsScreen(permissions: permissions, group: group)
        }
        stateMachine.addRoutes(event: .finishedChangingPermissions, transitions: [.changingPermissions => .rolesAndPermissionsScreen])
        
        stateMachine.addErrorHandler { context in
            fatalError("Unexpected transition: \(context)")
        }
    }
    
    private func presentRolesAndPermissionsScreen() {
        let parameters = RoomRolesAndPermissionsScreenCoordinatorParameters(roomProxy: roomProxy)
        let coordinator = RoomRolesAndPermissionsScreenCoordinator(parameters: parameters)
        coordinator.actions.sink { [stateMachine] action in
            switch action {
            case .editRoles(let role):
                stateMachine.tryEvent(.changeRoles, userInfo: role)
            case .editPermissions(let group):
                stateMachine.tryEvent(.changePermissions, userInfo: (group, RoomPermissions.default))
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator) { [weak self] in
            self?.actionsSubject.send(.complete)
        }
    }
    
    private func presentChangeRolesScreen(role: RoomRolesAndPermissionsScreenRole) {
        let mode = switch role {
        case .administrators: RoomMemberDetails.Role.administrator
        case .moderators: RoomMemberDetails.Role.moderator
        }
        
        let parameters = RoomChangeRolesScreenCoordinatorParameters(mode: mode,
                                                                    roomProxy: roomProxy,
                                                                    userIndicatorController: userIndicatorController)
        let coordinator = RoomChangeRolesScreenCoordinator(parameters: parameters)
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .done:
                // When discarding changes is finalised, either use an event or remove this action.
                navigationStackCoordinator.pop()
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator) { [stateMachine] in
            stateMachine.tryEvent(.finishedChangingRoles)
        }
    }
    
    private func presentChangePermissionsScreen(permissions: RoomPermissions, group: RoomRolesAndPermissionsScreenPermissionsGroup) {
        let parameters = RoomChangePermissionsScreenCoordinatorParameters(permissions: permissions,
                                                                          permissionsGroup: group,
                                                                          roomProxy: roomProxy,
                                                                          userIndicatorController: userIndicatorController)
        let coordinator = RoomChangePermissionsScreenCoordinator(parameters: parameters)
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .cancel:
                // When discarding changes is finalised, either use an event or remove this action.
                navigationStackCoordinator.pop()
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator) { [stateMachine] in
            stateMachine.tryEvent(.finishedChangingPermissions)
        }
    }
}
