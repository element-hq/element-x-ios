//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum UserDetailsEditScreenViewModelAction {
    case displayCameraPicker
    case displayMediaPicker
    case displayFilePicker
}

struct UserDetailsEditScreenViewState: BindableState {
    let userID: String
    
    var currentAvatarURL: URL?
    var selectedAvatarURL: URL?
    
    var currentDisplayName: String?
    
    var currentPrimaryZId: String = ""
    
    var localMedia: MediaInfo?
    
    var bindings: UserDetailsEditScreenViewStateBindings
    
    var nameDidChange: Bool {
        bindings.name != currentDisplayName
    }
    
    var primaryZIdDidChange: Bool {
        bindings.primaryZId != currentPrimaryZId
    }
      
    var avatarDidChange: Bool {
        localMedia != nil || selectedAvatarURL != currentAvatarURL
    }
    
    var canSave: Bool {
        !bindings.name.isEmpty && (avatarDidChange || nameDidChange || primaryZIdDidChange)
    }
    
    var showDeleteImageAction: Bool {
        localMedia != nil || selectedAvatarURL != nil
    }
    
    var nonePrimaryZId = "None (wallet address)"
}

struct UserDetailsEditScreenViewStateBindings {
    var name = ""
    var primaryZId: String = ""
    var userZeroIds: [String] = []
    var showMediaSheet = false
    var showZIdsSheet = false
}

enum UserDetailsEditScreenViewAction {
    case save
    case presentMediaSource
    case displayCameraPicker
    case displayMediaPicker
    case removeImage
}
