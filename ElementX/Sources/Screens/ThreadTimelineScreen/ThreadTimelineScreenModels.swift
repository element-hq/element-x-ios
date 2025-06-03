//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum ThreadTimelineScreenViewModelAction { }

struct ThreadTimelineScreenViewState: BindableState {
    var canSendMessage = true
    
    var bindings = ThreadTimelineScreenViewStateBindings()
}

struct ThreadTimelineScreenViewStateBindings {
    /// The view model used to present a QuickLook media preview.
    var mediaPreviewViewModel: TimelineMediaPreviewViewModel?
}

enum ThreadTimelineScreenViewAction { }
