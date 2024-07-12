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
import MatrixRustSDK

enum MessageForwardingScreenViewModelAction {
    case dismiss
    case sent(roomID: String)
}

struct MessageForwardingScreenViewState: BindableState {
    var rooms: [MessageForwardingRoom] = []
    var selectedRoomID: String?
    var bindings = MessageForwardingScreenViewStateBindings()
}

struct MessageForwardingScreenViewStateBindings {
    var searchQuery = ""
}

enum MessageForwardingScreenViewAction {
    case cancel
    case send
    case selectRoom(roomID: String)
    case reachedTop
    case reachedBottom
}

struct MessageForwardingRoom: Identifiable, Equatable {
    let id: String
    let name: String
    let alias: String?
    let avatar: RoomAvatar
}

struct MessageForwardingItem: Hashable {
    /// The source item's timeline ID. Only necessary for a rough Hashable conformance.
    let id: TimelineItemIdentifier
    /// The source item's room ID.
    let roomID: String
    /// The item's content to be forwarded.
    let content: RoomMessageEventContentWithoutRelation
    
    static func == (lhs: MessageForwardingItem, rhs: MessageForwardingItem) -> Bool {
        lhs.id == rhs.id && lhs.roomID == rhs.roomID
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(roomID)
    }
}
