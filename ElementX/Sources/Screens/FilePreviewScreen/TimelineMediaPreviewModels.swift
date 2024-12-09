//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import QuickLook

enum TimelineMediaPreviewViewModelAction {
    case loadedMediaFile
    case viewInTimeline
}

struct TimelineMediaPreviewViewState: BindableState {
    var previewItems: [TimelineMediaPreviewItem]
    var currentItem: TimelineMediaPreviewItem?
}

/// Wraps a media file and title to be previewed with QuickLook.
class TimelineMediaPreviewItem: NSObject, QLPreviewItem {
    private let timelineItem: EventBasedMessageTimelineItemProtocol
    var fileHandle: MediaFileHandleProxy?
    
    init(timelineItem: EventBasedMessageTimelineItemProtocol) {
        self.timelineItem = timelineItem
    }
    
    var id: TimelineItemIdentifier { timelineItem.id }
    
    // MARK: QLPreviewItem
    
    var previewItemURL: URL? {
        fileHandle?.url
    }
    
    var previewItemTitle: String? {
        switch timelineItem {
        case let audioItem as AudioRoomTimelineItem:
            audioItem.content.filename
        case let fileItem as FileRoomTimelineItem:
            fileItem.content.filename
        case let imageItem as ImageRoomTimelineItem:
            imageItem.content.filename
        case let videoItem as VideoRoomTimelineItem:
            videoItem.content.filename
        default:
            nil
        }
    }
    
    // MARK: Event details
    
    var sender: TimelineItemSender {
        timelineItem.sender
    }
    
    var timestamp: Date {
        timelineItem.timestamp
    }
    
    // MARK: Media details
    
    var mediaSource: MediaSourceProxy? {
        switch timelineItem {
        case let audioItem as AudioRoomTimelineItem:
            audioItem.content.source
        case let fileItem as FileRoomTimelineItem:
            fileItem.content.source
        case let imageItem as ImageRoomTimelineItem:
            imageItem.content.imageInfo.source
        case let videoItem as VideoRoomTimelineItem:
            videoItem.content.videoInfo.source
        default:
            nil
        }
    }
    
    var thumbnailMediaSource: MediaSourceProxy? {
        switch timelineItem {
        case let fileItem as FileRoomTimelineItem:
            fileItem.content.thumbnailSource
        case let imageItem as ImageRoomTimelineItem:
            imageItem.content.thumbnailInfo?.source
        case let videoItem as VideoRoomTimelineItem:
            videoItem.content.thumbnailInfo?.source
        default:
            nil
        }
    }
    
    var filename: String? {
        switch timelineItem {
        case let audioItem as AudioRoomTimelineItem:
            audioItem.content.filename
        case let fileItem as FileRoomTimelineItem:
            fileItem.content.filename
        case let imageItem as ImageRoomTimelineItem:
            imageItem.content.filename
        case let videoItem as VideoRoomTimelineItem:
            videoItem.content.filename
        default:
            nil
        }
    }
    
    var fileSize: Double? {
        previewItemURL.flatMap { try? FileManager.default.sizeForItem(at: $0) }
    }
    
    var caption: String? {
        timelineItem.mediaCaption
    }
    
    var contentType: String? {
        switch timelineItem {
        case let audioItem as AudioRoomTimelineItem:
            audioItem.content.contentType?.localizedDescription
        case let fileItem as FileRoomTimelineItem:
            fileItem.content.contentType?.localizedDescription
        case let imageItem as ImageRoomTimelineItem:
            imageItem.content.contentType?.localizedDescription
        case let videoItem as VideoRoomTimelineItem:
            videoItem.content.contentType?.localizedDescription
        default:
            nil
        }
    }
    
    var blurhash: String? {
        switch timelineItem {
        case let imageItem as ImageRoomTimelineItem:
            imageItem.content.blurhash
        case let videoItem as VideoRoomTimelineItem:
            videoItem.content.blurhash
        default:
            nil
        }
    }
}

enum TimelineMediaPreviewViewAction {
    case viewInTimeline
    case redact
}
