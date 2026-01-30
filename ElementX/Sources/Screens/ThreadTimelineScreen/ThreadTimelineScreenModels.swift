//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum ThreadTimelineScreenViewModelAction {
    case displayMessageForwarding(MessageForwardingItem)
}

struct ThreadTimelineScreenViewState: BindableState {
    var roomTitle: String
    var roomAvatar: RoomAvatar
    var canSendMessage = true
    var dmRecipientVerificationState: UserIdentityVerificationState?
    var roomHistorySharingState: RoomHistorySharingState?
    
    var bindings = ThreadTimelineScreenViewStateBindings()
}

struct ThreadTimelineScreenViewStateBindings {
    /// The view model used to present a QuickLook media preview.
    var mediaPreviewViewModel: TimelineMediaPreviewViewModel?
}

enum ThreadTimelineScreenViewAction { }
