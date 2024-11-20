//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum KnockRequestsListScreenViewModelAction { }

struct KnockRequestsListScreenViewState: BindableState {
    var requests: [KnockRequestCellInfo] = []
    var canAccept = false
    var canDecline = false
    var canBan = false
}

enum KnockRequestsListScreenViewAction {
    case acceptAllRequests
    case acceptRequest(userID: String)
    case declineRequest(userID: String)
    case ban(userID: String)
}
