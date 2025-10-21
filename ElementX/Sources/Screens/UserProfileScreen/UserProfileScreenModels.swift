//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum UserProfileScreenViewModelAction {
    case openDirectChat(roomID: String)
    case startCall(roomProxy: JoinedRoomProxyProtocol)
    case dismiss
}

struct UserProfileScreenViewState: BindableState {
    let userID: String
    let isOwnUser: Bool
    let isPresentedModally: Bool
    
    var userProfile: UserProfileProxy?
    var isVerified: Bool?
    var permalink: URL?
    var dmRoomID: String?

    var bindings: UserProfileScreenViewStateBindings
    
    var showVerifiedBadge: Bool {
        isVerified == true // We purposely show the badge on your own account for consistency with Web.
    }
}

struct UserProfileScreenViewStateBindings {
    var alertInfo: AlertInfo<UserProfileScreenAlertType>?
    var inviteConfirmationUser: UserProfileProxy?
    
    /// A media item that will be previewed with QuickLook.
    var mediaPreviewItem: MediaPreviewItem?
}

enum UserProfileScreenViewAction {
    case displayAvatar(URL)
    case openDirectChat
    case createDirectChat
    case startCall(roomID: String)
    case dismiss
}

enum UserProfileScreenAlertType: Hashable {
    case failedOpeningDirectChat
    case unknown
}
