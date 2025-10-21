//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum MediaUploadPreviewScreenViewModelAction {
    case dismiss
}

struct MediaUploadPreviewScreenViewState: BindableState {
    let mediaURLs: [URL]
    let title: String?
    let shouldShowCaptionWarning: Bool
    let isRoomEncrypted: Bool
    var shouldDisableInteraction = false
    
    var bindings = MediaUploadPreviewScreenBindings()
}

struct MediaUploadPreviewScreenBindings: BindableState {
    var caption = NSAttributedString()
    var presendCallback: (() -> Void)?
    var selectedRange = NSRange(location: 0, length: 0)
    
    var isPresentingMediaCaptionWarning = false
    var alertInfo: AlertInfo<MediaUploadPreviewAlertType>?
}

enum MediaUploadPreviewAlertType: Hashable {
    case maxUploadSizeUnknown
    case maxUploadSizeExceeded(limit: UInt)
}

enum MediaUploadPreviewScreenViewAction {
    case send
    case cancel
}
