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

enum StartChatFlowCoordinatorAction {
    case finished(Result)
    case showRoomDirectory
    
    enum Result {
        case room(id: String)
        case space(spaceRoomListProxy: SpaceRoomListProxyProtocol)
        case cancelled
    }
}

/// A value that represents where the flow will be started.
enum StartChatFlowCoordinatorEntryPoint {
    case startChat
    case createSpace
    case createRoomInSpace(SpaceServiceRoom)
}

class StartChatFlowCoordinator: FlowCoordinatorProtocol {
    struct CreatedRoomResult {
        let roomProxy: JoinedRoomProxyProtocol
        let spaceRoomListProxy: SpaceRoomListProxyProtocol?
    }
    
    private let entryPoint: StartChatFlowCoordinatorEntryPoint
    private let userDiscoveryService: UserDiscoveryServiceProtocol
    private let navigationStackCoordinator: NavigationStackCoordinator
    
    private let flowParameters: CommonFlowParameters
    
    private var createRoomScreenCoordinator: CreateRoomScreenCoordinator?
    
    indirect enum State: StateType {
        /// The state machine hasn't started.
        case initial
        
        /// Shown when the flow is started with options to create a room/DM, join by alias, use the room directory etc.
        case startChat
        /// The user is creating a new room.
        case createRoom
        /// The user is selecting an avatar for the new room.
        case roomAvatarPicker
        /// The user is inviting users to a newly created room.
        case inviteUsers
    }
    
    enum Event: EventType {
        /// The flow is being started.
        case start
        /// The user would like to create a room.
        case createRoom(isSpace: Bool)
        /// The user dismissed the create room screen.
        case dismissedCreateRoom
        
        /// The user would like to pick an avatar for the room.
        case presentRoomAvatarPicker
        /// The user finished picking the avatar.
        case dismissedRoomAvatarPicker
        
        /// The user's room was created successfully.
        case createdRoom
    }
    
    private let stateMachine: StateMachine<State, Event>
    private var cancellables: Set<AnyCancellable> = []
    
    private let actionsSubject: PassthroughSubject<StartChatFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<StartChatFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(entryPoint: StartChatFlowCoordinatorEntryPoint,
         userDiscoveryService: UserDiscoveryServiceProtocol,
         navigationStackCoordinator: NavigationStackCoordinator,
         flowParameters: CommonFlowParameters) {
        self.entryPoint = entryPoint
        self.userDiscoveryService = userDiscoveryService
        self.navigationStackCoordinator = navigationStackCoordinator
        
        self.flowParameters = flowParameters
        
        stateMachine = .init(state: .initial)
        configureStateMachine()
    }
    
    func start(animated: Bool) {
        switch entryPoint {
        case .startChat:
            stateMachine.tryEvent(.start)
        case .createSpace:
            stateMachine.tryEvent(.createRoom(isSpace: true))
        case .createRoomInSpace(let space):
            stateMachine.tryEvent(.createRoom(isSpace: false), userInfo: space)
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
        case .startChat:
            navigationStackCoordinator.setRootCoordinator(nil, animated: animated) // StartChatScreen
        case .createRoom:
            navigationStackCoordinator.pop(animated: animated) // CreateRoomScreen
            navigationStackCoordinator.setRootCoordinator(nil, animated: animated) // StartChatScreen
        case .roomAvatarPicker:
            navigationStackCoordinator.setSheetCoordinator(nil, animated: animated) // Media Picker
            clearRoute(animated: animated) // Re-run with the state machine back in the .createRoom state.
        case .inviteUsers:
            navigationStackCoordinator.pop(animated: animated) // InviteUsersScreen
            navigationStackCoordinator.pop(animated: animated) // CreateRoomScreen
            navigationStackCoordinator.setRootCoordinator(nil, animated: animated) // StartChatScreen
        }
    }
    
    // MARK: - Private
    
    private func configureStateMachine() {
        stateMachine.addRoutes(event: .start, transitions: [.initial => .startChat]) { [weak self] _ in
            self?.presentStartChatScreen()
        }
        stateMachine.addRoutes(event: .createRoom(isSpace: true), transitions: [.initial => .createRoom]) { [weak self] _ in
            self?.presentCreateRoomScreen(isSpace: true, spaceSelectionMode: .none, isRoot: true)
        }
        stateMachine.addRoutes(event: .createRoom(isSpace: false), transitions: [.initial => .createRoom]) { [weak self] context in
            guard context.fromState == .initial else { return } // Required check because the event is used in another route.
            guard let space = context.userInfo as? SpaceServiceRoom else {
                fatalError("This transition only supports creating a room in a pre-selected space.")
            }
            self?.presentCreateRoomScreen(isSpace: false, spaceSelectionMode: .editableSpacesList(preSelectedSpace: space), isRoot: true)
        }
        
        stateMachine.addRoutes(event: .createRoom(isSpace: false), transitions: [.startChat => .createRoom]) { [weak self] context in
            guard let self, context.fromState == .startChat else { return } // Required check because the event is used in another route.
            presentCreateRoomScreen(isSpace: false,
                                    spaceSelectionMode: flowParameters.appSettings.createSpaceEnabled ? .editableSpacesList(preSelectedSpace: nil) : .none,
                                    isRoot: false)
        }
        stateMachine.addRoutes(event: .dismissedCreateRoom, transitions: [.createRoom => .startChat]) { [weak self] _ in
            self?.createRoomScreenCoordinator = nil
        }
        
        stateMachine.addRoutes(event: .presentRoomAvatarPicker, transitions: [.createRoom => .roomAvatarPicker]) { [weak self] context in
            guard let mode = context.userInfo as? MediaPickerScreenMode else {
                fatalError("A picker mode is required for the room avatar.")
            }
            self?.presentRoomAvatarPicker(mode)
        }
        stateMachine.addRoutes(event: .dismissedRoomAvatarPicker, transitions: [.roomAvatarPicker => .createRoom])
        
        stateMachine.addRoutes(event: .createdRoom, transitions: [.createRoom => .inviteUsers]) { [weak self] context in
            guard let result = context.userInfo as? CreatedRoomResult else {
                fatalError("A room proxy is required to invite users.")
            }
            self?.presentInviteUsersScreen(roomProxy: result.roomProxy, spaceRoomListProxy: result.spaceRoomListProxy)
        }
        
        stateMachine.addErrorHandler { context in
            if context.fromState == context.toState {
                MXLog.error("Transition between equal states: \(context.fromState)")
            } else {
                fatalError("Unexpected transition: \(context)")
            }
        }
    }
    
