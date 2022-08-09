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
        /// Showing the home screen
        case homeScreen
        
        /// Showing a particular room's timeline
        /// - Parameter roomId: that room's identifier
        case roomScreen(roomId: String)
        
        /// Showing the session verification flows
        case sessionVerificationScreen
    
        /// Showing the settings screen
        case settingsScreen
        
        /// Processing a sign out request
        case signingOut
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
        case attemptSignOut
        /// Signing out succeeded
        case succeededSigningOut
        /// Signing out failed
        case failedSigningOut
        
        /// Request presentation for a particular room
        /// - Parameter roomId:the room identifier
        case showRoomScreen(roomId: String)
        /// The room screen has been dismissed
        case dismissedRoomScreen
        
        /// Request the start of the session verification flow
        case showSessionVerificationScreen
        /// Session verification has finished
        case dismissedSessionVerificationScreen
        
        /// Request settings screen presentation
        case showSettingsScreen
        /// The settings screen has been dismissed
        case dismissedSettingsScreen
    }
    
    private let stateMachine: StateMachine<State, Event>
    
    init() {
        stateMachine = StateMachine(state: .initial) { machine in
            machine.addRoutes(event: .startWithAuthentication, transitions: [.initial => .signedOut])
            machine.addRoutes(event: .succeededSigningIn, transitions: [.signedOut => .homeScreen])
            
            machine.addRoutes(event: .startWithExistingSession, transitions: [.initial => .restoringSession])
            machine.addRoutes(event: .succeededRestoringSession, transitions: [.restoringSession => .homeScreen])
            machine.addRoutes(event: .failedRestoringSession, transitions: [.restoringSession => .signedOut])
            
            machine.addRoutes(event: .attemptSignOut, transitions: [.settingsScreen => .signingOut])
            
            machine.addRoutes(event: .succeededSigningOut, transitions: [.signingOut => .signedOut])
            machine.addRoutes(event: .failedSigningOut, transitions: [.signingOut => .settingsScreen])

            machine.addRoutes(event: .showSettingsScreen, transitions: [.homeScreen => .settingsScreen])
            machine.addRoutes(event: .dismissedSettingsScreen, transitions: [.settingsScreen => .homeScreen])
            
            machine.addRoutes(event: .showSessionVerificationScreen, transitions: [.homeScreen => .sessionVerificationScreen])
            machine.addRoutes(event: .dismissedSessionVerificationScreen, transitions: [.sessionVerificationScreen => .homeScreen])
            
            // Transitions with associated values need to be handled through `addRouteMapping`
            machine.addRouteMapping { event, fromState, _ in
                switch (event, fromState) {
                case (.showRoomScreen(let roomId), .homeScreen):
                    return .roomScreen(roomId: roomId)
                case (.dismissedRoomScreen, .roomScreen):
                    return .homeScreen
                default:
                    return nil
                }
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
