//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import SwiftState

enum SpaceSettingsFlowCoordinatorAction {
    case finished
}

final class SpaceSettingsFlowCoordinator: FlowCoordinatorProtocol {
    indirect enum State: StateType {
        /// The state machine hasn't started.
        case initial
        /// The space settings screen
        case spaceSettings
    }
    
    enum Event: EventType {
        case start
        
        case presentSpaceSettings
    }
    
    private let roomProxy: JoinedRoomProxyProtocol
    private let navigationStackCoordinator: NavigationStackCoordinator
    private let flowParameters: CommonFlowParameters
    
    private let stateMachine: StateMachine<State, Event>
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<SpaceSettingsFlowCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<SpaceSettingsFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
        
    init(roomProxy: JoinedRoomProxyProtocol,
         navigationStackCoordinator: NavigationStackCoordinator,
         flowParameters: CommonFlowParameters) {
        self.roomProxy = roomProxy
        self.flowParameters = flowParameters
        self.navigationStackCoordinator = navigationStackCoordinator
        
        stateMachine = .init(state: .initial)
        configureStateMachine()
    }
    
    func start(animated: Bool) {
        stateMachine.tryEvent(.presentSpaceSettings, userInfo: animated)
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        fatalError("Not implemented yet")
    }
    
    func clearRoute(animated: Bool) {
        // Not implemented yet
    }
    
    private func configureStateMachine() {
        stateMachine.addRouteMapping { event, fromState, _ in
            switch (fromState, event) {
            case (.initial, .presentSpaceSettings):
                return .spaceSettings
                
            default:
                return nil
            }
        }
        
        stateMachine.addAnyHandler(.any => .any) { [weak self] context in
            guard let self else { return }
            let animated = context.userInfo as? Bool ?? true
            switch (context.fromState, context.event, context.toState) {
            case (.initial, .presentSpaceSettings, .spaceSettings):
                presentSpaceSettings(animated: animated)
                
            default:
                fatalError("Unhandled transition")
            }
        }
    }
    
    private func presentSpaceSettings(animated: Bool) {
        let coordinator = SpaceSettingsScreenCoordinator(parameters: .init())
        
        coordinator.actionsPublisher.sink { [weak self] action in
            switch action { }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator, animated: animated) { [weak self] in
            self?.actionsSubject.send(.finished)
        }
    }
}
