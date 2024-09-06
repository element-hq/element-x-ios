//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import SwiftState

class AppCoordinatorStateMachine {
    /// States the AppCoordinator can find itself in
    enum State: StateType {
        /// The initial state, used before the AppCoordinator starts
        case initial
        /// Showing the authentication flow
        case signedOut
        /// Showing the soft logout flow
        case softLogout
        /// Opening an existing session.
        case restoringSession
                
        /// User session started
        case signedIn

        /// Processing a sign out request
        case signingOut(isSoft: Bool, disableAppLock: Bool)
    }

    /// Events that can be triggered on the AppCoordinator state machine
    enum Event: EventType {
        /// Start the `AppCoordinator` by showing authentication.
        case startWithAuthentication
        
        /// Start the `AppCoordinator` by restoring an existing account.
        case startWithExistingSession
        
        /// Restoring session failed.
        case failedRestoringSession
        
        /// A session has been created.
        case createdUserSession
                
        /// Request sign out.
        case signOut(isSoft: Bool, disableAppLock: Bool)
        /// Request the soft logout screen.
        case showSoftLogout
        /// Signing out completed.
        case completedSigningOut
        
        /// Request cache clearing.
        case clearCache
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
        stateMachine.addRoutes(event: .startWithAuthentication, transitions: [.initial => .signedOut])
        stateMachine.addRoutes(event: .createdUserSession, transitions: [.signedOut => .signedIn,
                                                                         .softLogout => .signedIn])
        stateMachine.addRoutes(event: .startWithExistingSession, transitions: [.initial => .restoringSession])
        stateMachine.addRoutes(event: .createdUserSession, transitions: [.restoringSession => .signedIn])
        stateMachine.addRoutes(event: .failedRestoringSession, transitions: [.restoringSession => .signedOut])
                
        stateMachine.addRoutes(event: .completedSigningOut, transitions: [.signingOut(isSoft: false, disableAppLock: false) => .signedOut,
                                                                          .signingOut(isSoft: false, disableAppLock: true) => .signedOut])
        stateMachine.addRoutes(event: .showSoftLogout, transitions: [.signingOut(isSoft: true, disableAppLock: false) => .softLogout])
        
        stateMachine.addRoutes(event: .clearCache, transitions: [.signedIn => .initial])

        // Transitions with associated values need to be handled through `addRouteMapping`
        stateMachine.addRouteMapping { event, fromState, _ in
            switch (fromState, event) {
            case (_, .signOut(let isSoft, let disableAppLock)):
                return .signingOut(isSoft: isSoft, disableAppLock: disableAppLock)
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
