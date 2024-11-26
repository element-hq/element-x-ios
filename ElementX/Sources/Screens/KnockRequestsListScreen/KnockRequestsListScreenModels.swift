//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum KnockRequestsListScreenViewModelAction { }

struct KnockRequestsListScreenViewState: BindableState {
    // TODO: Not sure yet how we will fetch this, this is just for testing purposes
    var requests: [KnockRequestCellInfo] = [.init(id: "@alice:matrix.org", displayName: "Alice", avatarUrl: nil, timestamp: "Now", reason: "Hello")]
    // If you are in this view one of these must have been true so by default we assume all of them to be true
    var canAccept = true
    var canDecline = true
    var canBan = true
    var isKnockableRoom = true
    
    // If all the permissions are denied or the join rule changes while we are in the view
    // we want to stop displaying any request
    var shouldDisplayRequests: Bool {
        !requests.isEmpty && isKnockableRoom && (canAccept || canDecline || canBan)
    }
    
    var bindings = KnockRequestsListStateBindings()
}

struct KnockRequestsListStateBindings {
    var alertInfo: AlertInfo<KnockRequestsListAlertType>?
}

enum KnockRequestsListAlertType {
    case acceptAllRequests
    case declineRequest
    case declineAndBan
}

enum KnockRequestsListScreenViewAction {
    case acceptAllRequests
    case acceptRequest(userID: String)
    case declineRequest(userID: String)
    case ban(userID: String)
}
