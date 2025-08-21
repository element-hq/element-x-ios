//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import SwiftState

enum SpaceFlowCoordinatorAction: Equatable {
    case finished
}

class SpaceFlowCoordinator: FlowCoordinatorProtocol {
    private let spaceRoomListProxy: SpaceRoomListProxyProtocol
    private let spaceServiceProxy: SpaceServiceProxyProtocol
    private let isChildFlow: Bool
    
    private let mediaProvider: MediaProviderProtocol
    
    private let navigationStackCoordinator: NavigationStackCoordinator
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var childSpaceFlowCoordinator: SpaceFlowCoordinator?
    
    indirect enum State: StateType {
        /// The state machine hasn't started.
        case initial
        /// The root screen for this flow.
        case space
        /// A child flow is in progress.
        case presentingChild(childSpaceID: String, previousState: State)
    }
    
    enum Event: EventType {
        /// The flow is being started.
        case start
        
        case startChildFlow
        case tearDownChildFlow
    }
    
    private let stateMachine: StateMachine<State, Event>
    private var cancellables: Set<AnyCancellable> = []
    
    private let actionsSubject: PassthroughSubject<SpaceFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SpaceFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(spaceRoomListProxy: SpaceRoomListProxyProtocol,
         spaceServiceProxy: SpaceServiceProxyProtocol,
         isChildFlow: Bool,
         mediaProvider: MediaProviderProtocol,
         navigationStackCoordinator: NavigationStackCoordinator,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.spaceRoomListProxy = spaceRoomListProxy
        self.spaceServiceProxy = spaceServiceProxy
        self.isChildFlow = isChildFlow
        
        self.mediaProvider = mediaProvider
        
        self.navigationStackCoordinator = navigationStackCoordinator
        self.userIndicatorController = userIndicatorController
        
        stateMachine = .init(state: .initial)
        configureStateMachine()
    }
    
    func start() {
        stateMachine.tryEvent(.start)
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        // There aren't any routes to this screen yet, so clear the stacks.
        clearRoute(animated: animated)
    }
    
    func clearRoute(animated: Bool) {
        switch stateMachine.state {
        case .initial:
            break
        case .space:
            if isChildFlow {
                navigationStackCoordinator.pop(animated: animated)
            } else {
                navigationStackCoordinator.setRootCoordinator(nil, animated: animated)
            }
        case .presentingChild:
            childSpaceFlowCoordinator?.clearRoute(animated: animated)
            clearRoute(animated: animated) // Re-run with the state machine back in the .space state.
        }
    }
    
    // MARK: - Private
    
    private func configureStateMachine() {
        stateMachine.addRoutes(event: .start, transitions: [.initial => .space]) { [weak self] _ in
            self?.presentSpace()
        }
        
        stateMachine.addRouteMapping { event, fromState, userInfo in
            guard event == .startChildFlow, case .space = fromState else { return nil }
            guard let spaceRoomListProxy = userInfo as? SpaceRoomListProxyProtocol else { fatalError("A space proxy must be provided.") }
            return .presentingChild(childSpaceID: spaceRoomListProxy.spaceRoom.id, previousState: fromState)
        } handler: { [weak self] context in
            guard let self, let spaceRoomListProxy = context.userInfo as? SpaceRoomListProxyProtocol else { return }
            startChildFlow(for: spaceRoomListProxy)
        }
        
        stateMachine.addRouteMapping { event, fromState, _ in
            guard event == .tearDownChildFlow, case .presentingChild(_, let previousState) = fromState else { return nil }
            return previousState
        } handler: { [weak self] _ in
            guard let self else { return }
            childSpaceFlowCoordinator = nil
        }
        
        stateMachine.addErrorHandler { context in
            fatalError("Unexpected transition: \(context)")
        }
    }
    
    private func presentSpace() {
        let parameters = SpaceScreenCoordinatorParameters(spaceRoomListProxy: spaceRoomListProxy,
                                                          spaceServiceProxy: spaceServiceProxy,
                                                          mediaProvider: mediaProvider,
                                                          userIndicatorController: userIndicatorController)
        let coordinator = SpaceScreenCoordinator(parameters: parameters)
        coordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .selectSpace(let spaceRoomListProxy):
                    stateMachine.tryEvent(.startChildFlow, userInfo: spaceRoomListProxy)
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
    
    // MARK: - Other flows
    
    private func startChildFlow(for spaceRoomListProxy: SpaceRoomListProxyProtocol) {
        let coordinator = SpaceFlowCoordinator(spaceRoomListProxy: spaceRoomListProxy,
                                               spaceServiceProxy: spaceServiceProxy,
                                               isChildFlow: true,
                                               mediaProvider: mediaProvider,
                                               navigationStackCoordinator: navigationStackCoordinator,
                                               userIndicatorController: userIndicatorController)
        
        coordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .finished:
                    stateMachine.tryEvent(.tearDownChildFlow)
                }
            }
            .store(in: &cancellables)
        
        childSpaceFlowCoordinator = coordinator
        coordinator.start()
    }
}
