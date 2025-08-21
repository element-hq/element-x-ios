//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import SwiftState

enum SpaceExplorerFlowCoordinatorAction: Equatable {
    case showSettings
}

class SpaceExplorerFlowCoordinator: FlowCoordinatorProtocol {
    private let spaceServiceProxy: SpaceServiceProxyProtocol
    private let userSession: UserSessionProtocol
    
    private let navigationSplitCoordinator: NavigationSplitCoordinator
    private let sidebarNavigationStackCoordinator: NavigationStackCoordinator
    private let detailNavigationStackCoordinator: NavigationStackCoordinator
    
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    enum State: StateType {
        /// The state machine hasn't started.
        case initial
        /// The root screen for this flow.
        case spaceList(selectedSpaceID: String?)
    }
    
    enum Event: EventType {
        /// The flow is being started.
        case start
        /// Request presentation for a particular space.
        ///
        /// The space's `SpaceRoomListProxyProtocol` must be provided in the `userInfo`.
        case selectSpace
        /// The space screen has been dismissed.
        case deselectSpace
    }
    
    private let stateMachine: StateMachine<State, Event>
    private var cancellables: Set<AnyCancellable> = []
    
    private let selectedSpaceSubject = CurrentValueSubject<String?, Never>(nil)
    
    private let actionsSubject: PassthroughSubject<SpaceExplorerFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SpaceExplorerFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userSession: UserSessionProtocol,
         navigationSplitCoordinator: NavigationSplitCoordinator,
         userIndicatorController: UserIndicatorControllerProtocol) {
        spaceServiceProxy = SpaceServiceProxyMock(.init()) // Temporarily using the mock until the SDK is updated.
        self.userSession = userSession
        self.navigationSplitCoordinator = navigationSplitCoordinator
        self.userIndicatorController = userIndicatorController
        
        sidebarNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        detailNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        
        navigationSplitCoordinator.setSidebarCoordinator(sidebarNavigationStackCoordinator)
        
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
        case .initial, .spaceList:
            break
        }
    }
    
    // MARK: - Private
    
    private func configureStateMachine() {
        stateMachine.addRoutes(event: .start, transitions: [.initial => .spaceList(selectedSpaceID: nil)]) { [weak self] _ in
            self?.presentSpaceList()
        }
        
        stateMachine.addRouteMapping { event, fromState, userInfo in
            guard event == .selectSpace, case .spaceList = fromState else { return nil }
            guard let spaceRoomListProxy = userInfo as? SpaceRoomListProxyProtocol else { fatalError("A space proxy must be provided.") }
            return .spaceList(selectedSpaceID: spaceRoomListProxy.spaceRoom.id)
        } handler: { [weak self] context in
            guard let self, let spaceRoomListProxy = context.userInfo as? SpaceRoomListProxyProtocol else { return }
            startSpaceFlow(spaceRoomListProxy: spaceRoomListProxy)
        }
        
        stateMachine.addRouteMapping { event, fromState, _ in
            guard event == .deselectSpace, case .spaceList(.some) = fromState else { return nil }
            return .spaceList(selectedSpaceID: nil)
        } handler: { [weak self] _ in
            guard let self else { return }
            selectedSpaceSubject.send(nil)
            spaceFlowCoordinator = nil
        }
        
        stateMachine.addErrorHandler { context in
            fatalError("Unexpected transition: \(context)")
        }
    }
    
    private func presentSpaceList() {
        let parameters = SpaceListScreenCoordinatorParameters(userSession: userSession,
                                                              spaceServiceProxy: spaceServiceProxy,
                                                              selectedSpaceSubject: selectedSpaceSubject.asCurrentValuePublisher(),
                                                              userIndicatorController: userIndicatorController)
        let coordinator = SpaceListScreenCoordinator(parameters: parameters)
        coordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .selectSpace(let spaceRoomListProxy):
                    stateMachine.tryEvent(.selectSpace, userInfo: spaceRoomListProxy)
                case .showSettings:
                    actionsSubject.send(.showSettings)
                }
            }
            .store(in: &cancellables)
        
        sidebarNavigationStackCoordinator.setRootCoordinator(coordinator)
    }
    
    private var spaceFlowCoordinator: SpaceFlowCoordinator?
    private func startSpaceFlow(spaceRoomListProxy: SpaceRoomListProxyProtocol) {
        let coordinator = SpaceFlowCoordinator(spaceRoomListProxy: spaceRoomListProxy,
                                               spaceServiceProxy: spaceServiceProxy,
                                               isChildFlow: false,
                                               mediaProvider: userSession.mediaProvider,
                                               navigationStackCoordinator: detailNavigationStackCoordinator,
                                               userIndicatorController: userIndicatorController)
        
        coordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .finished:
                    stateMachine.tryEvent(.deselectSpace)
                }
            }
            .store(in: &cancellables)
        
        spaceFlowCoordinator = coordinator
        
        if navigationSplitCoordinator.detailCoordinator !== detailNavigationStackCoordinator {
            navigationSplitCoordinator.setDetailCoordinator(detailNavigationStackCoordinator)
        }
        
        coordinator.start()
        selectedSpaceSubject.send(spaceRoomListProxy.spaceRoom.id)
    }
}
