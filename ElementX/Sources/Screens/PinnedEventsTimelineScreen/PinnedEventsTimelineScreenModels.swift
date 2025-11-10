//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum PinnedEventsTimelineScreenViewModelAction {
    case viewInRoomTimeline(eventID: String, threadRootEventID: String?)
    case displayMessageForwarding(MessageForwardingItem)
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
