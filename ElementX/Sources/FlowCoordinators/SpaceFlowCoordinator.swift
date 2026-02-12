//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import SwiftState

enum SpaceFlowCoordinatorAction {
    case presentCallScreen(roomProxy: JoinedRoomProxyProtocol)
    case verifyUser(userID: String)
    case finished
}

enum SpaceFlowCoordinatorEntryPoint {
    case space(SpaceRoomListProxyProtocol)
    case joinSpace(SpaceServiceRoom)
    
    var spaceID: String {
        switch self {
        case .space(let spaceRoomListProxy): spaceRoomListProxy.id
        case .joinSpace(let spaceServiceRoom): spaceServiceRoom.id
        }
    }
}

class SpaceFlowCoordinator: FlowCoordinatorProtocol {
    private var entryPoint: SpaceFlowCoordinatorEntryPoint
    private let spaceServiceProxy: SpaceServiceProxyProtocol
    private let isChildFlow: Bool
    
    private let navigationStackCoordinator: NavigationStackCoordinator
    
    private let flowParameters: CommonFlowParameters
    
    private let selectedSpaceRoomSubject: CurrentValueSubject<String?, Never> = .init(nil)
    
    private var spaceScreenCoordinator: SpaceScreenCoordinator?
    private var childSpaceFlowCoordinator: SpaceFlowCoordinator?
    private var roomFlowCoordinator: RoomFlowCoordinator?
    private var membersFlowCoordinator: RoomMembersFlowCoordinator?
    private var settingsFlowCoordinator: SpaceSettingsFlowCoordinator?
    private var rolesAndPermissionsFlowCoordinator: RoomRolesAndPermissionsFlowCoordinator?
    private var createChildRoomFlowCoordinator: StartChatFlowCoordinator?
    
    indirect enum State: StateType {
        /// The state machine hasn't started.
        case initial
        /// Shown when the flow is started for an unjoined space.
        case joinSpace
        /// The root screen for this flow.
        case space
        /// The user is adding rooms to the space.
        case addingRooms
        /// The user is transferring their ownership of the space.
        case transferOwnership
        /// A child (space) flow is in progress.
        case presentingChild(childSpaceID: String, previousState: State)
        /// A room flow is in progress
        case roomFlow(previousState: State)
        /// A members flow is in progress
        case membersFlow
        /// A space settings flow is in progress
        case settingsFlow
        
        case rolesAndPermissionsFlow
        
        case createChildRoomFlow
        
        case leftSpace
    }
    
    enum Event: EventType {
        /// The flow is being started.
        case start
        /// The flow is being started for an unjoined space.
        case startUnjoined
        
        /// The join space screen joined the space.
        case joinedSpace
        /// The space screen left the space.
        case leftSpace
        
        /// Allow the user to add existing rooms to this space.
        case addRooms
        /// The user finished adding rooms to this space.
        case dismissedAddRooms
        
        /// Allow the user to transfer their ownership of the space.
        case presentTransferOwnership
        /// The user finished transferring their ownership of the space.
        case dismissedTransferOwnership
        
        /// Request the presentation of a child space flow.
        ///
        /// The space's `SpaceRoomListProxyProtocol` must be provided in the `userInfo`.
        case startChildFlow
        /// Tidy-up the child flow after it has dismissed itself.
        case stopChildFlow
        
        case startRoomFlow(roomID: String)
        case stopRoomFlow
        
        case startMembersFlow
        case stopMembersFlow
        
        case startSettingsFlow
        case stopSettingsFlow
        
        case startRolesAndPermissionsFlow
        case stopRolesAndPermissionsFlow
        
        case startCreateChildRoomFlow
        case stopCreateChildRoomFlow
    }
    
    private let stateMachine: StateMachine<State, Event>
    private var cancellables: Set<AnyCancellable> = []
    
