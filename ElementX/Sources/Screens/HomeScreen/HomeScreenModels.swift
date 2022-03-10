// 
// Copyright 2021 New Vector Ltd
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

enum HomeScreenViewModelResult {
    case logout
    case loadUserAvatar
    case selectRoom(roomIdentifier: String)
}

enum HomeScreenViewAction {
    case logout
    case loadUserAvatar
    case loadRoomData(roomIdentifier: String)
    case selectRoom(roomIdentifier: String)
}

struct HomeScreenViewState: BindableState {
    let userDisplayName: String
    var userAvatar: UIImage?
    
    var rooms: [HomeScreenRoom] = []
    var isLoadingRooms: Bool = false
    
    var sortedRooms: [HomeScreenRoom] {
        rooms.sorted(by: { ($0.displayName ?? $0.id).lowercased() < ($1.displayName ?? $1.id).lowercased() })
    }
    
    var unencryptedDMs: [HomeScreenRoom] {
        Array(sortedRooms.filter { $0.isDirect && !$0.isEncrypted })
    }
    
    var encryptedDMs: [HomeScreenRoom] {
        Array(sortedRooms.filter { $0.isDirect && $0.isEncrypted})
    }
    
    var unencryptedRooms: [HomeScreenRoom] {
        Array(sortedRooms.filter { !$0.isDirect && !$0.isEncrypted })
    }
    
    var encryptedRooms: [HomeScreenRoom] {
        Array(sortedRooms.filter { !$0.isDirect && $0.isEncrypted })
    }
}

struct HomeScreenRoom: Identifiable {
    let id: String
    
    var displayName: String?
    
    let topic: String?
    let lastMessage: String?
    
    var avatar: UIImage?
    
    let isDirect: Bool
    let isEncrypted: Bool
}

extension MutableCollection where Element == HomeScreenRoom {
    mutating func updateEach(_ update: (inout Element) -> Void) {
        for index in indices {
            update(&self[index])
        }
    }
}
