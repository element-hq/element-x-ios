//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum RoomSelectionScreenViewModelAction {
    case dismiss
    case confirm(roomID: String)
}

struct RoomSelectionScreenViewState: BindableState {
    var rooms: [RoomSelectionRoom] = []
    var selectedRoomID: String?
    var bindings = RoomSelectionScreenViewStateBindings()
}

struct RoomSelectionScreenViewStateBindings {
    var searchQuery = ""
}

enum RoomSelectionScreenViewAction {
    case cancel
    case confirm
    case selectRoom(roomID: String)
    case reachedTop
    case reachedBottom
}

struct RoomSelectionRoom: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let avatar: RoomAvatar
}
