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
    case presentRoomSettings(roomIdentifier: String)
    case presentSessionVerificationScreen
    case presentSettingsScreen
    case presentFeedbackScreen
    case presentStartChatScreen
    case presentInvitesScreen
    case signOut
}

enum HomeScreenViewUserMenuAction {
    case settings
    case feedback
    case signOut
}

enum HomeScreenViewAction {
    case selectRoom(roomIdentifier: String)
    case showRoomSettings(roomIdentifier: String)
    case leaveRoom(roomIdentifier: String)
    case confirmLeaveRoom
    case userMenu(action: HomeScreenViewUserMenuAction)
    case startChat
    case verifySession
    case skipSessionVerification
    case updateVisibleItemRange(range: Range<Int>, isScrolling: Bool)
    case selectInvites
}

enum HomeScreenRoomListMode: CustomStringConvertible {
    case skeletons
    case rooms
    
    var description: String {
        switch self {
        case .rooms:
            return "Showing rooms"
        case .skeletons:
            return "Showing placeholders"
        }
    }
}

struct HomeScreenViewState: BindableState {
    let userID: String
    var userDisplayName: String?
    var userAvatarURL: URL?
    var showSessionVerificationBanner = false
    var rooms: [HomeScreenRoom] = []
    var roomListMode: HomeScreenRoomListMode = .skeletons
    
    /// The URL that will be shared when inviting friends to use the app.
    let invitePermalink: URL?
    
    var hasPendingInvitations = false
    var hasUnreadPendingInvitations = false
    
    var startChatFlowEnabled: Bool {
        ServiceLocator.shared.settings.startChatFlowEnabled
    }
    
    var visibleRooms: [HomeScreenRoom] {
        if roomListMode == .skeletons {
            return placeholderRooms
        }
        
        if bindings.searchQuery.isEmpty {
            return rooms
        }
        
        return rooms.filter { $0.name.localizedStandardContains(bindings.searchQuery) }
    }
    
    var bindings = HomeScreenViewStateBindings()
    
    var placeholderRooms: [HomeScreenRoom] {
        (1...10).map { _ in
            HomeScreenRoom.placeholder()
        }
    }
}

struct HomeScreenViewStateBindings {
    var searchQuery = ""
    
    var alertInfo: AlertInfo<UUID>?
    var leaveRoomAlertItem: LeaveRoomAlertItem?
}

struct HomeScreenRoom: Identifiable, Equatable {
    static let placeholderLastMessage = AttributedString("Hidden last message")
    
    enum LastMessage: Equatable {
        case loaded(AttributedString)
        case loading
        case unknown
        
        init(attributedString: AttributedString?, isLoading: Bool) {
            if let message = attributedString, !message.characters.isEmpty {
                self = .loaded(message)
            } else if isLoading {
                self = .loading
            } else {
                self = .unknown
            }
        }
    }
    
    /// The list item identifier can be a real room identifier, a custom one for invalidated entries
    /// or a completely unique one for empty items and skeletons
    let id: String
    
    /// The real room identifier this item points to
    let roomId: String?
    
    var name = ""
    
    var hasUnreads = false
    
    var timestamp: String?
    
    var lastMessage: LastMessage
    
    var avatarURL: URL?
    
    var isPlaceholder = false
    
    static func placeholder() -> HomeScreenRoom {
        HomeScreenRoom(id: UUID().uuidString,
                       roomId: nil,
                       name: "Placeholder room name",
                       hasUnreads: false,
                       timestamp: "Now",
                       lastMessage: .loading,
                       isPlaceholder: true)
    }
}
