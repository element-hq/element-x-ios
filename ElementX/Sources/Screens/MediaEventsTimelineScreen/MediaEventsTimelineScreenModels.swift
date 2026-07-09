//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

enum MediaEventsTimelineScreenViewModelAction {
    case displayMessageForwarding(MessageForwardingItem)
    case viewInRoomTimeline(TimelineItemIdentifier)
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
    var shouldShowEmptyState = false
    
    /// The mode that `groups` were built for, so that the layout and its items always change
    /// together. Updated through the ``MediaEventsTimelineScreenViewAction/changeScreenMode(_:)`` action.
    var screenMode: MediaEventsTimelineScreenMode
    var groups = [MediaEventsTimelineGroup]()
    
    var activeTimelineContext: TimelineViewModel.Context
    
    var bindings: MediaEventsTimelineScreenViewStateBindings
}

struct MediaEventsTimelineScreenViewStateBindings {
    var mediaPreviewViewModel: TimelineMediaPreviewViewModel?
    var mediaPreviewSheetViewModel: TimelineMediaPreviewViewModel?
}

enum MediaEventsTimelineScreenViewAction {
    case changeScreenMode(MediaEventsTimelineScreenMode)
    case oldestItemDidAppear
    case oldestItemDidDisappear
    case tappedItem(item: RoomTimelineItemViewState)
    case longPressedItem(item: RoomTimelineItemViewState)
}
