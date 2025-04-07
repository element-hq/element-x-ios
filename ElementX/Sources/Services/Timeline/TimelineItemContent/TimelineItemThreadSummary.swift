//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

struct TimelineItemThreadSummary: Hashable {
    let senderID: String
    let sender: TimelineItemSender?
    let lastMessageContent: TimelineEventContent
}
