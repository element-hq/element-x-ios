//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
