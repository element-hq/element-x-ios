//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum BookmarksScreenViewModelAction {
    case dismiss
}

struct BookmarkListItem: Identifiable {
    var id: ObjectIdentifier {
        timelineItemViewState.id
    }
    
    let timelineItemViewState: RoomTimelineItemViewState
    let roomName: String
    let timelineContext: TimelineViewModelType.Context
}

struct BookmarksScreenViewState: BindableState {
    var items = [BookmarkListItem]()
}

enum BookmarksScreenViewAction {
    case dismiss
}
