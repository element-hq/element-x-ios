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
    case selectRoom(roomIdentifier: String)
    case userMenu(action: HomeScreenViewUserMenuAction)
    case verifySession
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
}

enum HomeScreenRoomListMode {
    case skeletons
    case rooms
}

struct HomeScreenViewState: BindableState {
    var userID: String
    var userDisplayName: String?
    var userAvatar: UIImage?
    
    var showSessionVerificationBanner = false
    
    var rooms: [HomeScreenRoom] = []
    
    var roomListMode: HomeScreenRoomListMode = .rooms
    
    var visibleRooms: [HomeScreenRoom] {
        if roomListMode == .skeletons {
            return placeholderRooms
        }
        
        if bindings.searchQuery.isEmpty {
            return rooms
        }
        
        return rooms.lazy.filter { $0.asFilled?.name.localizedStandardContains(bindings.searchQuery) ?? false }
    }
    
    var bindings = HomeScreenViewStateBindings()
    
    var placeholderRooms: [HomeScreenRoom] {
        (1...10).map { index in
            HomeScreenRoom.empty(HomeScreenRoomDetails.placeholder(id: "\(index)"))
        }
    }
}

struct HomeScreenViewStateBindings {
    var searchQuery = ""
}

enum HomeScreenRoom: Identifiable, Equatable {
    case empty(HomeScreenRoomDetails)
    case filled(HomeScreenRoomDetails)
    
    var id: String {
        switch self {
        case .filled(let room), .empty(let room):
            return room.id
        }
    }
    
    var asFilled: HomeScreenRoomDetails? {
        guard case let .filled(details) = self else {
            return nil
        }
        
        return details
    }
}

struct HomeScreenRoomDetails: Identifiable, Equatable {
    let id: String
    
    let name: String
    
    let hasUnreads: Bool
    
    let timestamp: String?
    
    var lastMessage: AttributedString?
    
    var avatar: UIImage?
    
    static func placeholder(id: String) -> HomeScreenRoomDetails {
        HomeScreenRoomDetails(id: id,
                              name: "Placeholder room name",
                              hasUnreads: false,
                              timestamp: "Now",
                              lastMessage: AttributedString("Last message"),
                              avatar: UIImage(systemName: "photo"))
    }
}
