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
}

struct ChatsSpaceFiltersScreenViewStateBindings { }

enum ChatsSpaceFiltersScreenViewAction {
    case confirm(SpaceServiceFilter)
    case cancel
}
