//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import SwiftState

class ChatsFlowCoordinatorStateMachine {
    /// States the AppCoordinator can find itself in
    enum State: StateType {
        /// The initial state, used before the coordinator starts
        case initial
                
        /// Showing the home screen. The `roomListSelectedRoomID` represents the timeline shown on the detail panel (if any)
        case roomList(roomListSelectedRoomID: String?)
                
        /// Showing the feedback screen.
        case feedbackScreen(roomListSelectedRoomID: String?)
        
        /// Showing the settings screen
        case settingsScreen(roomListSelectedRoomID: String?)
        
        /// Showing the recovery key screen.
        case recoveryKeyScreen(roomListSelectedRoomID: String?)
        
        /// Showing the encryption reset flow.
        case encryptionResetFlow(roomListSelectedRoomID: String?)
        
        /// Showing the start chat screen
        case startChatScreen(roomListSelectedRoomID: String?)
        
        /// Showing the logout flows
        case logoutConfirmationScreen(roomListSelectedRoomID: String?)
        
        /// Showing Room Directory Search screen
        case roomDirectorySearchScreen(roomListSelectedRoomID: String?)
        
        /// Showing the user profile screen. This screen clears the navigation.
        case userProfileScreen
        
        /// Showing the report room screen, for the given room identrifier
        case reportRoomScreen(roomListSelectedRoomID: String?)
        
        case shareExtensionRoomList(sharePayload: ShareExtensionPayload)
        
        case declineAndBlockUserScreen(roomListSelectedRoomID: String?)
        
        /// The selected room ID from the state if available.
        var roomListSelectedRoomID: String? {
            switch self {
            case .initial, .userProfileScreen, .shareExtensionRoomList:
                nil
            case .roomList(let roomListSelectedRoomID),
                 .feedbackScreen(let roomListSelectedRoomID),
                 .settingsScreen(let roomListSelectedRoomID),
                 .recoveryKeyScreen(let roomListSelectedRoomID),
                 .encryptionResetFlow(let roomListSelectedRoomID),
                 .startChatScreen(let roomListSelectedRoomID),
                 .logoutConfirmationScreen(let roomListSelectedRoomID),
                 .roomDirectorySearchScreen(let roomListSelectedRoomID),
                 .reportRoomScreen(let roomListSelectedRoomID),
                 .declineAndBlockUserScreen(let roomListSelectedRoomID):
                roomListSelectedRoomID
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
        
        case presentReportRoomScreen(roomID: String)
        case dismissedReportRoomScreen
        
        case presentDeclineAndBlockScreen(userID: String, roomID: String)
        case dismissedDeclineAndBlockScreen
    }
    
    private let stateMachine: StateMachine<State, Event>
    
    var state: ChatsFlowCoordinatorStateMachine.State {
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
        stateMachine.addRoutes(event: .start, transitions: [.initial => .roomList(roomListSelectedRoomID: nil)])

        stateMachine.addRouteMapping { event, fromState, _ in
            switch (fromState, event) {
            case (.roomList, .selectRoom(let roomID, _, _)):
                return .roomList(roomListSelectedRoomID: roomID)
            case (.roomList, .deselectRoom):
                return .roomList(roomListSelectedRoomID: nil)

            case (.roomList(let roomListSelectedRoomID), .showSettingsScreen):
                return .settingsScreen(roomListSelectedRoomID: roomListSelectedRoomID)
            case (.settingsScreen(let roomListSelectedRoomID), .dismissedSettingsScreen):
                return .roomList(roomListSelectedRoomID: roomListSelectedRoomID)
                
            case (.roomList(let roomListSelectedRoomID), .feedbackScreen):
                return .feedbackScreen(roomListSelectedRoomID: roomListSelectedRoomID)
            case (.feedbackScreen(let roomListSelectedRoomID), .dismissedFeedbackScreen):
                return .roomList(roomListSelectedRoomID: roomListSelectedRoomID)
                
            case (.roomList(let roomListSelectedRoomID), .showRecoveryKeyScreen):
                return .recoveryKeyScreen(roomListSelectedRoomID: roomListSelectedRoomID)
            case (.recoveryKeyScreen(let roomListSelectedRoomID), .dismissedRecoveryKeyScreen):
                return .roomList(roomListSelectedRoomID: roomListSelectedRoomID)
                
            case (.roomList(let roomListSelectedRoomID), .startEncryptionResetFlow):
                return .encryptionResetFlow(roomListSelectedRoomID: roomListSelectedRoomID)
            case (.encryptionResetFlow(let roomListSelectedRoomID), .finishedEncryptionResetFlow):
                return .roomList(roomListSelectedRoomID: roomListSelectedRoomID)
                
            case (.roomList(let roomListSelectedRoomID), .showStartChatScreen):
                return .startChatScreen(roomListSelectedRoomID: roomListSelectedRoomID)
            case (.startChatScreen(let roomListSelectedRoomID), .dismissedStartChatScreen):
                return .roomList(roomListSelectedRoomID: roomListSelectedRoomID)
                
            case (.roomList(let roomListSelectedRoomID), .showRoomDirectorySearchScreen):
                return .roomDirectorySearchScreen(roomListSelectedRoomID: roomListSelectedRoomID)
            case (.roomDirectorySearchScreen(let roomListSelectedRoomID), .dismissedRoomDirectorySearchScreen):
                return .roomList(roomListSelectedRoomID: roomListSelectedRoomID)
            
            case (_, .showUserProfileScreen):
                return .userProfileScreen
            case (.userProfileScreen, .dismissedUserProfileScreen):
                return .roomList(roomListSelectedRoomID: nil)
                
            case (.roomList, .showShareExtensionRoomList(let sharePayload)):
                return .shareExtensionRoomList(sharePayload: sharePayload)
            case (.shareExtensionRoomList, .dismissedShareExtensionRoomList):
                return .roomList(roomListSelectedRoomID: nil)
                
            case (.roomList(let roomListSelectedRoomID), .presentReportRoomScreen):
                return .reportRoomScreen(roomListSelectedRoomID: roomListSelectedRoomID)
            case (.reportRoomScreen(let roomListSelectedRoomID), .dismissedReportRoomScreen):
                return .roomList(roomListSelectedRoomID: roomListSelectedRoomID)
                
            case(.roomList(let roomListSelectedRoomID), .presentDeclineAndBlockScreen):
                return .declineAndBlockUserScreen(roomListSelectedRoomID: roomListSelectedRoomID)
            case (.declineAndBlockUserScreen(let roomListSelectedRoomID), .dismissedDeclineAndBlockScreen):
                return .roomList(roomListSelectedRoomID: roomListSelectedRoomID)
                
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
        case .roomList(let roomListSelectedRoomID):
            return roomID == roomListSelectedRoomID
        default:
            return false
        }
    }
}
