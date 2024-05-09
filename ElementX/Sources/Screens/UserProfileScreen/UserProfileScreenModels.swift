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
