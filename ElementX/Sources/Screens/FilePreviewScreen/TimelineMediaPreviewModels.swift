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
        // Falling back to a clear image allows the presentation animation to work when
        // the item is in the event cache and just needs to be loaded from the store.
        fileHandle?.url ?? Bundle.main.url(forResource: "clear", withExtension: "png")
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
        previewItemURL.flatMap { try? FileManager.default.sizeForItem(at: $0) } ?? expectedFileSize
    }
    
    private var expectedFileSize: Double? {
        let fileSize: UInt? = switch timelineItem {
        case let audioItem as AudioRoomTimelineItem:
            audioItem.content.fileSize
        case let fileItem as FileRoomTimelineItem:
            fileItem.content.fileSize
        case let imageItem as ImageRoomTimelineItem:
            imageItem.content.imageInfo.fileSize
        case let videoItem as VideoRoomTimelineItem:
            videoItem.content.videoInfo.fileSize
        default:
            nil
        }
        
        return fileSize.map(Double.init)
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
