//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum RoomMessageSearchScreenViewModelAction {
    case dismiss
    case displayEvent(eventID: String)
}

struct RoomMessageSearchScreenViewState: BindableState {
    var results: [RoomMessageSearchResult] = []
    var isLoading = false
    var hasSearched = false

    var bindings: RoomMessageSearchScreenViewStateBindings

    var shouldShowEmptyState: Bool {
        hasSearched && !isLoading && results.isEmpty && !bindings.searchQuery.isEmpty
    }
}

struct RoomMessageSearchScreenViewStateBindings {
    var searchQuery = ""
}

enum RoomMessageSearchScreenViewAction {
    case dismiss
    case selectResult(eventID: String)
    case reachedBottom
}
