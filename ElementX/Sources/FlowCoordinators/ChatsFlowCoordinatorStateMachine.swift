//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import SwiftState

class ChatsFlowCoordinatorStateMachine {
    enum DetailState: Hashable {
        case room(roomID: String)
        case space
    }

    /// States the AppCoordinator can find itself in
    enum State: StateType {
        /// The initial state, used before the coordinator starts
        case initial
                
        /// Showing the home screen. The `roomListSelectedRoomID` represents the timeline shown on the detail panel (if any)
        case roomList(detailState: DetailState?)
                
        /// Showing the feedback screen.
        case feedbackScreen(detailState: DetailState?)
        
        /// Showing the recovery key screen.
        case recoveryKeyScreen(detailState: DetailState?)
        
        /// Showing the encryption reset flow.
        case encryptionResetFlow(detailState: DetailState?)
        
        /// Showing the start chat flow
        case startChatFlow(detailState: DetailState?)
        
        /// Showing the logout flows
        case logoutConfirmationScreen(detailState: DetailState?)
        
        /// Showing Room Directory Search screen
        case roomDirectorySearchScreen(detailState: DetailState?)
        
        /// Showing the user profile screen. This screen clears the navigation.
        case userProfileScreen
        
        /// Showing the report room screen, for the given room identrifier
        case reportRoomScreen(detailState: DetailState?)
        
        case shareExtensionRoomList(sharePayload: ShareExtensionPayload)
        
        case declineAndBlockUserScreen(detailState: DetailState?)
        
        /// The selected room ID from the state if available.
        var detailState: DetailState? {
            switch self {
            case .initial, .userProfileScreen, .shareExtensionRoomList:
                nil
            case .roomList(let detailState),
                 .feedbackScreen(let detailState),
                 .recoveryKeyScreen(let detailState),
                 .encryptionResetFlow(let detailState),
                 .startChatFlow(let detailState),
                 .logoutConfirmationScreen(let detailState),
                 .roomDirectorySearchScreen(let detailState),
                 .reportRoomScreen(let detailState),
                 .declineAndBlockUserScreen(let detailState):
                detailState
            }
        }
    }
    
    struct EventUserInfo {
        let animated: Bool
        var spaceRoomListProxy: SpaceRoomListProxyProtocol?
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
        
        /// Request presentation of a space.
        ///
        /// The space's `RoomListProxyProtocol` must be provided in the `EventUserInfo`.
        case startSpaceFlow
        /// The space has been dismissed.
        case finishedSpaceFlow
        
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
        
        /// Request the start of the start chat flow.
        case startStartChatFlow
        /// The Start Chat flow is complete and has been dismissed.
        case finishedStartChatFlow
        
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
    
    init() {
        stateMachine = StateMachine(state: .initial)
        configure()
    }

    private func configure() {
        stateMachine.addRoutes(event: .start, transitions: [.initial => .roomList(detailState: nil)])

        stateMachine.addRouteMapping { event, fromState, _ in
            switch (fromState, event) {
            case (.roomList, .selectRoom(let roomID, _, _)):
                return .roomList(detailState: .room(roomID: roomID))
            case (.roomList, .deselectRoom):
                return .roomList(detailState: nil)
            
            case (.roomList, .startSpaceFlow):
                return .roomList(detailState: .space)
            case (.roomList, .finishedSpaceFlow):
                return .roomList(detailState: nil)
                
            case (.roomList(let detailState), .feedbackScreen):
                return .feedbackScreen(detailState: detailState)
            case (.feedbackScreen(let detailState), .dismissedFeedbackScreen):
                return .roomList(detailState: detailState)
                
            case (.roomList(let detailState), .showRecoveryKeyScreen):
                return .recoveryKeyScreen(detailState: detailState)
            case (.recoveryKeyScreen(let detailState), .dismissedRecoveryKeyScreen):
                return .roomList(detailState: detailState)
                
            case (.roomList(let detailState), .startEncryptionResetFlow):
                return .encryptionResetFlow(detailState: detailState)
            case (.encryptionResetFlow(let detailState), .finishedEncryptionResetFlow):
                return .roomList(detailState: detailState)
                
            case (.roomList(let detailState), .startStartChatFlow):
                return .startChatFlow(detailState: detailState)
            case (.startChatFlow(let detailState), .finishedStartChatFlow):
                return .roomList(detailState: detailState)
                
            case (.roomList(let detailState), .showRoomDirectorySearchScreen):
                return .roomDirectorySearchScreen(detailState: detailState)
            case (.roomDirectorySearchScreen(let detailState), .dismissedRoomDirectorySearchScreen):
                return .roomList(detailState: detailState)
            
            case (_, .showUserProfileScreen):
                return .userProfileScreen
            case (.userProfileScreen, .dismissedUserProfileScreen):
                return .roomList(detailState: nil)
                
            case (.roomList, .showShareExtensionRoomList(let sharePayload)):
                return .shareExtensionRoomList(sharePayload: sharePayload)
            case (.shareExtensionRoomList, .dismissedShareExtensionRoomList):
                return .roomList(detailState: nil)
                
            case (.roomList(let detailState), .presentReportRoomScreen):
                return .reportRoomScreen(detailState: detailState)
            case (.reportRoomScreen(let detailState), .dismissedReportRoomScreen):
                return .roomList(detailState: detailState)
                
            case(.roomList(let detailState), .presentDeclineAndBlockScreen):
                return .declineAndBlockUserScreen(detailState: detailState)
            case (.declineAndBlockUserScreen(let detailState), .dismissedDeclineAndBlockScreen):
                return .roomList(detailState: detailState)
                
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
        case .roomList(detailState: .room(let detailStateRoomID)):
            return roomID == detailStateRoomID
        default:
            return false
        }
    }
}
