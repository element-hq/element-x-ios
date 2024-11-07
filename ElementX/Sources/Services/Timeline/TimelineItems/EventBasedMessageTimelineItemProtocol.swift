//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum EventBasedMessageTimelineItemContentType: Hashable {
    case audio(AudioRoomTimelineItemContent)
    case emote(EmoteRoomTimelineItemContent)
    case file(FileRoomTimelineItemContent)
    case image(ImageRoomTimelineItemContent)
    case notice(NoticeRoomTimelineItemContent)
    case text(TextRoomTimelineItemContent)
    case video(VideoRoomTimelineItemContent)
    case location(LocationRoomTimelineItemContent)
    case voice(AudioRoomTimelineItemContent)
}

protocol EventBasedMessageTimelineItemProtocol: EventBasedTimelineItemProtocol {
    var replyDetails: TimelineItemReplyDetails? { get }
    var contentType: EventBasedMessageTimelineItemContentType { get }
    var isThreaded: Bool { get }
}

extension EventBasedMessageTimelineItemProtocol {
    var hasMediaCaption: Bool {
        switch contentType {
        case .audio(let content):
            content.caption != nil
        case .file(let content):
            content.caption != nil
        case .image(let content):
            content.caption != nil
        case .video(let content):
            content.caption != nil
        case .emote, .notice, .text, .location, .voice:
            false
        }
    }
}
