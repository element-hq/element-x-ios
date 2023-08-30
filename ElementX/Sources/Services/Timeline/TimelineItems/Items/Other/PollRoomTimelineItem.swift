//
// Copyright 2023 New Vector Ltd
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

struct PollRoomTimelineItem: Equatable, EventBasedTimelineItemProtocol {
    let id: TimelineItemIdentifier
    let poll: Poll
    let body: String
    let timestamp: String
    let isOutgoing: Bool
    let isEditable: Bool
    let sender: TimelineItemSender
    var properties: RoomTimelineItemProperties
}

struct Poll: Equatable {
    /// The "m.poll.start" event id
    let id: String
    let question: String
    let kind: Kind
    let maxSelections: Int
    let options: [Option]
    let votes: [String: [String]]
    let endDate: Date?

    var hasEnded: Bool {
        endDate != nil
    }

    enum Kind: Equatable {
        case disclosed
        case undisclosed
    }

    struct Option: Equatable {
        let id: String
        let text: String
        let votes: Int
        let allVotes: Int
        let isSelected: Bool
        let isWinning: Bool
    }
}
