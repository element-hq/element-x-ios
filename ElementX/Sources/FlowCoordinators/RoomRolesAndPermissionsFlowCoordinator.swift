//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import SwiftState

enum RoomRolesAndPermissionsFlowCoordinatorAction: Equatable {
    /// The flow is complete.
    case complete
}

struct RoomRolesAndPermissionsFlowCoordinatorParameters {
    let roomProxy: JoinedRoomProxyProtocol
    let mediaProvider: MediaProviderProtocol
    let navigationStackCoordinator: NavigationStackCoordinator
    let userIndicatorController: UserIndicatorControllerProtocol
    let analytics: AnalyticsService
}

class RoomRolesAndPermissionsFlowCoordinator: FlowCoordinatorProtocol {
    private let roomProxy: JoinedRoomProxyProtocol
    private let navigationStackCoordinator: NavigationStackCoordinator
    private let mediaProvider: MediaProviderProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let analytics: AnalyticsService
    
    enum State: StateType {
        /// The state machine hasn't started.
        case initial
        /// The root screen for this flow.
        case rolesAndPermissionsScreen
        /// Changing member roles.
        case changingRoles
        /// Changing room permissions.
        case changingPermissions
        /// The flow is complete and the stack has been cleaned up.
        case complete
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
        /// The user finished changing room permissions.
        case finishedChangingPermissions
        /// The user has demoted themself.
        case demotedOwnUser
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
        mediaProvider = parameters.mediaProvider
        userIndicatorController = parameters.userIndicatorController
        analytics = parameters.analytics
        
        stateMachine = .init(state: .initial)
        configureStateMachine()
    }
    
    func start(animated: Bool) {
        stateMachine.tryEvent(.start)
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        // There aren't any routes to this screen, so always clear the stack.
        clearRoute(animated: animated)
    }
    
    func clearRoute(animated: Bool) {
        // As we push screens on top of an existing stack, popping to root wouldn't be safe.
        switch stateMachine.state {
        case .initial, .complete:
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
            let mode: RoomRole = switch role {
            case .administrators:
                .administrator
            case .moderators:
                .moderator
            }
            self?.presentChangeRolesScreen(mode: mode)
        }
        stateMachine.addRoutes(event: .finishedChangingRoles, transitions: [.changingRoles => .rolesAndPermissionsScreen])
        
        stateMachine.addRoutes(event: .changePermissions, transitions: [.rolesAndPermissionsScreen => .changingPermissions]) { [weak self] context in
            guard let (ownPowerLevel, permissions) = context.userInfo as? (RoomPowerLevel, RoomPermissions) else {
                fatalError("Expected a group and the current permissions")
            }
            self?.presentChangePermissionsScreen(ownPowerLevel: ownPowerLevel, permissions: permissions)
        }
        stateMachine.addRoutes(event: .finishedChangingPermissions, transitions: [.changingPermissions => .rolesAndPermissionsScreen])
        
        stateMachine.addRoutes(event: .demotedOwnUser, transitions: [.rolesAndPermissionsScreen => .complete]) { [weak self] _ in
            self?.navigationStackCoordinator.pop()
        }
        
        stateMachine.addErrorHandler { context in
            fatalError("Unexpected transition: \(context)")
        }
    }
    
    private func presentRolesAndPermissionsScreen() {
        let parameters = RoomRolesAndPermissionsScreenCoordinatorParameters(roomProxy: roomProxy,
                                                                            userIndicatorController: userIndicatorController,
                                                                            analytics: analytics)
        let coordinator = RoomRolesAndPermissionsScreenCoordinator(parameters: parameters)
        coordinator.actionsPublisher.sink { [stateMachine] action in
            switch action {
            case .editRoles(let role):
                stateMachine.tryEvent(.changeRoles, userInfo: role)
            case .editPermissions(let ownPowerLevel, let permissions):
                stateMachine.tryEvent(.changePermissions, userInfo: (ownPowerLevel, permissions))
            case .demotedOwnUser:
                stateMachine.tryEvent(.demotedOwnUser)
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator) { [weak self] in
            self?.actionsSubject.send(.complete)
        }
    }
    
    private func presentChangeRolesScreen(mode: RoomRole) {
        let parameters = RoomChangeRolesScreenCoordinatorParameters(mode: mode,
                                                                    roomProxy: roomProxy,
                                                                    mediaProvider: mediaProvider,
                                                                    userIndicatorController: userIndicatorController,
                                                                    analytics: analytics)
        let coordinator = RoomChangeRolesScreenCoordinator(parameters: parameters)
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .complete:
                // When discarding changes is finalised, either use an event or remove this action.
                navigationStackCoordinator.pop()
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator) { [stateMachine] in
            stateMachine.tryEvent(.finishedChangingRoles)
        }
    }
    
    private func presentChangePermissionsScreen(ownPowerLevel: RoomPowerLevel, permissions: RoomPermissions) {
        let parameters = RoomChangePermissionsScreenCoordinatorParameters(ownPowerLevel: ownPowerLevel,
                                                                          permissions: permissions,
                                                                          roomProxy: roomProxy,
                                                                          userIndicatorController: userIndicatorController,
                                                                          analytics: analytics)
        let coordinator = RoomChangePermissionsScreenCoordinator(parameters: parameters)
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .complete:
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
