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
    let name: String
    let avatarURL: URL?
    let isAccountOwner: Bool
    let permalink: URL?
    var isIgnored: Bool
    var isIgnoreLoading = false

    var bindings: RoomMemberDetailsViewStateBindings
}

struct RoomMemberDetailsViewStateBindings {
    var blockUserAlertItem: BlockUserAlertItem?
    var errorAlert: ErrorAlertItem?
}

struct BlockUserAlertItem: AlertItem {
    enum Action {
        case block
        case unblock
    }

    let action: Action
    let cancelTitle = ElementL10n.actionCancel

    var title: String {
        switch action {
        case .block: return ElementL10n.roomMemberDetailsBlockUser
        case .unblock: return ElementL10n.roomMemberDetailsUnblockUser
        }
    }

    var confirmationTitle: String {
        switch action {
        case .block: return ElementL10n.roomMemberDetailsBlockAlertAction
        case .unblock: return ElementL10n.roomMemberDetailsUnblockAlertAction
        }
    }

    var description: String {
        switch action {
        case .block: return ElementL10n.roomMemberDetailsBlockAlertDescription
        case .unblock: return ElementL10n.roomMemberDetailsUnblockAlertDescription
        }
    }

    var viewAction: RoomMemberDetailsViewAction {
        switch action {
        case .block: return .blockConfirmed
        case .unblock: return .unblockConfirmed
        }
    }
}

enum RoomMemberDetailsViewAction {
    case unblockTapped
    case blockTapped
    case blockConfirmed
    case unblockConfirmed
    case copyUserLink
}
