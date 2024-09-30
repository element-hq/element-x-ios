//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum UserProfileScreenViewModelAction {
    case openDirectChat(roomID: String)
    case startCall(roomID: String)
    case dismiss
}

struct UserProfileScreenViewState: BindableState {
    let userID: String
    let isOwnUser: Bool
    let isPresentedModally: Bool
    
    var userProfile: UserProfileProxy?
    var permalink: URL?
    var dmRoomID: String?

    var bindings: UserProfileScreenViewStateBindings
}

struct UserProfileScreenViewStateBindings {
    var alertInfo: AlertInfo<UserProfileScreenError>?
    
    /// A media item that will be previewed with QuickLook.
    var mediaPreviewItem: MediaPreviewItem?
}

enum UserProfileScreenViewAction {
    case displayAvatar
    case openDirectChat
    case startCall(roomID: String)
    case dismiss
}

enum UserProfileScreenError: Hashable {
    case failedOpeningDirectChat
    case unknown
}