    private func presentStartChatScreen() {
        let parameters = StartChatScreenCoordinatorParameters(userSession: flowParameters.userSession,
                                                              userDiscoveryService: userDiscoveryService,
                                                              userIndicatorController: flowParameters.userIndicatorController,
                                                              appSettings: flowParameters.appSettings,
                                                              analytics: flowParameters.analytics)
        
        let coordinator = StartChatScreenCoordinator(parameters: parameters)
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .close:
                actionsSubject.send(.finished(.cancelled))
            case .createRoom:
                stateMachine.tryEvent(.createRoom(isSpace: false))
            case .openRoom(let roomID):
                actionsSubject.send(.finished(.room(id: roomID)))
            case .openRoomDirectorySearch:
                actionsSubject.send(.showRoomDirectory)
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.setRootCoordinator(coordinator)
    }
    
    private func presentCreateRoomScreen(isSpace: Bool,
                                         spaceSelectionMode: CreateRoomScreenSpaceSelectionMode,
                                         isRoot: Bool) {
        let createParameters = CreateRoomScreenCoordinatorParameters(isSpace: isSpace,
                                                                     spaceSelectionMode: spaceSelectionMode,
                                                                     shouldShowCancelButton: isRoot,
                                                                     userSession: flowParameters.userSession,
                                                                     userIndicatorController: flowParameters.userIndicatorController,
                                                                     appSettings: flowParameters.appSettings,
                                                                     analytics: flowParameters.analytics)
        let coordinator = CreateRoomScreenCoordinator(parameters: createParameters)
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .createdRoom(let roomProxy, let spaceRoomListProxy):
                stateMachine.tryEvent(.createdRoom, userInfo: CreatedRoomResult(roomProxy: roomProxy, spaceRoomListProxy: spaceRoomListProxy))
            case .displayMediaPickerWithMode(let mode):
                stateMachine.tryEvent(.presentRoomAvatarPicker, userInfo: mode)
            case .dismiss:
                // Only used when isRoot
                actionsSubject.send(.finished(.cancelled))
            }
        }
        .store(in: &cancellables)
        
        createRoomScreenCoordinator = coordinator
        
        if isRoot {
            navigationStackCoordinator.setRootCoordinator(coordinator)
        } else {
            navigationStackCoordinator.push(coordinator) { [weak self] in
                self?.stateMachine.tryEvent(.dismissedCreateRoom)
            }
        }
    }
    
    private func presentRoomAvatarPicker(_ mode: MediaPickerScreenMode) {
        let stackCoordinator = NavigationStackCoordinator()
        
        let mediaPickerCoordinator = MediaPickerScreenCoordinator(mode: mode,
                                                                  userIndicatorController: flowParameters.userIndicatorController,
                                                                  orientationManager: flowParameters.windowManager) { [weak self] action in
            guard let self else { return }
            switch action {
            case .cancel:
                navigationStackCoordinator.setSheetCoordinator(nil)
            case .selectedMediaAtURLs(let urls):
                guard urls.count == 1 else { fatalError("Received an invalid number of URLs") }
                
                navigationStackCoordinator.setSheetCoordinator(nil)
                createRoomScreenCoordinator?.updateAvatar(fileURL: urls[0])
            }
        }
        
        stackCoordinator.setRootCoordinator(mediaPickerCoordinator)
        
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissedRoomAvatarPicker)
        }
    }
    
    private func presentInviteUsersScreen(roomProxy: JoinedRoomProxyProtocol, spaceRoomListProxy: SpaceRoomListProxyProtocol?) {
        let inviteParameters = InviteUsersScreenCoordinatorParameters(userSession: flowParameters.userSession,
                                                                      roomProxy: roomProxy,
                                                                      isSkippable: true,
                                                                      userDiscoveryService: userDiscoveryService,
                                                                      userIndicatorController: flowParameters.userIndicatorController,
                                                                      appSettings: flowParameters.appSettings)
        let coordinator = InviteUsersScreenCoordinator(parameters: inviteParameters)
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .dismiss:
                if let spaceRoomListProxy {
                    actionsSubject.send(.finished(.space(spaceRoomListProxy: spaceRoomListProxy)))
                } else {
                    actionsSubject.send(.finished(.room(id: roomProxy.id)))
                }
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator)
    }
}
