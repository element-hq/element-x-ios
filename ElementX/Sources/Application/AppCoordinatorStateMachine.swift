//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftState

class AppCoordinatorStateMachine {
    /// States the AppCoordinator can find itself in
    enum State: StateType {
        /// The initial state, used before the AppCoordinator starts
        case initial
        /// Opening the existing accounts at launch.
        case restoringSession
        /// The app is running, with or without any accounts.
        case running
    }
    
    /// Events that can be triggered on the AppCoordinator state machine
    enum Event: EventType {
        /// Start the `AppCoordinator` by showing authentication.
        case startWithAuthentication
        
        /// Start the `AppCoordinator` by restoring an existing account.
        case startWithExistingSession
        
        /// Restoring session failed.
        case failedRestoringSession
        
        /// A session has been restored.
        case restoredSession
    }
    
    private let stateMachine: StateMachine<State, Event>
    
    var state: AppCoordinatorStateMachine.State {
        stateMachine.state
    }
    
    init() {
        stateMachine = StateMachine(state: .initial)
        configure()
    }
    
    private func configure() {
        stateMachine.addRoutes(event: .startWithAuthentication, transitions: [.initial => .running])
        stateMachine.addRoutes(event: .startWithExistingSession, transitions: [.initial => .restoringSession])
        stateMachine.addRoutes(event: .restoredSession, transitions: [.restoringSession => .running])
        stateMachine.addRoutes(event: .failedRestoringSession, transitions: [.restoringSession => .running])
        
        addTransitionHandler { context in
            if let event = context.event {
                MXLog.info("Transitioning from `\(context.fromState)` to `\(context.toState)` with event `\(event)`")
            } else {
                MXLog.info("Transitioning from \(context.fromState)` to `\(context.toState)`")
            }
        }
    }
    
    /// Attempt to move the state machine to another state through an event
    /// It will either invoke the `transitionHandler` or the `errorHandler` depending on its current state
    func processEvent(_ event: Event) {
        stateMachine.tryEvent(event)
    }
    
    /// Registers a callback for processing state machine transitions
    func addTransitionHandler(_ handler: @escaping StateMachine<State, Event>.Handler) {
        stateMachine.addAnyHandler(.any => .any, handler: handler)
    }
    
    /// Registers a callback for processing state machine errors
    func addErrorHandler(_ handler: @escaping StateMachine<State, Event>.Handler) {
        stateMachine.addErrorHandler(handler: handler)
    }
}
