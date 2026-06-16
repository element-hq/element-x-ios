//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum SearchScreenViewModelAction {
    case presentRoom(roomID: String)
}

struct SearchScreenViewState: BindableState {
    var rooms = [SearchScreenRoom]()
    var bindings: SearchScreenViewStateBindings
    
    var isSearching: Bool {
        !bindings.searchQuery.isEmpty
    }
}

struct SearchScreenViewStateBindings {
    var searchQuery = ""
}

enum SearchScreenViewAction {
    case selectRoom(roomID: String)
    case reachedTop
    case reachedBottom
}

struct SearchScreenRoom: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let avatar: RoomAvatar
}
