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

enum RoomDetailsEditScreenViewModelAction {
    case cancel
    case saveFinished
    case displayCameraPicker
    case displayMediaPicker
}

struct RoomDetailsEditScreenViewStateBindings {
    var name: String
    var topic: String
    var showMediaSheet = false
}

struct RoomDetailsEditScreenViewState: BindableState {
    let roomID: String
    let initialAvatarURL: URL?
    let initialName: String?
    let initialTopic: String?
    let canEditAvatar: Bool
    let canEditName: Bool
    let canEditTopic: Bool
    var avatarURL: URL?
    var localMedia: MediaInfo?

    var bindings: RoomDetailsEditScreenViewStateBindings
    
    var nameDidChange: Bool {
        bindings.name != initialName
    }
    
    var topicDidChange: Bool {
        bindings.topic != initialTopic
    }
    
    var avatarDidChange: Bool {
        localMedia != nil || avatarURL != initialAvatarURL
    }

    var canSave: Bool {
        !bindings.name.isEmpty && (avatarDidChange || nameDidChange || topicDidChange)
    }
    
    var showDeleteImageAction: Bool {
        localMedia != nil || avatarURL != nil
    }
}

enum RoomDetailsEditScreenViewAction {
    case cancel
    case save
    case presentMediaSource
    case displayCameraPicker
    case displayMediaPicker
    case removeImage
}
