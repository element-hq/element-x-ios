//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum MessageForwardingScreenViewModelAction {
    case dismiss
    case sent(roomIDs: [String])
}

struct MessageForwardingScreenViewState: BindableState {
    /// The recently visited rooms, never filtered by the search query.
    var suggestedRooms: [MessageForwardingRoom] = []
    var rooms: [MessageForwardingRoom] = []
    var selectedRoomIDs: Set<String> = []
    let maxRoomSelectionCount = 5
    var bindings = MessageForwardingScreenViewStateBindings()
    
    var showsSuggestions: Bool {
        bindings.searchQuery.isEmpty && !suggestedRooms.isEmpty
    }
    
    /// Every room appears once: the suggested ones are left out unless searching.
    var chats: [MessageForwardingRoom] {
        guard showsSuggestions else { return rooms }
        
        let suggestedRoomIDs = Set(suggestedRooms.map(\.id))
        return rooms.filter { !suggestedRoomIDs.contains($0.id) }
    }
    
    var isAtRoomSelectionLimit: Bool {
        selectedRoomIDs.count >= maxRoomSelectionCount
    }
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
    let title: String
    let description: String
    let avatar: RoomAvatar
}

extension MessageForwardingRoom {
    init(summary: RoomSummary) {
        self.init(id: summary.id,
                  title: summary.name,
                  description: summary.roomListDescription,
                  avatar: summary.avatar)
    }
}

struct MessageForwardingPayload: Hashable {
    /// The source items' timeline IDs. Only necessary for a rough Hashable conformance.
    let ids: [TimelineItemIdentifier]
    /// The source items' room ID.
    let roomID: String
    /// The contents to be forwarded, in timeline order.
    let contents: [RoomMessageEventContentWithoutRelation]
    
    static func == (lhs: MessageForwardingPayload, rhs: MessageForwardingPayload) -> Bool {
        lhs.ids == rhs.ids && lhs.roomID == rhs.roomID
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ids)
        hasher.combine(roomID)
    }
}
