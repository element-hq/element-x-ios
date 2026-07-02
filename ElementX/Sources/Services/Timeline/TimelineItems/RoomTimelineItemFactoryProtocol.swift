//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

nonisolated protocol RoomTimelineItemFactoryProtocol: Sendable {
    func buildTimelineItem(for eventItemProxy: EventTimelineItemProxy, isDM: Bool) -> RoomTimelineItemProtocol?
    func buildTimelineItemReply(_ details: MatrixRustSDK.InReplyToDetails) -> TimelineItemReply
    func buildMessageTimelineItemContent(messageType: MessageType?, senderID: String, senderDisplayName: String?) -> EventBasedMessageTimelineItemContentType
}
