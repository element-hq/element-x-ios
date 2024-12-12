//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

enum MediaEventsTimelineScreenViewModelAction {
    case viewItem(TimelineMediaPreviewContext)
}

enum MediaEventsTimelineScreenMode {
    case media
    case files
}

struct MediaEventsTimelineGroup: Identifiable {
    var id: String
    var title: String
    var items: [RoomTimelineItemViewState]
}

struct MediaEventsTimelineScreenViewState: BindableState {
    var isBackPaginating = false
    var groups = [MediaEventsTimelineGroup]()
    
    var activeTimelineContextProvider: (() -> TimelineViewModel.Context)!
    
    var bindings: MediaEventsTimelineScreenViewStateBindings
}

struct MediaEventsTimelineScreenViewStateBindings {
    var screenMode: MediaEventsTimelineScreenMode
}

enum MediaEventsTimelineScreenViewAction {
    case changedScreenMode
    case oldestItemDidAppear
    case oldestItemDidDisappear
    case tappedItem(item: RoomTimelineItemViewState, namespace: Namespace.ID)
}
