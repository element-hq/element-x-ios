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

import Combine
import Foundation
import UIKit

enum HomeScreenViewModelAction {
    case presentRoom(roomIdentifier: String)
    case presentRoomDetails(roomIdentifier: String)
    case roomLeft(roomIdentifier: String)
    case presentSessionVerificationScreen
    case presentSecureBackupSettings
    case presentSettingsScreen
    case presentFeedbackScreen
    case presentStartChatScreen
    case presentInvitesScreen
    case logout
}

enum HomeScreenViewUserMenuAction {
    case settings
    case logout
}

enum HomeScreenViewAction {
    case selectRoom(roomIdentifier: String)
    case showRoomDetails(roomIdentifier: String)
    case leaveRoom(roomIdentifier: String)
    case confirmLeaveRoom(roomIdentifier: String)
    case userMenu(action: HomeScreenViewUserMenuAction)
    case startChat
    case verifySession
    case confirmRecoveryKey
    case skipSessionVerification
    case skipRecoveryKeyConfirmation
    case updateVisibleItemRange(range: Range<Int>, isScrolling: Bool)
    case selectInvites
}

enum HomeScreenRoomListMode: CustomStringConvertible {
    case skeletons
    case empty
    case rooms
    
    var description: String {
        switch self {
        case .skeletons:
            return "Showing placeholders"
        case .empty:
            return "Showing empty state"
        case .rooms:
            return "Showing rooms"
        }
    }
}

struct HomeScreenViewState: BindableState {
    let userID: String
    var userDisplayName: String?
    var userAvatarURL: URL?
    
    var isSessionVerified: Bool?
    var hasSessionVerificationBannerBeenDismissed = false
    var showSessionVerificationBanner: Bool {
        guard let isSessionVerified else {
            return false
        }
        
        return !isSessionVerified && !hasSessionVerificationBannerBeenDismissed
    }
    
    var requiresSecureBackupSetup = false

    var needsRecoveryKeyConfirmation = false
    var hasRecoveryKeyConfirmationBannerBeenDismissed = false
    var showRecoveryKeyConfirmationBanner: Bool {
        guard let isSessionVerified else {
            return false
        }
        
        return isSessionVerified && needsRecoveryKeyConfirmation && !hasRecoveryKeyConfirmationBannerBeenDismissed
    }
    
    var rooms: [HomeScreenRoom] = []
    var roomListMode: HomeScreenRoomListMode = .skeletons
    
    var hasPendingInvitations = false
    var hasUnreadPendingInvitations = false
    
    var selectedRoomID: String?
    
    var visibleRooms: [HomeScreenRoom] {
        if roomListMode == .skeletons {
            return placeholderRooms
        }
        
        return rooms
    }
    
    var bindings = HomeScreenViewStateBindings()
    
    var placeholderRooms: [HomeScreenRoom] {
        (1...10).map { _ in
            HomeScreenRoom.placeholder()
        }
    }
    
    // Used to hide all the rooms when the search field is focused and the query is empty
    var shouldHideRoomList: Bool {
        bindings.isSearchFieldFocused && bindings.searchQuery.isEmpty
    }
}

struct HomeScreenViewStateBindings {
    var searchQuery = ""
    var isSearchFieldFocused = false
    
    var alertInfo: AlertInfo<UUID>?
    var leaveRoomAlertItem: LeaveRoomAlertItem?
}

struct HomeScreenRoom: Identifiable, Equatable {
    static let placeholderLastMessage = AttributedString("Hidden last message")
        
    /// The list item identifier can be a real room identifier, a custom one for invalidated entries
    /// or a completely unique one for empty items and skeletons
    let id: String
    
    /// The real room identifier this item points to
    let roomId: String?
    
    var name = ""
    
    var hasUnreads = false
    
    var hasMentions = false
    
    var hasOngoingCall = false
    
    var timestamp: String?
    
    var lastMessage: AttributedString?
    
    var avatarURL: URL?
    
    var notificationMode: RoomNotificationModeProxy?
    
    var isPlaceholder = false
    
    static func placeholder() -> HomeScreenRoom {
        HomeScreenRoom(id: UUID().uuidString,
                       roomId: nil,
                       name: "Placeholder room name",
                       hasUnreads: false,
                       hasMentions: false,
                       timestamp: "Now",
                       lastMessage: placeholderLastMessage,
                       isPlaceholder: true)
    }
}
