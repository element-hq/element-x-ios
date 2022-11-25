//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import SwiftState

class AppCoordinatorStateMachine {
    /// States the AppCoordinator can find itself in
    enum State: StateType {
        /// The initial state, used before the AppCoordinator starts
        case initial
        /// Showing the login screen
        case signedOut
        /// Opening an existing session.
        case restoringSession
        
        /// User session started
        case signedIn

        /// Processing a sign out request
        case signingOut

        /// Processing a remote sign out
        case remoteSigningOut(isSoft: Bool)

        /// Application has been suspended
        case suspended
    }

    /// Events that can be triggered on the AppCoordinator state machine
    enum Event: EventType {
        /// Start the `AppCoordinator` by showing authentication.
        case startWithAuthentication
        /// Signing in succeeded
        case succeededSigningIn
        
        /// Start the `AppCoordinator` by restoring an existing account.
        case startWithExistingSession
        /// Restoring session succeeded.
        case succeededRestoringSession
        /// Restoring session failed.
        case failedRestoringSession
        
        /// Request sign out
        case signOut
        /// Remote sign out.
        case remoteSignOut(isSoft: Bool)
        /// Signing out completed
        case completedSigningOut

        /// Application is about to be suspended
        case suspend
        /// Application goes into active state
        case becomeActive
    }
    
    private let stateMachine: StateMachine<State, Event>
    private var stateBeforeSuspension: State?
    
    init() {
        stateMachine = StateMachine(state: .initial)
        configure()
    }

    private func configure() {
        stateMachine.addRoutes(event: .startWithAuthentication, transitions: [.initial => .signedOut])
        stateMachine.addRoutes(event: .succeededSigningIn, transitions: [.signedOut => .signedIn])

        stateMachine.addRoutes(event: .startWithExistingSession, transitions: [.initial => .restoringSession])
        stateMachine.addRoutes(event: .succeededRestoringSession, transitions: [.restoringSession => .signedIn])
        stateMachine.addRoutes(event: .failedRestoringSession, transitions: [.restoringSession => .signedOut])

        stateMachine.addRoutes(event: .signOut, transitions: [.any => .signingOut])
        stateMachine.addRoutes(event: .completedSigningOut, transitions: [.signingOut => .signedOut])

        // Transitions with associated values need to be handled through `addRouteMapping`
        stateMachine.addRouteMapping { event, fromState, _ in
            switch (event, fromState) {
            case (.remoteSignOut(let isSoft), _):
                return .remoteSigningOut(isSoft: isSoft)
            case (.completedSigningOut, .remoteSigningOut):
                return .signedOut
            case (.suspend, _):
                self.stateBeforeSuspension = fromState
                return .suspended
            case (.becomeActive, _):
                // Cannot become active if not previously suspended
                // Happens when the app is backgrounded before the session is setup
                guard let previousState = self.stateBeforeSuspension else {
                    return self.stateMachine.state
                }

                return previousState
            default:
                return nil
            }
        }

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
