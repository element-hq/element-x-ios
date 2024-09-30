//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum RoomDirectorySearchScreenViewModelAction {
    case selectAlias(String)
    case selectRoomID(String)
    case dismiss
}

struct RoomDirectorySearchScreenViewState: BindableState {
    var rooms: [RoomDirectorySearchResult] = []
    var isLoading = false
    
    var bindings = RoomDirectorySearchScreenViewStateBindings()
}

struct RoomDirectorySearchScreenViewStateBindings {
    var isSearching = false
    var searchString = ""
}

enum RoomDirectorySearchScreenViewAction {
    case dismiss
    case select(room: RoomDirectorySearchResult)
    case reachedBottom
}
