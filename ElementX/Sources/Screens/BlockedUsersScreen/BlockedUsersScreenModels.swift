//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

struct BlockedUsersScreenViewState: BindableState {
    var blockedUsers: [UserProfileProxy]
    var processingUserID: String?
    
    var bindings = BlockedUsersScreenViewStateBindings()
}

struct BlockedUsersScreenViewStateBindings {
    var alertInfo: AlertInfo<BlockedUsersScreenViewStateAlertType>?
}

enum BlockedUsersScreenViewAction {
    case unblockUser(UserProfileProxy)
}

enum BlockedUsersScreenViewStateAlertType: Hashable {
    case unblock
    case error
}