    private let actionsSubject: PassthroughSubject<SpaceFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SpaceFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(entryPoint: SpaceFlowCoordinatorEntryPoint,
         spaceServiceProxy: SpaceServiceProxyProtocol,
         isChildFlow: Bool,
         navigationStackCoordinator: NavigationStackCoordinator,
         flowParameters: CommonFlowParameters) {
        self.entryPoint = entryPoint
        self.spaceServiceProxy = spaceServiceProxy
        self.isChildFlow = isChildFlow
        self.flowParameters = flowParameters
        
        self.navigationStackCoordinator = navigationStackCoordinator
        
        stateMachine = .init(state: .initial)
        configureStateMachine()
    }
    
    func start(animated: Bool) {
        switch entryPoint {
        case .space:
            stateMachine.tryEvent(.start)
        case .joinSpace:
            stateMachine.tryEvent(.startUnjoined)
        }
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        // There aren't any routes to this screen yet, so clear the stacks.
        clearRoute(animated: animated)
    }
    
    func clearRoute(animated: Bool) {
        switch stateMachine.state {
        case .initial:
            break
        case .joinSpace, .space, .leftSpace:
            if isChildFlow {
                navigationStackCoordinator.pop(animated: animated)
            } else {
                navigationStackCoordinator.setRootCoordinator(nil, animated: animated)
            }
        case .addingRooms:
            navigationStackCoordinator.setSheetCoordinator(nil)
            clearRoute(animated: animated) // Re-run with the state machine back in the .space state.
        case .transferOwnership:
            navigationStackCoordinator.setSheetCoordinator(nil)
            clearRoute(animated: animated) // Re-run with the state machine back in the .space state.
        case .presentingChild:
            childSpaceFlowCoordinator?.clearRoute(animated: animated)
            clearRoute(animated: animated) // Re-run with the state machine back in the .space state.
        case .roomFlow:
            roomFlowCoordinator?.clearRoute(animated: animated)
            clearRoute(animated: animated) // Re-run with the state machine back in the .space state.
        case .membersFlow:
            membersFlowCoordinator?.clearRoute(animated: animated)
            clearRoute(animated: animated) // Re-run with the state machine back in the .space state.
        case .settingsFlow:
            settingsFlowCoordinator?.clearRoute(animated: animated)
            clearRoute(animated: animated) // Re-run with the state machine back in the .space state.
        case .rolesAndPermissionsFlow:
            rolesAndPermissionsFlowCoordinator?.clearRoute(animated: animated)
            clearRoute(animated: animated) // Re-run with the state machine back in the .space state.
        case .createChildRoomFlow:
            navigationStackCoordinator.setSheetCoordinator(nil)
            clearRoute(animated: animated) // Re-run with the state machine back in the .space state.
        }
    }
    
    // MARK: - Private
    
