//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum GlobalSearchScreenViewModelAction {
    case dismiss
    case select(roomID: String)
}

struct GlobalSearchScreenViewState: BindableState {
    var rooms = [GlobalSearchRoom]()
    var bindings: GlobalSearchScreenViewStateBindings
}

struct GlobalSearchScreenViewStateBindings {
    var searchQuery: String
}

enum GlobalSearchScreenViewAction {
    case dismiss
    case select(roomID: String)
    case reachedTop
    case reachedBottom
}

struct GlobalSearchRoom: Identifiable, Equatable {
    let id: String
    let name: String
    let alias: String?
    let avatar: RoomAvatar
}
