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
        
        /// Showing the home screen. The `selectedRoomId` represents the timeline shown on the detail panel (if any)
        case roomList(selectedRoomId: String?)
                
        /// Showing the session verification flows
        case sessionVerificationScreen(selectedRoomId: String?)

        /// Showing the session verification flows
        case feedbackScreen(selectedRoomId: String?)
        
        /// Showing the settings screen
        case settingsScreen(selectedRoomId: String?)
        
        /// Showing the start chat screen
        case startChatScreen(selectedRoomId: String?)
        
        /// Showing invites list screen
        case invitesScreen(selectedRoomId: String?)
    }

    /// Events that can be triggered on the AppCoordinator state machine
    enum Event: EventType {
        /// Start the user session flows
        case start
        
        /// Request presentation for a particular room
        /// - Parameter roomId:the room identifier
        case selectRoom(roomId: String)
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
        
        /// Request presentation of the settings of a specific room
        case selectRoomDetails(roomId: String)
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
        stateMachine.addRoutes(event: .start, transitions: [.initial => .roomList(selectedRoomId: nil)])

        stateMachine.addRouteMapping { event, fromState, _ in
            switch (event, fromState) {
            case (.selectRoom(let roomId), .roomList):
                return .roomList(selectedRoomId: roomId)
            case (.deselectRoom, .roomList):
                return .roomList(selectedRoomId: nil)

            case (.showSettingsScreen, .roomList(let selectedRoomId)):
                return .settingsScreen(selectedRoomId: selectedRoomId)
            case (.dismissedSettingsScreen, .settingsScreen(let selectedRoomId)):
                return .roomList(selectedRoomId: selectedRoomId)
                
            case (.feedbackScreen, .roomList(let selectedRoomId)):
                return .feedbackScreen(selectedRoomId: selectedRoomId)
            case (.dismissedFeedbackScreen, .feedbackScreen(let selectedRoomId)):
                return .roomList(selectedRoomId: selectedRoomId)
                
            case (.showSessionVerificationScreen, .roomList(let selectedRoomId)):
                return .sessionVerificationScreen(selectedRoomId: selectedRoomId)
            case (.dismissedSessionVerificationScreen, .sessionVerificationScreen(let selectedRoomId)):
                return .roomList(selectedRoomId: selectedRoomId)
                
            case (.showStartChatScreen, .roomList(let selectedRoomId)):
                return .startChatScreen(selectedRoomId: selectedRoomId)
            case (.dismissedStartChatScreen, .startChatScreen(let selectedRoomId)):
                return .roomList(selectedRoomId: selectedRoomId)
            
            case (.showInvitesScreen, .roomList(let selectedRoomId)):
                return .invitesScreen(selectedRoomId: selectedRoomId)
            case (.closedInvitesScreen, .invitesScreen(let selectedRoomId)):
                return .roomList(selectedRoomId: selectedRoomId)
            case (.selectRoom(let roomId), .invitesScreen):
                return .invitesScreen(selectedRoomId: roomId)
            case (.deselectRoom, .invitesScreen):
                return .invitesScreen(selectedRoomId: nil)
                
            case (.selectRoomDetails(let roomId), .roomList):
                return .roomList(selectedRoomId: roomId)

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
    func isDisplayingRoomScreen(withRoomId roomId: String) -> Bool {
        switch stateMachine.state {
        case .roomList(let selectedRoomId):
            return roomId == selectedRoomId
        default:
            return false
        }
    }
}

struct EventUserInfo {
    let animated: Bool
}
