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

enum RoomPollsHistoryScreenViewModelAction {
    case editPoll(pollStartID: String, poll: Poll)
}

struct RoomPollsHistoryScreenViewState: BindableState {
    var title: String
    var filters: [RoomPollsHistoryFilter] = [.ongoing, .past]
    var pollTimelineItems: [RoomPollsHistoryPollDetails] = []
    var canBackPaginate = true
    var isInitializing = false
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
