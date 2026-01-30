//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum ChatsSpaceFiltersScreenViewModelAction {
    case confirm(SpaceServiceFilter)
    case cancel
}

struct ChatsSpaceFiltersScreenViewState: BindableState {
    var filters = [SpaceServiceFilter]()
    var bindings: ChatsSpaceFiltersScreenViewStateBindings
    
    var visibleFilters: [SpaceServiceFilter] {
        if bindings.searchQuery.isEmpty {
            return filters
        }
        
        return filters.filter { filter in
            filter.room.name.localizedStandardContains(bindings.searchQuery) ||
                (filter.room.canonicalAlias ?? "").localizedStandardContains(bindings.searchQuery)
        }
    }
}

struct ChatsSpaceFiltersScreenViewStateBindings {
    var searchQuery = ""
}

enum ChatsSpaceFiltersScreenViewAction: CustomStringConvertible {
    case confirm(SpaceServiceFilter)
    case cancel
    
    var description: String {
        switch self {
        case .confirm: "Confirm"
        case .cancel: "Cancel"
        }
    }
}
