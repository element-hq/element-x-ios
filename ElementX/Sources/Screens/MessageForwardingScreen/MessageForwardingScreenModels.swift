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

enum MessageForwardingScreenViewModelAction {
    case dismiss
    case send(roomID: String)
}

struct MessageForwardingScreenViewState: BindableState {
    var rooms: [MessageForwardingRoom] = []
    var selectedRoomID: String?
    
    var visibleRooms: [MessageForwardingRoom] {
        if bindings.searchQuery.isEmpty {
            return rooms
        }
        
        return rooms.filter { $0.name.localizedStandardContains(bindings.searchQuery) }
    }
    
    var bindings = MessageForwardingScreenViewStateBindings()
}

struct MessageForwardingScreenViewStateBindings {
    var searchQuery = ""
}

enum MessageForwardingScreenViewAction {
    case cancel
    case send
    case selectRoom(roomID: String)
}

struct MessageForwardingRoom: Identifiable, Equatable {
    let id: String
    let name: String
    let alias: String?
    let avatarURL: URL?
}
