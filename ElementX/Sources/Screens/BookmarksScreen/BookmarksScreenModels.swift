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
    let id: TimelineItemIdentifier
    let body: String
    let roomName: String
}

struct BookmarksScreenViewState: BindableState {
    var items = [BookmarkListItem]()
}

enum BookmarksScreenViewAction {
    case dismiss
}
