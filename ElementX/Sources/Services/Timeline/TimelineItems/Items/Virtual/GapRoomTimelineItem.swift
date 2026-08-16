//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// A gap in the timeline: a range of events that haven't been fetched (yet),
/// rendered as a small loading indicator and resolved when it becomes visible.
nonisolated struct GapRoomTimelineItem: DecorationTimelineItemProtocol, Equatable {
    let id: TimelineItemIdentifier
    
    /// The prev-batch token used to resolve this gap.
    let prevToken: String
}
