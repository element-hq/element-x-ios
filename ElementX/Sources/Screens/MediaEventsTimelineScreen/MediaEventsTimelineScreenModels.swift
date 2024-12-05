//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum MediaEventsTimelineScreenViewModelAction { }

enum MediaEventsTimelineScreenMode {
    case imageAndVideo
    case fileAndAudio
}

struct MediaEventsTimelineScreenViewState: BindableState {
    var isBackPaginating = false
    var items = [RoomTimelineItemViewState]()
    
    var bindings: MediaEventsTimelineScreenViewStateBindings
}

struct MediaEventsTimelineScreenViewStateBindings {
    var screenMode: MediaEventsTimelineScreenMode
}

enum MediaEventsTimelineScreenViewAction {
    case changedScreenMode
    case topBecameVisible
    case topBecameHidden
}
