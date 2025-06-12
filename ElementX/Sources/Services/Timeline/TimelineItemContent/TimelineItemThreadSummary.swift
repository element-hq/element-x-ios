//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

enum TimelineItemThreadSummary: Hashable {
    case notLoaded
    case loading
    case loaded(senderID: String, sender: TimelineItemSender, latestEventContent: TimelineEventContent, numberOfReplies: Int)
    case error(message: String)
}
