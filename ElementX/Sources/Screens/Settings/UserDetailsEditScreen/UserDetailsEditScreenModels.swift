//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
}

enum UserDetailsEditScreenViewAction {
    case save
    case presentMediaSource
    case displayCameraPicker
    case displayMediaPicker
    case removeImage
}
