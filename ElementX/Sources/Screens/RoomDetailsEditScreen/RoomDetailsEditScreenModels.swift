//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum RoomDetailsEditScreenViewModelAction {
    case cancel
    case saveFinished
    case displayCameraPicker
    case displayMediaPicker
}

struct RoomDetailsEditScreenViewState: BindableState {
    let roomID: String
    let isSpace: Bool
    let initialAvatarURL: URL?
    let initialName: String
    let initialTopic: String
    var canEditAvatar = false
    var canEditName = false
    var canEditTopic = false
    var avatarURL: URL?
    var localMedia: MediaInfo?

    var bindings: RoomDetailsEditScreenViewStateBindings
    
    var nameDidChange: Bool {
        bindings.name != initialName
    }
    
    /// The string shown for the room's name when it can't be edited.
    var nameRowTitle: String {
        bindings.name.isEmpty ? L10n.commonName : bindings.name
    }
    
    /// The string shown for the room's topic when it can't be edited.
    var topicRowTitle: String {
        bindings.topic.isEmpty ? L10n.commonTopic : bindings.topic
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

struct RoomDetailsEditScreenViewStateBindings {
    var name: String
    var topic: String
    var showMediaSheet = false
    
    var alertInfo: AlertInfo<RoomDetailsEditScreenAlertType>?
}

enum RoomDetailsEditScreenAlertType {
    case failedProcessingMedia
    case unsavedChanges
    case saveError
    case unknown
}

enum RoomDetailsEditScreenViewAction {
    case cancel
    case save
    case presentMediaSource
    case displayCameraPicker
    case displayMediaPicker
    case removeImage
}
