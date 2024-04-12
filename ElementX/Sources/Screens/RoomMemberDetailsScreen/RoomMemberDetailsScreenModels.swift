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

enum RoomMemberDetailsScreenViewModelAction {
    case openUserProfile
    case openDirectChat(displayName: String?)
}

struct RoomMemberDetailsScreenViewState: BindableState {
    let userID: String
    var memberDetails: RoomMemberDetails?
    var isOwnMemberDetails = false
    var isProcessingIgnoreRequest = false

    var bindings: RoomMemberDetailsScreenViewStateBindings
}

struct RoomMemberDetailsScreenViewStateBindings {
    struct IgnoreUserAlertItem: AlertProtocol, Equatable {
        enum Action {
            case ignore
            case unignore
        }

        let action: Action
        let cancelTitle = L10n.actionCancel

        var title: String {
            switch action {
            case .ignore: return L10n.screenRoomMemberDetailsBlockUser
            case .unignore: return L10n.screenRoomMemberDetailsUnblockUser
            }
        }

        var confirmationTitle: String {
            switch action {
            case .ignore: return L10n.screenRoomMemberDetailsBlockAlertAction
            case .unignore: return L10n.screenRoomMemberDetailsUnblockAlertAction
            }
        }

        var description: String {
            switch action {
            case .ignore: return L10n.screenRoomMemberDetailsBlockAlertDescription
            case .unignore: return L10n.screenRoomMemberDetailsUnblockAlertDescription
            }
        }

        var viewAction: RoomMemberDetailsScreenViewAction {
            switch action {
            case .ignore: return .ignoreConfirmed
            case .unignore: return .unignoreConfirmed
            }
        }
    }
    
    var ignoreUserAlert: IgnoreUserAlertItem?
    var alertInfo: AlertInfo<RoomMemberDetailsScreenError>?
    
    /// A media item that will be previewed with QuickLook.
    var mediaPreviewItem: MediaPreviewItem?
}

enum RoomMemberDetailsScreenViewAction {
    case showUnignoreAlert
    case showIgnoreAlert
    case ignoreConfirmed
    case unignoreConfirmed
    case displayAvatar
    case openDirectChat
}

enum RoomMemberDetailsScreenError: Hashable {
    case unknown
}
