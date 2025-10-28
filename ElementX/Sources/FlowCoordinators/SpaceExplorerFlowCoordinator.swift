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

enum SpaceExplorerFlowCoordinatorAction {
    case showSettings
    case presentCallScreen(roomProxy: JoinedRoomProxyProtocol)
    case verifyUser(userID: String)
}

class SpaceExplorerFlowCoordinator: FlowCoordinatorProtocol {
    private let userSession: UserSessionProtocol
    
    private var flowParameters: CommonFlowParameters
    private let navigationSplitCoordinator: NavigationSplitCoordinator
    private let sidebarNavigationStackCoordinator: NavigationStackCoordinator
    private let detailNavigationStackCoordinator: NavigationStackCoordinator
    
    private var spaceFlowCoordinator: SpaceFlowCoordinator?
    
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
    
    init(navigationSplitCoordinator: NavigationSplitCoordinator, flowParameters: CommonFlowParameters) {
        userSession = flowParameters.userSession
        self.navigationSplitCoordinator = navigationSplitCoordinator
        self.flowParameters = flowParameters
        
        sidebarNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        detailNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        
        navigationSplitCoordinator.setSidebarCoordinator(sidebarNavigationStackCoordinator)
        
        stateMachine = .init(state: .initial)
        configureStateMachine()
    }
    
    func start(animated: Bool) {
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
            return .spaceList(selectedSpaceID: spaceRoomListProxy.id)
        } handler: { [weak self] context in
            guard let self, let spaceRoomListProxy = context.userInfo as? SpaceRoomListProxyProtocol else { return }
            startSpaceFlow(spaceRoomListProxy: spaceRoomListProxy)
        }
        
        stateMachine.addRouteMapping { event, fromState, _ in
            guard event == .deselectSpace, case .spaceList(.some) = fromState else { return nil }
            return .spaceList(selectedSpaceID: nil)
        } handler: { [weak self] _ in
            guard let self else { return }
            navigationSplitCoordinator.setDetailCoordinator(nil) // If we forget to do this, the tab bar remains hidden.
            selectedSpaceSubject.send(nil)
            spaceFlowCoordinator = nil
        }
        
        stateMachine.addErrorHandler { context in
            fatalError("Unexpected transition: \(context)")
        }
    }
    
    private func presentSpaceList() {
        let parameters = SpaceListScreenCoordinatorParameters(userSession: userSession,
                                                              selectedSpacePublisher: selectedSpaceSubject.asCurrentValuePublisher(),
                                                              appSettings: flowParameters.appSettings,
                                                              userIndicatorController: flowParameters.userIndicatorController)
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
    
    private func startSpaceFlow(spaceRoomListProxy: SpaceRoomListProxyProtocol) {
        let coordinator = SpaceFlowCoordinator(entryPoint: .space(spaceRoomListProxy),
                                               spaceServiceProxy: userSession.clientProxy.spaceService,
                                               isChildFlow: false,
                                               navigationStackCoordinator: detailNavigationStackCoordinator,
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
                    stateMachine.tryEvent(.deselectSpace)
                }
            }
            .store(in: &cancellables)
        
        spaceFlowCoordinator = coordinator
        
        if navigationSplitCoordinator.detailCoordinator !== detailNavigationStackCoordinator {
            navigationSplitCoordinator.setDetailCoordinator(detailNavigationStackCoordinator)
        }
        
        coordinator.start()
        selectedSpaceSubject.send(spaceRoomListProxy.id)
    }
}
