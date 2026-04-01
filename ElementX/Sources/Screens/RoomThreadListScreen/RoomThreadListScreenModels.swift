//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum RoomThreadListScreenViewModelAction {
    case presentThread(threadRootEventID: String)
}

struct RoomThreadListScreenViewState: BindableState {
    var items = [RoomThreadListItem]()
    
    var isPaginating = false
    
    var bindings: RoomThreadListScreenViewStateBindings
}

struct RoomThreadListScreenViewStateBindings { }

enum RoomThreadListScreenViewAction {
    case oldestItemDidAppear
    case oldestItemDidDisappear
    case tappedThread(threadRootEventID: String)
}
