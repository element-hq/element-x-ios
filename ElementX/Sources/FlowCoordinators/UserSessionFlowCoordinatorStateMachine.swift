//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import SwiftState

class UserSessionFlowCoordinatorStateMachine {
    /// States the AppCoordinator can find itself in
    enum State: StateType {
        /// The initial state, used before the coordinator starts
        case initial
                
        /// Showing the home screen. The `selectedRoomID` represents the timeline shown on the detail panel (if any)
        case roomList(selectedRoomID: String?)
                
        /// Showing the feedback screen.
        case feedbackScreen(selectedRoomID: String?)
        
        /// Showing the settings screen
        case settingsScreen(selectedRoomID: String?)
        
        /// Showing the recovery key screen.
        case recoveryKeyScreen(selectedRoomID: String?)
        
        /// Showing the encryption reset flow.
        case encryptionResetFlow(selectedRoomID: String?)
        
        /// Showing the start chat screen
        case startChatScreen(selectedRoomID: String?)
        
        /// Showing the logout flows
        case logoutConfirmationScreen(selectedRoomID: String?)
        
        /// Showing Room Directory Search screen
        case roomDirectorySearchScreen(selectedRoomID: String?)
        
        /// Showing the user profile screen. This screen clears the navigation.
        case userProfileScreen
        
        case shareExtensionRoomList(sharePayload: ShareExtensionPayload)
        
        /// The selected room ID from the state if available.
        var selectedRoomID: String? {
            switch self {
            case .initial, .userProfileScreen, .shareExtensionRoomList:
                nil
            case .roomList(let selectedRoomID),
                 .feedbackScreen(let selectedRoomID),
                 .settingsScreen(let selectedRoomID),
                 .recoveryKeyScreen(let selectedRoomID),
                 .encryptionResetFlow(let selectedRoomID),
                 .startChatScreen(let selectedRoomID),
                 .logoutConfirmationScreen(let selectedRoomID),
                 .roomDirectorySearchScreen(let selectedRoomID):
                selectedRoomID
            }
        }
    }
    
    struct EventUserInfo {
        let animated: Bool
    }

    /// Events that can be triggered on the AppCoordinator state machine
    enum Event: EventType {
        /// Start the user session flows.
        case start
        
        /// Request presentation for a particular room.
        /// - Parameter roomID: The room identifier.
        /// - Parameter via: Any servers necessary to discover the room.
        /// - Parameter entryPoint: The starting point for the presented room.
        case selectRoom(roomID: String, via: [String], entryPoint: RoomFlowCoordinatorEntryPoint)
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
        
        /// Request presentation of the recovery key screen.
        case showRecoveryKeyScreen
        /// The recovery key screen has been dismissed.
        case dismissedRecoveryKeyScreen
        
        /// Request presentation of the encryption reset flow.
        case startEncryptionResetFlow
        /// The encryption reset flow is complete and has been dismissed.
        case finishedEncryptionResetFlow
        
        /// Request the start of the start chat flow
        case showStartChatScreen
        /// Start chat has been dismissed
        case dismissedStartChatScreen
                
        /// Logout has been requested and this is the last session
        case showLogoutConfirmationScreen
        /// Logout has been cancelled
        case dismissedLogoutConfirmationScreen
        
        /// Request presentation of the room directory search screen.
        case showRoomDirectorySearchScreen
        /// The room directory search screen has been dismissed.
        case dismissedRoomDirectorySearchScreen
        
        /// Request presentation of the user profile screen.
        case showUserProfileScreen(userID: String)
        /// The user profile screen has been dismissed.
        case dismissedUserProfileScreen
        
        case showShareExtensionRoomList(sharePayload: ShareExtensionPayload)
        case dismissedShareExtensionRoomList
    }
    
    private let stateMachine: StateMachine<State, Event>
    
    var state: UserSessionFlowCoordinatorStateMachine.State {
        stateMachine.state
    }
    
    var stateSubject = PassthroughSubject<State, Never>()
    var statePublisher: AnyPublisher<State, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    init() {
        stateMachine = StateMachine(state: .initial)
        configure()
    }

    private func configure() {
        stateMachine.addRoutes(event: .start, transitions: [.initial => .roomList(selectedRoomID: nil)])

        stateMachine.addRouteMapping { event, fromState, _ in
            switch (fromState, event) {
            case (.roomList, .selectRoom(let roomID, _, _)):
                return .roomList(selectedRoomID: roomID)
            case (.roomList, .deselectRoom):
                return .roomList(selectedRoomID: nil)

            case (.roomList(let selectedRoomID), .showSettingsScreen):
                return .settingsScreen(selectedRoomID: selectedRoomID)
            case (.settingsScreen(let selectedRoomID), .dismissedSettingsScreen):
                return .roomList(selectedRoomID: selectedRoomID)
                
            case (.roomList(let selectedRoomID), .feedbackScreen):
                return .feedbackScreen(selectedRoomID: selectedRoomID)
            case (.feedbackScreen(let selectedRoomID), .dismissedFeedbackScreen):
                return .roomList(selectedRoomID: selectedRoomID)
                
            case (.roomList(let selectedRoomID), .showRecoveryKeyScreen):
                return .recoveryKeyScreen(selectedRoomID: selectedRoomID)
            case (.recoveryKeyScreen(let selectedRoomID), .dismissedRecoveryKeyScreen):
                return .roomList(selectedRoomID: selectedRoomID)
                
            case (.roomList(let selectedRoomID), .startEncryptionResetFlow):
                return .encryptionResetFlow(selectedRoomID: selectedRoomID)
            case (.encryptionResetFlow(let selectedRoomID), .finishedEncryptionResetFlow):
                return .roomList(selectedRoomID: selectedRoomID)
                
            case (.roomList(let selectedRoomID), .showStartChatScreen):
                return .startChatScreen(selectedRoomID: selectedRoomID)
            case (.startChatScreen(let selectedRoomID), .dismissedStartChatScreen):
                return .roomList(selectedRoomID: selectedRoomID)
                            
            case (.roomList(let selectedRoomID), .showLogoutConfirmationScreen):
                return .logoutConfirmationScreen(selectedRoomID: selectedRoomID)
            case (.logoutConfirmationScreen(let selectedRoomID), .dismissedLogoutConfirmationScreen):
                return .roomList(selectedRoomID: selectedRoomID)
                
            case (.roomList(let selectedRoomID), .showRoomDirectorySearchScreen):
                return .roomDirectorySearchScreen(selectedRoomID: selectedRoomID)
            case (.roomDirectorySearchScreen(let selectedRoomID), .dismissedRoomDirectorySearchScreen):
                return .roomList(selectedRoomID: selectedRoomID)
            
            case (_, .showUserProfileScreen):
                return .userProfileScreen
            case (.userProfileScreen, .dismissedUserProfileScreen):
                return .roomList(selectedRoomID: nil)
                
            case (.roomList, .showShareExtensionRoomList(let sharePayload)):
                return .shareExtensionRoomList(sharePayload: sharePayload)
            case (.shareExtensionRoomList, .dismissedShareExtensionRoomList):
                return .roomList(selectedRoomID: nil)
                
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
        
        addTransitionHandler { [weak self] context in
            self?.stateSubject.send(context.toState)
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
