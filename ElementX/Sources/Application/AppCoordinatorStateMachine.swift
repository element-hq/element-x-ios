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
        /// Showing the authentication flow
        case signedOut
        /// Showing the soft logout flow
        case softLogout
        /// Opening an existing session.
        case restoringSession
        
        /// Showing the mandatory app lock setup flow before restoring the session.
        /// This state should only be allowed before restoring an existing session. For
        /// new users the setup is inserted in the middle of the authentication flow.
        case mandatoryAppLockSetup
        
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

        /// Start the `AppCoordinator` by showing the mandatory PIN creation flow.
        /// This event should only be sent if an account exists and a mandatory PIN is
        /// missing. Normally it will be handled as part of the authentication flow.
        case startWithAppLockSetup
        
        /// Restoring session failed.
        case failedRestoringSession
        
        /// A session has been created.
        case createdUserSession
        
        /// The app lock setup has been completed.
        case appLockSetupComplete
        
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
        
        stateMachine.addRoutes(event: .startWithAppLockSetup, transitions: [.initial => .mandatoryAppLockSetup])
        stateMachine.addRoutes(event: .appLockSetupComplete, transitions: [.mandatoryAppLockSetup => .restoringSession])
        
        stateMachine.addRoutes(event: .completedSigningOut, transitions: [.signingOut(isSoft: false, disableAppLock: false) => .signedOut,
                                                                          .signingOut(isSoft: false, disableAppLock: true) => .signedOut])
        stateMachine.addRoutes(event: .showSoftLogout, transitions: [.signingOut(isSoft: true, disableAppLock: false) => .softLogout])
        
        stateMachine.addRoutes(event: .clearCache, transitions: [.signedIn => .initial])

        // Transitions with associated values need to be handled through `addRouteMapping`
        stateMachine.addRouteMapping { event, fromState, _ in
            switch (event, fromState) {
            case (.signOut(let isSoft, let disableAppLock), _):
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
