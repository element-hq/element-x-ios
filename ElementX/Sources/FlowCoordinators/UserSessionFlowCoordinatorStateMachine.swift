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
                
        /// Showing the home screen. The `selectedRoomID` represents the timeline shown on the detail panel (if any)
        case roomList(selectedRoomID: String?)
                
        /// Showing the session verification flows
        case feedbackScreen(selectedRoomID: String?)
        
        /// Showing the settings screen
        case settingsScreen(selectedRoomID: String?)
        
        /// Showing the start chat screen
        case startChatScreen(selectedRoomID: String?)
        
        /// Showing invites list screen
        case invitesScreen(selectedRoomID: String?)
        
        // Showing the logout flows
        case logoutConfirmationScreen(selectedRoomID: String?)
        
        // Showing Room Directory Search screen
        case roomDirectorySearchScreen(selectedRoomID: String?)
    }
    
    struct EventUserInfo {
        let animated: Bool
    }

    /// Events that can be triggered on the AppCoordinator state machine
    enum Event: EventType {
        /// Start the user session flows.
        case start
        
        /// Request presentation for a particular room
        /// - Parameter roomID:the room identifier
        case selectRoom(roomID: String, showingRoomDetails: Bool)
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
        
        /// Request the start of the start chat flow
        case showStartChatScreen
        /// Start chat has been dismissed
        case dismissedStartChatScreen
        
        /// Request presentation of the invites screen
        case showInvitesScreen
        /// The invites screen has been dismissed
        case dismissedInvitesScreen
        
        /// Logout has been requested and this is the last sesion
        case showLogoutConfirmationScreen
        /// Logout has been cancelled
        case dismissedLogoutConfirmationScreen
        
        case showRoomDirectorySearchScreen
        case dismissedRoomDirectorySearchScreen(joinedRoomID: String?)
    }
    
    private let stateMachine: StateMachine<State, Event>
    
    var state: UserSessionFlowCoordinatorStateMachine.State {
        stateMachine.state
    }
    
    init() {
        stateMachine = StateMachine(state: .initial)
        configure()
    }

    private func configure() {
        stateMachine.addRoutes(event: .start, transitions: [.initial => .roomList(selectedRoomID: nil)])

        stateMachine.addRouteMapping { event, fromState, _ in
            switch (fromState, event) {
            case (.roomList, .selectRoom(let roomID, _)):
                return .roomList(selectedRoomID: roomID)
            case (.invitesScreen, .selectRoom(let roomID, _)):
                return .invitesScreen(selectedRoomID: roomID)
            case (.roomList, .deselectRoom):
                return .roomList(selectedRoomID: nil)
            case (.invitesScreen, .deselectRoom):
                return .invitesScreen(selectedRoomID: nil)

            case (.roomList(let selectedRoomID), .showSettingsScreen):
                return .settingsScreen(selectedRoomID: selectedRoomID)
            case (.settingsScreen(let selectedRoomID), .dismissedSettingsScreen):
                return .roomList(selectedRoomID: selectedRoomID)
                
            case (.roomList(let selectedRoomID), .feedbackScreen):
                return .feedbackScreen(selectedRoomID: selectedRoomID)
            case (.feedbackScreen(let selectedRoomID), .dismissedFeedbackScreen):
                return .roomList(selectedRoomID: selectedRoomID)
                
            case (.roomList(let selectedRoomID), .showStartChatScreen):
                return .startChatScreen(selectedRoomID: selectedRoomID)
            case (.startChatScreen(let selectedRoomID), .dismissedStartChatScreen):
                return .roomList(selectedRoomID: selectedRoomID)
            
            case (.roomList(let selectedRoomID), .showInvitesScreen):
                return .invitesScreen(selectedRoomID: selectedRoomID)
            case (.invitesScreen(let selectedRoomID), .showInvitesScreen):
                return .invitesScreen(selectedRoomID: selectedRoomID)

            case (.invitesScreen(let selectedRoomID), .dismissedInvitesScreen):
                return .roomList(selectedRoomID: selectedRoomID)
                
            case (.roomList(let selectedRoomID), .showLogoutConfirmationScreen):
                return .logoutConfirmationScreen(selectedRoomID: selectedRoomID)
            case (.logoutConfirmationScreen(let selectedRoomID), .dismissedLogoutConfirmationScreen):
                return .roomList(selectedRoomID: selectedRoomID)
                
            case (.roomList(let selectedRoomID), .showRoomDirectorySearchScreen):
                return .roomDirectorySearchScreen(selectedRoomID: selectedRoomID)
            case (.roomDirectorySearchScreen(let selectedRoomID), .dismissedRoomDirectorySearchScreen(let joinedRoomID)):
                if let joinedRoomID {
                    return .roomList(selectedRoomID: joinedRoomID)
                }
                return .roomList(selectedRoomID: selectedRoomID)
                
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
        case .invitesScreen(let selectedRoomID):
            return roomID == selectedRoomID
        default:
            return false
        }
    }
}
