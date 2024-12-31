//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

import MatrixRustSDK

@MainActor
protocol RoomTimelineItemFactoryProtocol {
    func buildTimelineItem(for eventItemProxy: EventTimelineItemProxy, isDM: Bool) -> RoomTimelineItemProtocol?
    func buildReply(details: InReplyToDetails) -> TimelineItemReply
}
