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
    private let userSession: UserSessionProtocol
    
    private let navigationSplitCoordinator: NavigationSplitCoordinator
    private let sidebarNavigationStackCoordinator: NavigationStackCoordinator
    private let detailNavigationStackCoordinator: NavigationStackCoordinator
    
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    enum State: StateType {
        /// The state machine hasn't started.
        case initial
        /// The root screen for this flow.
        case spaceList
    }
    
    enum Event: EventType {
        /// The flow is being started.
        case start
    }
    
    private let stateMachine: StateMachine<State, Event>
    private var cancellables: Set<AnyCancellable> = []
    
    private let actionsSubject: PassthroughSubject<SpaceExplorerFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SpaceExplorerFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userSession: UserSessionProtocol,
         navigationSplitCoordinator: NavigationSplitCoordinator,
         userIndicatorController: UserIndicatorControllerProtocol) {
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
        stateMachine.addRoutes(event: .start, transitions: [.initial => .spaceList]) { [weak self] _ in
            self?.presentSpaceList()
        }
        
        stateMachine.addErrorHandler { context in
            fatalError("Unexpected transition: \(context)")
        }
    }
    
    private func presentSpaceList() {
        // Temporarily using the mock until the SDK is updated.
        let parameters = SpaceListScreenCoordinatorParameters(userSession: userSession, spaceServiceProxy: SpaceServiceProxyMock(.init()))
        let coordinator = SpaceListScreenCoordinator(parameters: parameters)
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .showSettings:
                actionsSubject.send(.showSettings)
            case .selectSpace:
                break
            }
        }
        .store(in: &cancellables)
        
        sidebarNavigationStackCoordinator.setRootCoordinator(coordinator)
    }
}
