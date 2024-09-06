//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum MediaUploadPreviewScreenViewModelAction {
    case dismiss
}

struct MediaUploadPreviewScreenViewState: BindableState {
    let url: URL
    let title: String?
    var shouldDisableInteraction = false
}

enum MediaUploadPreviewScreenViewAction {
    case send
    case cancel
}
