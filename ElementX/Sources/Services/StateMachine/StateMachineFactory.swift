//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import SwiftState

protocol StateMachineFactoryProtocol {
    func makeUserSessionFlowStateMachine(state: UserSessionFlowCoordinator.State) -> StateMachine<UserSessionFlowCoordinator.State, UserSessionFlowCoordinator.Event>
    func makeChatsFlowStateMachine() -> ChatsFlowCoordinatorStateMachine
}

struct StateMachineFactory: StateMachineFactoryProtocol {
    func makeUserSessionFlowStateMachine(state: UserSessionFlowCoordinator.State) -> StateMachine<UserSessionFlowCoordinator.State, UserSessionFlowCoordinator.Event> {
        .init(state: state)
    }
    
    func makeChatsFlowStateMachine() -> ChatsFlowCoordinatorStateMachine {
        .init()
    }
}

// MARK: For testing

class PublishedStateMachineFactory: StateMachineFactoryProtocol {
    let baseFactory = StateMachineFactory()
    
    // MARK: UserSessionFlowCoordinator
    
    let userSessionFlowStatePublisher = PassthroughSubject<UserSessionFlowCoordinator.State, Never>()
    
    func makeUserSessionFlowStateMachine(state: UserSessionFlowCoordinator.State) -> StateMachine<UserSessionFlowCoordinator.State, UserSessionFlowCoordinator.Event> {
        let stateMachine = baseFactory.makeUserSessionFlowStateMachine(state: state)
        stateMachine.addAnyHandler(.any => .any) { [weak self] in self?.userSessionFlowStatePublisher.send($0.toState) }
        return stateMachine
    }
    
    // MARK: ChatsFlowCoordinator
    
    let chatsFlowStatePublisher = PassthroughSubject<ChatsFlowCoordinatorStateMachine.State, Never>()
    
    func makeChatsFlowStateMachine() -> ChatsFlowCoordinatorStateMachine {
        let stateMachine = baseFactory.makeChatsFlowStateMachine()
        stateMachine.addTransitionHandler { [weak self] in self?.chatsFlowStatePublisher.send($0.toState) }
        return stateMachine
    }
}
