//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum MediaEventsTimelineScreenViewModelAction { }

enum MediaEventsTimelineScreenMode {
    case media
    case files
}

struct MediaEventsTimelineScreenViewState: BindableState {
    var isBackPaginating = false
    var items = [RoomTimelineItemViewState]()
    
    var bindings: MediaEventsTimelineScreenViewStateBindings
}

struct MediaEventsTimelineScreenViewStateBindings {
    var screenMode: MediaEventsTimelineScreenMode
    var mediaPreviewViewModel: TimelineMediaPreviewViewModel?
}

enum MediaEventsTimelineScreenViewAction {
    case changedScreenMode
    case oldestItemDidAppear
    case oldestItemDidDisappear
    case tappedItem(RoomTimelineItemViewState)
}
