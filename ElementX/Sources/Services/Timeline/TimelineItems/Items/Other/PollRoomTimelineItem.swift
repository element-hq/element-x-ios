//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

struct PollRoomTimelineItem: Equatable, EventBasedTimelineItemProtocol {
    let id: TimelineItemIdentifier
    let poll: Poll
    let body: String
    let timestamp: String
    let isOutgoing: Bool
    let isEditable: Bool
    let canBeRepliedTo: Bool
    let sender: TimelineItemSender
    var properties: RoomTimelineItemProperties
}

struct Poll: Hashable {
    let question: String
    let kind: Kind
    let maxSelections: Int
    let options: [Option]
    let votes: [String: [String]]
    let endDate: Date?
    /// Whether the poll has been created by the account owner
    let createdByAccountOwner: Bool

    var hasEnded: Bool {
        endDate != nil
    }

    enum Kind: Hashable {
        case disclosed
        case undisclosed
    }

    struct Option: Hashable {
        let id: String
        let text: String
        let votes: Int
        let allVotes: Int
        let isSelected: Bool
        let isWinning: Bool
    }
}
