//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct TimelineStartRoomTimelineItem: DecorationTimelineItemProtocol, Equatable {
    let id: TimelineItemIdentifier = .virtual(uniqueID: .init(id: UUID().uuidString))
    let name: String?
}
