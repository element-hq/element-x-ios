//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum RoomPollsHistoryScreenViewModelAction {
    case editPoll(pollStartID: String, poll: Poll)
}

struct RoomPollsHistoryScreenViewState: BindableState {
    let title: String
    let filters: [RoomPollsHistoryFilter] = [.ongoing, .past]
    var pollTimelineItems: [RoomPollsHistoryPollDetails] = []
    var canBackPaginate = false
    var isBackPaginating = false
    var bindings: RoomPollsHistoryScreenViewStateBindings
    
    var emptyStateMessage: String {
        switch bindings.filter {
        case .ongoing:
            L10n.screenPollsHistoryEmptyOngoing
        case .past:
            L10n.screenPollsHistoryEmptyPast
        }
    }
}

struct RoomPollsHistoryScreenViewStateBindings {
    /// Polls list filter
    var filter: RoomPollsHistoryFilter

    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<RoomPollsHistoryScreenErrorType>?
}

enum RoomPollsHistoryScreenViewAction {
    case filter(RoomPollsHistoryFilter)
    case end(pollStartID: String)
    case edit(pollStartID: String, poll: Poll)
    case sendPollResponse(pollStartID: String, optionID: String)
    case loadMore
}

enum RoomPollsHistoryFilter: Equatable {
    case ongoing
    case past
}

struct RoomPollsHistoryPollDetails {
    let timestamp: Date
    let item: PollRoomTimelineItem
}

extension RoomPollsHistoryFilter: CustomStringConvertible {
    var description: String {
        switch self {
        case .ongoing:
            L10n.screenPollsHistoryFilterOngoing
        case .past:
            L10n.screenPollsHistoryFilterPast
        }
    }
}

enum RoomPollsHistoryScreenErrorType: Hashable {
    /// A specific error message shown in an alert.
    case alert
}
