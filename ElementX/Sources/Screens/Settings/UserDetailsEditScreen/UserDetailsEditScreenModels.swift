//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum UserDetailsEditScreenViewModelAction {
    case dismiss
    case displayCameraPicker
    case displayMediaPicker
    case displayFilePicker
}

struct UserDetailsEditScreenViewState: BindableState {
    let userID: String
    
    var currentAvatarURL: URL?
    var selectedAvatarURL: URL?
    
    var currentDisplayName: String?
    
    var localMedia: MediaInfo?
    
    var bindings: UserDetailsEditScreenViewStateBindings
    
    var nameDidChange: Bool {
        bindings.name != currentDisplayName
    }
      
    var avatarDidChange: Bool {
        localMedia != nil || selectedAvatarURL != currentAvatarURL
    }
    
    var canSave: Bool {
        !bindings.name.isEmpty && (avatarDidChange || nameDidChange)
    }
    
    var showDeleteImageAction: Bool {
        localMedia != nil || selectedAvatarURL != nil
    }
}

struct UserDetailsEditScreenViewStateBindings {
    var name = ""
    var showMediaSheet = false
    
    var alertInfo: AlertInfo<UserDetailsEditScreenAlertType>?
}

enum UserDetailsEditScreenAlertType {
    case failedProcessingMedia
    case unsavedChanges
    case saveError
    case unknown
}

enum UserDetailsEditScreenViewAction {
    case cancel
    case save
    case presentMediaSource
    case displayCameraPicker
    case displayMediaPicker
    case removeImage
}
