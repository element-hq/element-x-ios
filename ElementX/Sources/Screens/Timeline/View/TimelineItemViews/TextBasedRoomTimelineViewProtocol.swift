//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

// periphery: ignore - markdown protocol
protocol TextBasedRoomTimelineViewProtocol {
    associatedtype TimelineItemType: TextBasedRoomTimelineItem

    var timelineItem: TimelineItemType { get }
}
