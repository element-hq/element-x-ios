//
// Copyright 2025 Element Creations Ltd.
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
    func makeChatsTabFlowStateMachine() -> ChatsTabFlowCoordinatorStateMachine
    func makeMembersFlowStateMachine(state: RoomMembersFlowCoordinator.State) -> StateMachine<RoomMembersFlowCoordinator.State, RoomMembersFlowCoordinator.Event>
}

struct StateMachineFactory: StateMachineFactoryProtocol {
    func makeUserSessionFlowStateMachine(state: UserSessionFlowCoordinator.State) -> StateMachine<UserSessionFlowCoordinator.State, UserSessionFlowCoordinator.Event> {
        .init(state: state)
    }
    
    func makeChatsTabFlowStateMachine() -> ChatsTabFlowCoordinatorStateMachine {
        .init()
    }
    
    func makeMembersFlowStateMachine(state: RoomMembersFlowCoordinator.State) -> StateMachine<RoomMembersFlowCoordinator.State, RoomMembersFlowCoordinator.Event> {
        .init(state: state)
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
    
    // MARK: ChatsTabFlowCoordinator
    
    let chatsTabFlowStatePublisher = PassthroughSubject<ChatsTabFlowCoordinatorStateMachine.State, Never>()
    
    func makeChatsTabFlowStateMachine() -> ChatsTabFlowCoordinatorStateMachine {
        let stateMachine = baseFactory.makeChatsTabFlowStateMachine()
        stateMachine.addTransitionHandler { [weak self] in self?.chatsTabFlowStatePublisher.send($0.toState) }
        return stateMachine
    }
    
    // MARK: MembersFlowCoordinator
    
    let membersFlowStatePublisher = PassthroughSubject<RoomMembersFlowCoordinator.State, Never>()
    
    func makeMembersFlowStateMachine(state: RoomMembersFlowCoordinator.State) -> StateMachine<RoomMembersFlowCoordinator.State, RoomMembersFlowCoordinator.Event> {
        let stateMachine = baseFactory.makeMembersFlowStateMachine(state: state)
        stateMachine.addAnyHandler(.any => .any) { [weak self] in self?.membersFlowStatePublisher.send($0.toState) }
        return stateMachine
    }
}
