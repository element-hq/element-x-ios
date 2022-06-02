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

enum HomeScreenViewModelAction {
    case logout
    case selectRoom(roomIdentifier: String)
    case tapUserAvatar
}

enum HomeScreenViewAction {
    case logout
    case loadRoomData(roomIdentifier: String)
    case selectRoom(roomIdentifier: String)
    case tapUserAvatar
}

struct HomeScreenViewState: BindableState {
    var userDisplayName: String?
    var userAvatar: UIImage?
    
    var rooms: [HomeScreenRoom] = []
    var isLoadingRooms: Bool = false
    
    var unencryptedDMs: [HomeScreenRoom] {
        Array(rooms.filter { $0.isDirect && !$0.isEncrypted })
    }
    
    var encryptedDMs: [HomeScreenRoom] {
        Array(rooms.filter { $0.isDirect && $0.isEncrypted})
    }
    
    var unencryptedRooms: [HomeScreenRoom] {
        Array(rooms.filter { !$0.isDirect && !$0.isEncrypted })
    }
    
    var encryptedRooms: [HomeScreenRoom] {
        Array(rooms.filter { !$0.isDirect && $0.isEncrypted })
    }
}

struct HomeScreenRoom: Identifiable, Equatable {
    let id: String
    
    var displayName: String?
    
    let topic: String?
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
