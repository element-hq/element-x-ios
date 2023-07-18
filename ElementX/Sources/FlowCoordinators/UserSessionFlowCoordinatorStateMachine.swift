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
        
        /// Showing the migration screen whilst the proxy performs an initial sync.
        case migration

        /// Showing the welcome screen.
        case welcomeScreen
        
        /// Showing the home screen. The `selectedRoomID` represents the timeline shown on the detail panel (if any)
        case roomList(selectedRoomID: String?)
                
        /// Showing the session verification flows
        case sessionVerificationScreen(selectedRoomID: String?)

        /// Showing the session verification flows
        case feedbackScreen(selectedRoomID: String?)
        
        /// Showing the settings screen
        case settingsScreen(selectedRoomID: String?)
        
        /// Showing the start chat screen
        case startChatScreen(selectedRoomID: String?)
        
        /// Showing invites list screen
        case invitesScreen(selectedRoomID: String?)
    }
    
    struct EventUserInfo {
        let animated: Bool
    }

    /// Events that can be triggered on the AppCoordinator state machine
    enum Event: EventType {
        /// Start the user session flows.
        case start
        /// Starts the user session flows with the welcome screen.
        /// **Note:** This is event is only for users who used the app before v1.1.8.
        /// It can be removed once the older TestFlight builds have expired.
        case startWithWelcomeScreen
        /// Start the user session flows with a migration screen.
        case startWithMigration
        
        /// Request to transition from the migration state to the home screen.
        case completeMigration
        
        /// Request presentation of the welcome screen.
        case presentWelcomeScreen
        /// The welcome screen has been dismissed.
        case dismissedWelcomeScreen
        
        /// Request presentation for a particular room
        /// - Parameter roomID:the room identifier
        case selectRoom(roomID: String)
        /// The room screen has been dismissed
        case deselectRoom
        
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
        
        /// Request the start of the start chat flow
        case showStartChatScreen
        /// Start chat has been dismissed
        case dismissedStartChatScreen
        
        /// Request presentation of the invites screen
        case showInvitesScreen
        /// The invites screen has been dismissed
        case closedInvitesScreen
    }
    
    private let stateMachine: StateMachine<State, Event>
    
    var state: UserSessionFlowCoordinatorStateMachine.State {
        stateMachine.state
    }
    
    init() {
        stateMachine = StateMachine(state: .initial)
        configure()
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func configure() {
        stateMachine.addRoutes(event: .start, transitions: [.initial => .roomList(selectedRoomID: nil)])
        stateMachine.addRoutes(event: .startWithMigration, transitions: [.initial => .migration])
        stateMachine.addRoutes(event: .startWithWelcomeScreen, transitions: [.initial => .welcomeScreen])
        stateMachine.addRoutes(event: .completeMigration, transitions: [.migration => .roomList(selectedRoomID: nil)])
        stateMachine.addRoutes(event: .dismissedWelcomeScreen, transitions: [.welcomeScreen => .roomList(selectedRoomID: nil)])

        stateMachine.addRouteMapping { event, fromState, _ in
            switch (event, fromState) {
            case (.selectRoom(let roomID), .roomList):
                return .roomList(selectedRoomID: roomID)
            case (.selectRoom(let roomID), .invitesScreen):
                return .invitesScreen(selectedRoomID: roomID)
            case (.deselectRoom, .roomList):
                return .roomList(selectedRoomID: nil)
            case (.deselectRoom, .invitesScreen):
                return .invitesScreen(selectedRoomID: nil)

            case (.showSettingsScreen, .roomList(let selectedRoomID)):
                return .settingsScreen(selectedRoomID: selectedRoomID)
            case (.dismissedSettingsScreen, .settingsScreen(let selectedRoomID)):
                return .roomList(selectedRoomID: selectedRoomID)
                
            case (.feedbackScreen, .roomList(let selectedRoomID)):
                return .feedbackScreen(selectedRoomID: selectedRoomID)
            case (.dismissedFeedbackScreen, .feedbackScreen(let selectedRoomID)):
                return .roomList(selectedRoomID: selectedRoomID)
                
            case (.showSessionVerificationScreen, .roomList(let selectedRoomID)):
                return .sessionVerificationScreen(selectedRoomID: selectedRoomID)
            case (.dismissedSessionVerificationScreen, .sessionVerificationScreen(let selectedRoomID)):
                return .roomList(selectedRoomID: selectedRoomID)
                
            case (.showStartChatScreen, .roomList(let selectedRoomID)):
                return .startChatScreen(selectedRoomID: selectedRoomID)
            case (.dismissedStartChatScreen, .startChatScreen(let selectedRoomID)):
                return .roomList(selectedRoomID: selectedRoomID)
            
            case (.showInvitesScreen, .roomList(let selectedRoomID)):
                return .invitesScreen(selectedRoomID: selectedRoomID)
            case (.showInvitesScreen, .invitesScreen(let selectedRoomID)):
                return .invitesScreen(selectedRoomID: selectedRoomID)

            case (.closedInvitesScreen, .invitesScreen(let selectedRoomID)):
                return .roomList(selectedRoomID: selectedRoomID)

            case (.presentWelcomeScreen, .roomList):
                return .welcomeScreen
                
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
    func processEvent(_ event: Event, userInfo: EventUserInfo? = nil) {
        stateMachine.tryEvent(event, userInfo: userInfo)
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
    func isDisplayingRoomScreen(withRoomID roomID: String) -> Bool {
        switch stateMachine.state {
        case .roomList(let selectedRoomID):
            return roomID == selectedRoomID
        default:
            return false
        }
    }
}
