//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

struct TimelineStartRoomTimelineItem: DecorationTimelineItemProtocol, Equatable {
    let id = TimelineItemIdentifier(timelineID: UUID().uuidString)
    let name: String?
}
