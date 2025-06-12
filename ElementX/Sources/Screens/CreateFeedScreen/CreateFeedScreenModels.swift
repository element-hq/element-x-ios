//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

struct CreateFeedScreenViewState: BindableState {
    let userID: String
    var userAvatarURL: URL?
    
    var showCloseButton: Bool = true
    
    var bindings: CreateFeedScreenViewStateBindings
}

struct CreateFeedScreenViewStateBindings {
    var feedText: String = ""
    var alertInfo: AlertInfo<UUID>?
    var selectedFeedMediaUrl: URL?
}

enum CreateFeedScreenViewModelAction {
    case newFeedPosted
    case dismissPost
    case attachMedia(FeedMediaSelectedProtocol)
}

enum CreateFeedScreenViewAction {
    case createPost
    case dismissPost
    case attachMedia
    case deleteMedia
}