    // swiftlint:disable:next function_body_length
    private func configureStateMachine() {
        stateMachine.addRouteMapping { event, fromState, userInfo in
            switch (fromState, event) {
            case (.initial, .start):
                return .space
            case (.initial, .startUnjoined):
                return .joinSpace
            
            case (.joinSpace, .joinedSpace):
                return .space
            case (.space, .leftSpace):
                return .leftSpace
            
            case (.space, .addRooms):
                return .addingRooms
            case (.addingRooms, .dismissedAddRooms):
                return .space
            
            case (.space, .presentTransferOwnership):
                return .transferOwnership
            case (.transferOwnership, .dismissedTransferOwnership):
                return .space
            
            case (.space, .startChildFlow):
                guard let childEntryPoint = userInfo as? SpaceFlowCoordinatorEntryPoint else { fatalError("An entry point must be provided.") }
                return .presentingChild(childSpaceID: childEntryPoint.spaceID, previousState: fromState)
            case (.roomFlow(let previousState), .startChildFlow):
                guard let childEntryPoint = userInfo as? SpaceFlowCoordinatorEntryPoint else { fatalError("An entry point must be provided.") }
                return .presentingChild(childSpaceID: childEntryPoint.spaceID, previousState: previousState)
            case (.presentingChild(_, let previousState), .stopChildFlow):
                return previousState
            
            case (.space, .startRoomFlow):
                return .roomFlow(previousState: fromState)
            case (.roomFlow, .startRoomFlow):
                return fromState // Ignore tapping on multiple rooms at the same time
            case (.roomFlow(let previousState), .stopRoomFlow):
                return previousState
            
            case (.space, .startMembersFlow):
                return .membersFlow
            case (.membersFlow, .stopMembersFlow):
                return .space
            
            case (.space, .startSettingsFlow):
                return .settingsFlow
            case (.settingsFlow, .stopSettingsFlow):
                return .space
            
            case (.space, .startRolesAndPermissionsFlow):
                return .rolesAndPermissionsFlow
            case (.rolesAndPermissionsFlow, .stopRolesAndPermissionsFlow):
                return .space
            
            case (.space, .startCreateChildRoomFlow):
                return .createChildRoomFlow
            case (.createChildRoomFlow, .stopCreateChildRoomFlow):
                return .space
            
            default:
                return nil
            }
        }
        
        stateMachine.addAnyHandler(.any => .any) { [weak self] context in
            guard let self else { return }
            
            switch (context.fromState, context.event, context.toState) {
            case (.initial, .start, .space):
                presentSpace()
            case (.initial, .startUnjoined, .joinSpace):
                presentJoinSpaceScreen()
            
            case (.joinSpace, .joinedSpace, .space):
                presentSpaceAfterJoining()
            case (.space, .leftSpace, .leftSpace):
                clearRoute(animated: true)
            
            case (.space, .addRooms, .addingRooms):
                presentSpaceAddRoomsScreen()
            case (.addingRooms, .dismissedAddRooms, .space):
                break
            
            case (.space, .presentTransferOwnership, .transferOwnership):
                guard let roomProxy = context.userInfo as? JoinedRoomProxyProtocol else { return }
                presentTransferOwnershipScreen(roomProxy: roomProxy)
            case (.transferOwnership, .dismissedTransferOwnership, .space):
                break
            
            case (.space, .startChildFlow, .presentingChild),
                 (.roomFlow, .startChildFlow, .presentingChild):
                guard let entryPoint = context.userInfo as? SpaceFlowCoordinatorEntryPoint else { return }
                startChildFlow(with: entryPoint)
            case (.presentingChild, .stopChildFlow, _):
                childSpaceFlowCoordinator = nil
                selectedSpaceRoomSubject.send(nil)
            
            case (.space, .startRoomFlow(let roomID), .roomFlow):
                startRoomFlow(roomID: roomID)
            case (.roomFlow, .startRoomFlow, .roomFlow):
                break // Ignore tapping on multiple rooms at the same time
            case (.roomFlow, .stopRoomFlow, _):
                roomFlowCoordinator = nil
                selectedSpaceRoomSubject.send(nil)
            
            case (.space, .startMembersFlow, .membersFlow):
                guard let roomProxy = context.userInfo as? JoinedRoomProxyProtocol else {
                    fatalError("The room proxy must always be provided")
                }
                startMembersFlow(roomProxy: roomProxy)
            case (.membersFlow, .stopMembersFlow, .space):
                membersFlowCoordinator = nil
            
            case (.space, .startSettingsFlow, .settingsFlow):
                guard let roomProxy = context.userInfo as? JoinedRoomProxyProtocol else { return }
                startSettingsFlow(roomProxy: roomProxy)
            case (.settingsFlow, .stopSettingsFlow, .space):
                settingsFlowCoordinator = nil
            
            case (.space, .startRolesAndPermissionsFlow, .rolesAndPermissionsFlow):
                guard let roomProxy = context.userInfo as? JoinedRoomProxyProtocol else { return }
                startRolesAndPermissionsFlow(roomProxy: roomProxy)
            case (.rolesAndPermissionsFlow, .stopRolesAndPermissionsFlow, .space):
                rolesAndPermissionsFlowCoordinator = nil
            
            case (.space, .startCreateChildRoomFlow, .createChildRoomFlow):
                guard let space = context.userInfo as? SpaceServiceRoom else { fatalError("The space is missing") }
                startCreateChildFlow(space: space)
            case (.createChildRoomFlow, .stopCreateChildRoomFlow, .space):
                createChildRoomFlowCoordinator = nil
            
            default:
                break
            }
            
            // Log transitions
            if let event = context.event {
                MXLog.info("Transitioning from `\(context.fromState)` to `\(context.toState)` with event `\(event)`")
            } else {
                MXLog.info("Transitioning from \(context.fromState)` to `\(context.toState)`")
            }
        }
        
        stateMachine.addErrorHandler { context in
            fatalError("Unexpected transition: \(context)")
        }
    }
    
