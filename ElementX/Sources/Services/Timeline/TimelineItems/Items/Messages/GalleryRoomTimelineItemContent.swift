//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UniformTypeIdentifiers

nonisolated struct GalleryRoomTimelineItemContent: Hashable {
    let body: String
    var caption: String?
    var formattedCaption: AttributedString?
    /// The original textual representation of the formatted caption directly from the event (usually HTML code)
    var formattedCaptionHTMLString: String?
    let items: [GalleryItem]
}

/// Identifies a single attachment within a gallery message.
nonisolated struct GalleryItemID: Hashable {
    /// The unique ID of the parent gallery timeline item.
    let timelineItemUniqueID: TimelineItemIdentifier.UniqueID
    /// The item's position within the gallery.
    let mediaIndex: Int
}

/// A single attachment of a gallery message. The SDK hands back the same content types it uses for
/// individual messages, so we reuse them here rather than duplicating their fields.
nonisolated enum GalleryItem: Hashable, Identifiable {
    case image(id: GalleryItemID, ImageRoomTimelineItemContent)
    case video(id: GalleryItemID, VideoRoomTimelineItemContent)
    case audio(id: GalleryItemID, AudioRoomTimelineItemContent)
    case file(id: GalleryItemID, FileRoomTimelineItemContent)
    /// An item of an unknown type. It has no media source, so there's nothing to preview.
    case other(id: GalleryItemID, filename: String)
    
    var id: GalleryItemID {
        switch self {
        case .image(let id, _), .video(let id, _), .audio(let id, _), .file(let id, _), .other(let id, _):
            id
        }
    }
    
    var isImage: Bool {
        if case .image = self {
            true
        } else {
            false
        }
    }
    
    var isVideo: Bool {
        if case .video = self {
            true
        } else {
            false
        }
    }
    
    var isAudio: Bool {
        if case .audio = self {
            true
        } else {
            false
        }
    }
    
    var isFile: Bool {
        if case .file = self {
            true
        } else {
            false
        }
    }
    
    var filename: String {
        switch self {
        case .image(_, let content): content.filename
        case .video(_, let content): content.filename
        case .audio(_, let content): content.filename
        case .file(_, let content): content.filename
        case .other(_, let filename): filename
        }
    }
    
    var mediaSource: MediaSourceProxy? {
        switch self {
        case .image(_, let content): content.imageInfo.source
        case .video(_, let content): content.videoInfo.source
        case .audio(_, let content): content.source
        case .file(_, let content): content.source
        case .other: nil
        }
    }
    
    var thumbnailSource: MediaSourceProxy? {
        switch self {
        case .image(_, let content): content.thumbnailInfo?.source
        case .video(_, let content): content.thumbnailInfo?.source
        case .file(_, let content): content.thumbnailSource
        case .audio, .other: nil
        }
    }
    
    var size: CGSize? {
        switch self {
        case .image(_, let content): content.imageInfo.size
        case .video(_, let content): content.videoInfo.size
        case .audio, .file, .other: nil
        }
    }
    
    var blurhash: String? {
        switch self {
        case .image(_, let content): content.blurhash
        case .video(_, let content): content.blurhash
        case .audio, .file, .other: nil
        }
    }
    
    var duration: TimeInterval? {
        switch self {
        case .video(_, let content): content.videoInfo.duration
        case .audio(_, let content): content.duration
        case .image, .file, .other: nil
        }
    }
    
    var contentType: UTType? {
        switch self {
        case .image(_, let content): content.contentType
        case .video(_, let content): content.contentType
        case .audio(_, let content): content.contentType
        case .file(_, let content): content.contentType
        case .other: nil
        }
    }
    
    /// Whether the item can render a visible thumbnail. Images always can (their media source
    /// IS the image); for everything else we need an explicit thumbnail source.
    var hasThumbnail: Bool {
        isImage || thumbnailSource != nil
    }
}
