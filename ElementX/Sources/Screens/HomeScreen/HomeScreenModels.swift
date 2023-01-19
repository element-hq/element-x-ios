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
import UIKit

enum HomeScreenViewModelAction {
    case presentRoom(roomIdentifier: String)
    case presentSessionVerificationScreen
    case presentSettingsScreen
    case presentInviteFriendsScreen
    case presentFeedbackScreen
    case signOut
}

enum HomeScreenViewUserMenuAction {
    case settings
    case inviteFriends
    case feedback
    case signOut
}

enum HomeScreenViewAction {
    case loadRoomData(roomIdentifier: String)
    case selectRoom(roomIdentifier: String)
    case userMenu(action: HomeScreenViewUserMenuAction)
    case verifySession
    case skipSessionVerification
    case updatedVisibleItemRange(Range<Int>)
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
    var userID: String
    var userDisplayName: String?
    var userAvatar: UIImage?
    
    var showSessionVerificationBanner = false
    
    var rooms: [HomeScreenRoom] = []
    
    var roomListMode: HomeScreenRoomListMode = .skeletons
    
    var visibleRooms: [HomeScreenRoom] {
        if roomListMode == .skeletons {
            return placeholderRooms
        }
        
        if bindings.searchQuery.isEmpty {
            return rooms
        }
        
        return rooms.lazy.filter { $0.name.localizedStandardContains(bindings.searchQuery) }
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
}

struct HomeScreenRoom: Identifiable, Equatable {
    private static let placeholderLastMessage = AttributedString("Last message")
    private static let placeholderAvatar = UIImage(systemName: "photo")
    
    /// The list item identifier can be a real room identifier, a custom one for invalidated entries
    /// or a completely unique one for empty items and skeletons
    let id: String
    
    /// The real room identifier this item points to
    let roomId: String?
    
    let name: String
    
    let hasUnreads: Bool
    
    let timestamp: String?
    
    var lastMessage: AttributedString?
    
    var avatarURL: URL?
    
    var avatar: UIImage?
    
    var isPlaceholder = false
    
    static func placeholder() -> HomeScreenRoom {
        HomeScreenRoom(id: UUID().uuidString,
                       roomId: nil,
                       name: "Placeholder room name",
                       hasUnreads: false,
                       timestamp: "Now",
                       lastMessage: Self.placeholderLastMessage,
                       avatar: Self.placeholderAvatar,
                       isPlaceholder: true)
    }
}
