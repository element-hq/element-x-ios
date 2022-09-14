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
}

struct HomeScreenViewState: BindableState {
    var userDisplayName: String
    var userAvatar: UIImage?
    
    var showSessionVerificationBanner = false
    
    var rooms: [HomeScreenRoom] = []
    
    var isLoadingRooms = false
    
    var visibleDMs: [HomeScreenRoom] {
        searchFilteredRooms.filter(\.isDirect)
    }

    var visibleRooms: [HomeScreenRoom] {
        searchFilteredRooms.filter { !$0.isDirect }
    }
    
    private var searchFilteredRooms: LazyFilterSequence<LazySequence<[HomeScreenRoom]>.Elements> {
        guard !bindings.searchQuery.isEmpty else {
            // This extra filter is fine for now as there are always downstream filters
            // but if that changes, this approach should be reconsidered.
            return rooms.lazy.filter { _ in true }
        }
        
        return rooms.lazy.filter { $0.displayName?.localizedStandardContains(bindings.searchQuery) ?? false }
    }
    
    var bindings = HomeScreenViewStateBindings()
}

struct HomeScreenViewStateBindings {
    var searchQuery = ""
}

struct HomeScreenRoom: Identifiable, Equatable {
    let id: String
    
    var displayName: String?
    
    var topic: String?
    var lastMessage: String?
    
    var avatar: UIImage?
    
    let isDirect: Bool
    let isEncrypted: Bool
    let isSpace: Bool
    let isTombstoned: Bool
}

extension MutableCollection where Element == HomeScreenRoom {
    mutating func updateEach(_ update: (inout Element) -> Void) {
        for index in indices {
            update(&self[index])
        }
    }
}
