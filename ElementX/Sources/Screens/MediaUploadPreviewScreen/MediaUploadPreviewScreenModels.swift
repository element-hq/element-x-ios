//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum MediaUploadPreviewScreenViewModelAction {
    case dismiss
}

struct MediaUploadPreviewScreenViewState: BindableState {
    let url: URL
    let title: String?
    let shouldShowCaptionWarning: Bool
    var shouldDisableInteraction = false
    
    var bindings = MediaUploadPreviewScreenBindings()
}

struct MediaUploadPreviewScreenBindings: BindableState {
    var caption = NSAttributedString()
    var presendCallback: (() -> Void)?
    
    var isPresentingMediaCaptionWarning = false
}

enum MediaUploadPreviewScreenViewAction {
    case send
    case cancel
}
