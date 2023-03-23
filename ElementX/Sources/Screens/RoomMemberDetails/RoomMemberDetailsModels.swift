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

    var bindings: RoomMemberDetailsViewStateBindings
}

struct RoomMemberDetailsViewStateBindings {
    var blockUserAlertItem: BlockUserAlertItem?
}

struct BlockUserAlertItem: AlertItem {
    // TODO: Localise strings (for the first you can reuse the one in the screen)
    let title = "Block User"
    let confirmationTitle = "Block"
    let cancelTitle = ElementL10n.actionCancel
    let description = "Blocked users will not be able to send you messages and all message by them will be hidden. You can reverse this action anytime."
}

enum RoomMemberDetailsViewAction {
    case ignoreTapped
    case ignoreConfirmed
    case copyUserLink
}
