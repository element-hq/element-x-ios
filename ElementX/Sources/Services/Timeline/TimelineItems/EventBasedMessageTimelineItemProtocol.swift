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
    var supportsMediaCaption: Bool {
        switch contentType {
        case .audio, .file, .image, .video:
            true
        case .emote, .notice, .text, .location, .voice:
            false
        }
    }
    
    var mediaCaption: String? {
        switch contentType {
        case .audio(let content):
            content.caption
        case .file(let content):
            content.caption
        case .image(let content):
            content.caption
        case .video(let content):
            content.caption
        case .emote, .notice, .text, .location, .voice:
            nil
        }
    }
    
    var hasMediaCaption: Bool {
        mediaCaption != nil
    }
}
