//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum KnockRequestsListScreenViewModelAction { }

struct KnockRequestsListScreenViewState: BindableState {
    var requestsState: KnockRequestsListState = .loading
    
    var displayedRequests: [KnockRequestCellInfo] {
        guard case let .loaded(requests) = requestsState else {
            return []
        }
        return requests.filter { !handledEventIDs.contains($0.id) }
    }
    
    var isLoading: Bool {
        switch requestsState {
        case .loading:
            true
        default:
            false
        }
    }

    // If you are in this view one of these must have been true so by default we assume all of them to be true
    var canAccept = true
    var canDecline = true
    var canBan = true
    var isKnockableRoom = true
    var handledEventIDs: Set<String> = []
    
    // If all the permissions are denied or the join rule changes while we are in the view
    // we want to stop displaying any request
    var shouldDisplayRequests: Bool {
        !displayedRequests.isEmpty && isKnockableRoom && (canAccept || canDecline || canBan)
    }
    
    var shouldDisplayAcceptAllButton: Bool {
        !isLoading && shouldDisplayRequests && displayedRequests.count > 1
    }
    
    var shouldDisplayEmptyView: Bool {
        !isLoading && !shouldDisplayRequests
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
    case acceptAllFailed
    case acceptFailed
    case declineFailed
}

enum KnockRequestsListScreenViewAction {
    case acceptAllRequests
    case acceptRequest(eventID: String)
    case declineRequest(eventID: String)
    case ban(eventID: String)
}

enum KnockRequestsListState: Equatable {
    case loading
    case loaded([KnockRequestCellInfo])
    
    init(from state: KnockRequestsState) {
        switch state {
        case .loading:
            self = .loading
        case .loaded(let requests):
            self = .loaded(requests.map(KnockRequestCellInfo.init))
        }
    }
}

private extension KnockRequestCellInfo {
    init(from proxy: KnockRequestProxyProtocol) {
        self.init(eventID: proxy.eventID,
                  userID: proxy.userID,
                  displayName: proxy.displayName,
                  avatarURL: proxy.avatarURL,
                  timestamp: proxy.formattedTimestamp,
                  reason: proxy.reason)
    }
}
