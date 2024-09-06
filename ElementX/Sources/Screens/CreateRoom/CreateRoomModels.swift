//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum CreateRoomScreenErrorType: Error {
    case failedCreatingRoom
    case failedUploadingMedia
    case fileTooLarge
    case mediaFileError
    case unknown
}

enum CreateRoomViewModelAction {
    case openRoom(withIdentifier: String)
    case deselectUser(UserProfileProxy)
    case updateDetails(CreateRoomFlowParameters)
    case displayMediaPicker
    case displayCameraPicker
    case removeImage
}

struct CreateRoomViewState: BindableState {
    var selectedUsers: [UserProfileProxy]
    var bindings: CreateRoomViewStateBindings
    var avatarURL: URL?
    var canCreateRoom: Bool {
        !bindings.roomName.isEmpty
    }
}

struct CreateRoomViewStateBindings {
    var roomName: String
    var roomTopic: String
    var isRoomPrivate: Bool
    var showAttachmentConfirmationDialog = false
    
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<CreateRoomScreenErrorType>?
}

enum CreateRoomViewAction {
    case createRoom
    case deselectUser(UserProfileProxy)
    case displayCameraPicker
    case displayMediaPicker
    case removeImage
}
