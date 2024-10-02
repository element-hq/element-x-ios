//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

// periphery: ignore - markdown protocol
protocol TextBasedRoomTimelineViewProtocol {
    associatedtype TimelineItemType: TextBasedRoomTimelineItem

    var timelineItem: TimelineItemType { get }
}
