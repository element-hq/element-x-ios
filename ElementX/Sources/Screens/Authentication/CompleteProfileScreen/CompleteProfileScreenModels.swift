//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

// MARK: - Coordinator

enum CompleteProfileScreenCoordinatorAction {
    case signedIn(UserSessionProtocol)
}

enum CompleteProfileScreenViewModelAction {
    case displayCameraPicker
    case displayMediaPicker
    case signedIn(UserSessionProtocol)
}

struct CompleteProfileScreenViewState: BindableState {
    let inviteCode: String
    
    var currentAvatarURL: URL?
    var selectedAvatarURL: URL?
    
    var localMedia: MediaInfo?
    
    var bindings = CompleteProfileScreenBindings()
    
    var hasValidInput: Bool {
        !bindings.name.isEmpty && ValidationUtil.shared.isValidUserDisplayName(bindings.name)
    }
    
    var canSubmit: Bool {
        hasValidInput
    }
}

struct CompleteProfileScreenBindings {
    var name = ""
    var showMediaSheet = false
}

enum CompleteProfileScreenViewAction {
    case presentMediaSource
    case displayCameraPicker
    case displayMediaPicker
    case completeProfile
}
