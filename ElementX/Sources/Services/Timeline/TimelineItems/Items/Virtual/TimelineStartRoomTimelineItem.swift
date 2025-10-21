//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct TimelineStartRoomTimelineItem: DecorationTimelineItemProtocol, Equatable {
    // Using a static identifier makes the animations consistent in SwiftUI
    let id: TimelineItemIdentifier = .virtual(uniqueID: .init("TimelineStart"))
    let name: String?
}
