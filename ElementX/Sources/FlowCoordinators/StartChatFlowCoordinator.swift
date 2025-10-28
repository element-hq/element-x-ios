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
    case finished(roomID: String?)
    case showRoomDirectory
}

class StartChatFlowCoordinator: FlowCoordinatorProtocol {
    private let navigationStackCoordinator: NavigationStackCoordinator
    
    private let flowParameters: CommonFlowParameters
    
    indirect enum State: StateType {
        /// The state machine hasn't started.
        case initial
        /// Shown when the flow is started for an unjoined space.
        case startChatScreen
    }
    
    enum Event: EventType {
        /// The flow is being started.
        case start
    }
    
    private let stateMachine: StateMachine<State, Event>
    private var cancellables: Set<AnyCancellable> = []
    
    private let actionsSubject: PassthroughSubject<StartChatFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<StartChatFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(navigationStackCoordinator: NavigationStackCoordinator,
         flowParameters: CommonFlowParameters) {
        self.flowParameters = flowParameters
        
        self.navigationStackCoordinator = navigationStackCoordinator
        
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
        case .initial:
            break
        case .startChatScreen:
            navigationStackCoordinator.pop()
        }
    }
    
    // MARK: - Private
    
    private func configureStateMachine() {
        stateMachine.addRoutes(event: .start, transitions: [.initial => .startChatScreen]) { [weak self] _ in
            self?.presentStartChatScreen()
        }
        
        stateMachine.addErrorHandler { context in
            fatalError("Unexpected transition: \(context)")
        }
    }
    
    private func presentStartChatScreen() {
        let userDiscoveryService = UserDiscoveryService(clientProxy: flowParameters.userSession.clientProxy)
        let parameters = StartChatScreenCoordinatorParameters(orientationManager: flowParameters.windowManager,
                                                              userSession: flowParameters.userSession,
                                                              userIndicatorController: flowParameters.userIndicatorController,
                                                              navigationStackCoordinator: navigationStackCoordinator,
                                                              userDiscoveryService: userDiscoveryService,
                                                              mediaUploadingPreprocessor: MediaUploadingPreprocessor(appSettings: flowParameters.appSettings),
                                                              appSettings: flowParameters.appSettings,
                                                              analytics: flowParameters.analytics)
        
        let coordinator = StartChatScreenCoordinator(parameters: parameters)
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .close:
                actionsSubject.send(.finished(roomID: nil))
            case .openRoom(let roomID):
                actionsSubject.send(.finished(roomID: roomID))
            case .openRoomDirectorySearch:
                actionsSubject.send(.showRoomDirectory)
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.setRootCoordinator(coordinator)
    }
}
