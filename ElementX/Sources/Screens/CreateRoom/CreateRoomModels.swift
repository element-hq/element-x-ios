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

enum CreateRoomScreenErrorType: Error {
    case failedCreatingRoom
    case failedUploadingMedia
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
    var roomImage: Data?
    var canCreateRoom: Bool {
        !bindings.roomName.isEmpty
    }
}

struct CreateRoomViewStateBindings {
    var roomName: String
    var roomTopic: String
    var isRoomPrivate: Bool
    
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
