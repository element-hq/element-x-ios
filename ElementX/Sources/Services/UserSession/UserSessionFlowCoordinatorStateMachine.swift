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

class UserSessionFlowCoordinatorStateMachine {
    /// States the AppCoordinator can find itself in
    enum State: StateType {
        /// The initial state, used before the coordinator starts
        case initial
        
        /// Showing the home screen
        case homeScreen
        
        /// Showing a particular room's timeline
        /// - Parameter roomId: that room's identifier
        case roomScreen(roomId: String)
        
        /// Showing the session verification flows
        case sessionVerificationScreen
        
        /// Showing the session verification flows
        case feedbackScreen
        
        /// Showing the settings screen
        case settingsScreen

        /// Application has been suspended
        case suspended
    }

    /// Events that can be triggered on the AppCoordinator state machine
    enum Event: EventType {
        /// Start the user session flows
        case start
        
        /// Request presentation for a particular room
        /// - Parameter roomId:the room identifier
        case showRoomScreen(roomId: String)
        /// The room screen has been dismissed
        case dismissedRoomScreen
        
        /// Request presentation of the settings screen
        case showSettingsScreen
        /// The settings screen has been dismissed
        case dismissedSettingsScreen
        
        /// Request presentation of the feedback screen
        case feedbackScreen
        /// The feedback screen has been dismissed
        case dismissedFeedbackScreen
        
        /// Request the start of the session verification flow
        case showSessionVerificationScreen
        /// Session verification has finished
        case dismissedSessionVerificationScreen

        /// Application goes into inactive state
        case resignActive
        /// Application goes into active state
        case becomeActive
    }
    
    private let stateMachine: StateMachine<State, Event>
    private var stateBeforeSuspension: State?
    
    init() {
        stateMachine = StateMachine(state: .initial)
        configure()
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func configure() {
        stateMachine.addRoutes(event: .start, transitions: [.initial => .homeScreen])

        stateMachine.addRouteMapping { event, fromState, _ in
            switch (event, fromState) {
            case (.showRoomScreen(let roomId), .homeScreen):
                return .roomScreen(roomId: roomId)
            case (.dismissedRoomScreen, .roomScreen):
                return .homeScreen

            case (.showSettingsScreen, .homeScreen):
                return .settingsScreen
            case (.dismissedSettingsScreen, .settingsScreen):
                return .homeScreen
                
            case (.feedbackScreen, .homeScreen):
                return .feedbackScreen
            case (.dismissedFeedbackScreen, .feedbackScreen):
                return .homeScreen
                
            case (.showSessionVerificationScreen, .homeScreen):
                return .sessionVerificationScreen
            case (.dismissedSessionVerificationScreen, .sessionVerificationScreen):
                return .homeScreen
                
            case (.resignActive, _):
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

    /// Flag indicating the machine is displaying room screen with given room identifier
    func isDisplayingRoomScreen(withRoomId roomId: String) -> Bool {
        switch stateMachine.state {
        case .roomScreen(let displayedRoomId):
            return roomId == displayedRoomId
        default:
            return false
        }
    }
}
