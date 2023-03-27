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

enum RoomMemberDetailsViewModelAction { }

struct RoomMemberDetailsViewState: BindableState {
    let userID: String
    let name: String?
    let avatarURL: URL?
    let isAccountOwner: Bool
    let permalink: URL?
    var isIgnored: Bool

    var bindings: RoomMemberDetailsViewStateBindings
}

struct RoomMemberDetailsViewStateBindings {
    var ignoreUserAlert: IgnoreUserAlertItem?
    var errorAlert: ErrorAlertItem?
}

struct IgnoreUserAlertItem: AlertItem {
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

    var viewAction: RoomMemberDetailsViewAction {
        switch action {
        case .ignore: return .ignoreConfirmed
        case .unignore: return .unignoreConfirmed
        }
    }
}

enum RoomMemberDetailsViewAction {
    case showUnblockAlert
    case showBlockAlert
    case ignoreConfirmed
    case unignoreConfirmed
    case copyUserLink
}
