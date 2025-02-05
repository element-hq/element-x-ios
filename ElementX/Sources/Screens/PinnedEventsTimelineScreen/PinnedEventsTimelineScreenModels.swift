//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum PinnedEventsTimelineScreenViewModelAction {
    case viewInRoomTimeline(itemID: TimelineItemIdentifier)
    case dismiss
}

struct PinnedEventsTimelineScreenViewState: BindableState {
    var bindings = PinnedEventsTimelineScreenViewStateBindings()
}

struct PinnedEventsTimelineScreenViewStateBindings {
    /// The view model used to present a QuickLook media preview.
    var mediaPreviewViewModel: TimelineMediaPreviewViewModel?
}

enum PinnedEventsTimelineScreenViewAction {
    case close
}