    private func presentSpace() {
        guard case let .space(spaceRoomListProxy) = entryPoint else { fatalError("Attempting to show a space with the wrong entry point.") }
        
        let parameters = SpaceScreenCoordinatorParameters(spaceRoomListProxy: spaceRoomListProxy,
                                                          spaceServiceProxy: spaceServiceProxy,
                                                          selectedSpaceRoomPublisher: selectedSpaceRoomSubject.asCurrentValuePublisher(),
                                                          userSession: flowParameters.userSession,
                                                          appSettings: flowParameters.appSettings,
                                                          userIndicatorController: flowParameters.userIndicatorController)
        let coordinator = SpaceScreenCoordinator(parameters: parameters)
        spaceScreenCoordinator = coordinator
        coordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .selectSpace(let spaceRoomListProxy):
                    stateMachine.tryEvent(.startChildFlow, userInfo: SpaceFlowCoordinatorEntryPoint.space(spaceRoomListProxy))
                case .selectUnjoinedSpace(let spaceServiceRoom):
                    stateMachine.tryEvent(.startChildFlow, userInfo: SpaceFlowCoordinatorEntryPoint.joinSpace(spaceServiceRoom))
                case .selectRoom(let roomID):
                    stateMachine.tryEvent(.startRoomFlow(roomID: roomID))
                case .leftSpace:
                    stateMachine.tryEvent(.leftSpace)
                case .displayMembers(let roomProxy):
                    stateMachine.tryEvent(.startMembersFlow, userInfo: roomProxy)
                case .displaySpaceSettings(let roomProxy):
                    stateMachine.tryEvent(.startSettingsFlow, userInfo: roomProxy)
                case .displayRolesAndPermissions(let roomProxy):
                    stateMachine.tryEvent(.startRolesAndPermissionsFlow, userInfo: roomProxy)
                case .addExistingChildren:
                    stateMachine.tryEvent(.addRooms)
                case .displayCreateChildRoomFlow(let space):
                    stateMachine.tryEvent(.startCreateChildRoomFlow, userInfo: space)
                case .displayTransferOwnership(let roomProxy):
                    stateMachine.tryEvent(.presentTransferOwnership, userInfo: roomProxy)
                }
            }
            .store(in: &cancellables)
        
        if isChildFlow {
            navigationStackCoordinator.push(coordinator) { [weak self] in
                self?.actionsSubject.send(.finished)
            }
        } else {
            navigationStackCoordinator.setRootCoordinator(coordinator) { [weak self] in
                self?.actionsSubject.send(.finished)
            }
        }
    }
    
    private func presentJoinSpaceScreen() {
        guard case let .joinSpace(spaceServiceRoom) = entryPoint else { fatalError("Attempting to join a space with the wrong entry point.") }
        
        let parameters = JoinRoomScreenCoordinatorParameters(source: .space(spaceServiceRoom),
                                                             userSession: flowParameters.userSession,
                                                             userIndicatorController: flowParameters.userIndicatorController,
                                                             appSettings: flowParameters.appSettings)
        let coordinator = JoinRoomScreenCoordinator(parameters: parameters)
        coordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .joined(.space(let spaceRoomListProxy)):
                    entryPoint = .space(spaceRoomListProxy)
                    stateMachine.tryEvent(.joinedSpace)
                case .joined(.roomID):
                    MXLog.error("Expected to join a space, but got a room ID instead.")
                    clearRoute(animated: true)
                case .cancelled:
                    clearRoute(animated: true)
                case .presentDeclineAndBlock:
                    MXLog.error("Joining a space from the spaces tab shouldn't involve an inviter.")
                    clearRoute(animated: true)
                }
            }
            .store(in: &cancellables)
        
        if isChildFlow {
            navigationStackCoordinator.push(coordinator) { [weak self] in
                guard let self, stateMachine.state == .joinSpace else { return }
                actionsSubject.send(.finished)
            }
        } else {
            navigationStackCoordinator.setRootCoordinator(coordinator) { [weak self] in
                guard let self, stateMachine.state == .joinSpace else { return }
                actionsSubject.send(.finished)
            }
        }
    }
    
    private func presentSpaceAfterJoining() {
        if isChildFlow {
            navigationStackCoordinator.pop()
        } else {
            navigationStackCoordinator.setRootCoordinator(nil)
        }
        
        presentSpace()
    }
    
    private func presentSpaceAddRoomsScreen() {
        guard case let .space(spaceRoomListProxy) = entryPoint else { fatalError("Attempting to show a space with the wrong entry point.") }
        
        let stackCoordinator = NavigationStackCoordinator()
        let parameters = SpaceAddRoomsScreenCoordinatorParameters(spaceRoomListProxy: spaceRoomListProxy,
                                                                  userSession: flowParameters.userSession,
                                                                  roomSummaryProvider: flowParameters.userSession.clientProxy.alternateRoomSummaryProvider,
                                                                  userIndicatorController: flowParameters.userIndicatorController)
        let coordinator = SpaceAddRoomsScreenCoordinator(parameters: parameters)
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .dismiss:
                    navigationStackCoordinator.setSheetCoordinator(nil)
                }
            }
            .store(in: &cancellables)
        
        stackCoordinator.setRootCoordinator(coordinator)
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissedAddRooms)
        }
    }
    
    private func presentTransferOwnershipScreen(roomProxy: JoinedRoomProxyProtocol) {
        let parameters = RoomChangeRolesScreenCoordinatorParameters(mode: .owner,
                                                                    roomProxy: roomProxy,
                                                                    mediaProvider: flowParameters.userSession.mediaProvider,
                                                                    userIndicatorController: flowParameters.userIndicatorController,
                                                                    analytics: flowParameters.analytics)
        let stackCoordinator = NavigationStackCoordinator()
        let coordinator = RoomChangeRolesScreenCoordinator(parameters: parameters)
        coordinator.actionsPublisher.sink { [weak self] action in
            switch action {
            case .complete:
                self?.navigationStackCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        
        stackCoordinator.setRootCoordinator(coordinator)
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissedTransferOwnership)
        }
    }
    
    // MARK: - Other flows
    
    private func startChildFlow(with entryPoint: SpaceFlowCoordinatorEntryPoint) {
        let coordinator = SpaceFlowCoordinator(entryPoint: entryPoint,
                                               spaceServiceProxy: spaceServiceProxy,
                                               isChildFlow: true,
                                               navigationStackCoordinator: navigationStackCoordinator,
                                               flowParameters: flowParameters)
        
        coordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .presentCallScreen(let roomProxy):
                    actionsSubject.send(.presentCallScreen(roomProxy: roomProxy))
                case .verifyUser(let userID):
                    actionsSubject.send(.verifyUser(userID: userID))
                case .finished:
                    stateMachine.tryEvent(.stopChildFlow)
                }
            }
            .store(in: &cancellables)
        
        childSpaceFlowCoordinator = coordinator
        coordinator.start()
        selectedSpaceRoomSubject.send(entryPoint.spaceID)
    }
    
    private func startRoomFlow(roomID: String) {
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
                case .continueWithSpaceFlow(let spaceRoomListProxy):
                    stateMachine.tryEvent(.startChildFlow, userInfo: SpaceFlowCoordinatorEntryPoint.space(spaceRoomListProxy))
                case .finished:
                    stateMachine.tryEvent(.stopRoomFlow)
                }
            }
            .store(in: &cancellables)
        
        roomFlowCoordinator = coordinator
        coordinator.handleAppRoute(.room(roomID: roomID, via: []), animated: true)
        selectedSpaceRoomSubject.send(roomID)
    }
    
    private func startMembersFlow(roomProxy: JoinedRoomProxyProtocol) {
        let flowCoordinator = RoomMembersFlowCoordinator(entryPoint: .roomMembersList,
                                                         roomProxy: roomProxy,
                                                         navigationStackCoordinator: navigationStackCoordinator,
                                                         flowParameters: flowParameters)
        
        flowCoordinator.actions.sink { [weak self] actions in
            guard let self else { return }
            switch actions {
            case .finished:
                stateMachine.tryEvent(.stopMembersFlow)
            case .presentCallScreen(let roomProxy):
                actionsSubject.send(.presentCallScreen(roomProxy: roomProxy))
            case .verifyUser(let userID):
                actionsSubject.send(.verifyUser(userID: userID))
            }
        }
        .store(in: &cancellables)
        membersFlowCoordinator = flowCoordinator
        flowCoordinator.start()
    }
    
    private func startSettingsFlow(roomProxy: JoinedRoomProxyProtocol) {
        let flowCoordinator = SpaceSettingsFlowCoordinator(roomProxy: roomProxy,
                                                           navigationStackCoordinator: navigationStackCoordinator,
                                                           flowParameters: flowParameters)
        
        flowCoordinator.actions.sink { [weak self] actions in
            guard let self else { return }
            switch actions {
            case .finished(let leftRoom):
                stateMachine.tryEvent(.stopSettingsFlow)
                if leftRoom {
                    stateMachine.tryEvent(.leftSpace)
                }
            case .presentCallScreen(let roomProxy):
                actionsSubject.send(.presentCallScreen(roomProxy: roomProxy))
            case .verifyUser(userID: let userID):
                actionsSubject.send(.verifyUser(userID: userID))
            }
        }
        .store(in: &cancellables)
        
        settingsFlowCoordinator = flowCoordinator
        flowCoordinator.start()
    }
    
    private func startRolesAndPermissionsFlow(roomProxy: JoinedRoomProxyProtocol) {
        let flowCoordinator = RoomRolesAndPermissionsFlowCoordinator(parameters: .init(roomProxy: roomProxy,
                                                                                       mediaProvider: flowParameters.userSession.mediaProvider,
                                                                                       navigationStackCoordinator: navigationStackCoordinator,
                                                                                       userIndicatorController: flowParameters.userIndicatorController,
                                                                                       analytics: flowParameters.analytics))
        flowCoordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .complete:
                stateMachine.tryEvent(.stopRolesAndPermissionsFlow)
            }
        }
        .store(in: &cancellables)
        
        rolesAndPermissionsFlowCoordinator = flowCoordinator
        flowCoordinator.start()
    }
    
    private func startCreateChildFlow(space: SpaceServiceRoom) {
        let stackCoordinator = NavigationStackCoordinator()
        let flowCoordinator = StartChatFlowCoordinator(entryPoint: .createRoomInSpace(space),
                                                       userDiscoveryService: UserDiscoveryService(clientProxy: flowParameters.userSession.clientProxy),
                                                       navigationStackCoordinator: stackCoordinator,
                                                       flowParameters: flowParameters)
        
        var flowCoordinatorResult: StartChatFlowCoordinatorAction.Result?
        flowCoordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .finished(let result):
                flowCoordinatorResult = result
                navigationStackCoordinator.setSheetCoordinator(nil)
            case .showRoomDirectory:
                fatalError("Not implemented yet")
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            guard let self else { return }
            stateMachine.tryEvent(.stopCreateChildRoomFlow)
            switch flowCoordinatorResult {
            case .room(let id):
                stateMachine.tryEvent(.startRoomFlow(roomID: id))
                spaceScreenCoordinator?.resetRoomList()
            case .space(let spaceRoomListProxy):
                stateMachine.tryEvent(.startChildFlow, userInfo: spaceRoomListProxy)
                spaceScreenCoordinator?.resetRoomList()
            case .cancelled, .none:
                break
            }
        }
        
        createChildRoomFlowCoordinator = flowCoordinator
        flowCoordinator.start()
    }
}
