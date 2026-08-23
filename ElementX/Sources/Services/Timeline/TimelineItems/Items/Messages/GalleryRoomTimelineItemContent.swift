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
    
    /// The items of the given types, paired with their position in the gallery so that they remain
    /// identifiable once separated from it. Items of an unknown type are never included.
    /// - Parameter allowedTypes: The types to include, or `nil` to include them all.
    func items(matching allowedTypes: [TimelineAllowedGalleryItemType]?) -> [(mediaIndex: Int, item: GalleryItem)] {
        items.enumerated().compactMap { mediaIndex, item in
            guard let allowedItemType = item.allowedItemType,
                  allowedTypes?.contains(allowedItemType) ?? true else {
                return nil
            }
            
            return (mediaIndex, item)
        }
    }
}

/// Identifies a single attachment within a gallery message.
nonisolated struct GalleryItemID: Hashable {
    /// The identifier of the parent gallery timeline item. The whole identifier is used so that an
    /// attachment remains identifiable across timelines, where the unique ID alone wouldn't be.
    let timelineItemID: TimelineItemIdentifier
    /// The item's position within the gallery.
    let mediaIndex: Int
    
    // Identity across timelines: the unique ID is per-timeline (the room timeline and the media
    // timeline built for the viewer number the same event differently), the event/transaction ID
    // is not. Synthesised equality over the whole identifier made the viewer unable to match a
    // tapped gallery against the media timeline's copy ("Ignoring update: unable to find existing
    // preview items range"). Fall back to the whole identifier only for virtual items.
    static func == (lhs: GalleryItemID, rhs: GalleryItemID) -> Bool {
        guard lhs.mediaIndex == rhs.mediaIndex else { return false }
        switch (lhs.timelineItemID.eventOrTransactionID, rhs.timelineItemID.eventOrTransactionID) {
        case (let lhsID?, let rhsID?): return lhsID == rhsID
        case (nil, nil): return lhs.timelineItemID == rhs.timelineItemID
        default: return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(mediaIndex)
        hasher.combine(timelineItemID.eventOrTransactionID)
    }
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
    
    var fileSize: UInt? {
        switch self {
        case .image(_, let content): content.imageInfo.fileSize
        case .video(_, let content): content.videoInfo.fileSize
        case .audio(_, let content): content.fileSize
        case .file(_, let content): content.fileSize
        case .other: nil
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
    
    /// The type this attachment is allowed by, or `nil` when its type is unknown.
    var allowedItemType: TimelineAllowedGalleryItemType? {
        switch self {
        case .image: .image
        case .video: .video
        case .audio: .audio
        case .file: .file
        case .other: nil
        }
    }
}

// MARK: - Mocks

nonisolated extension GalleryItemID {
    static func mock(_ index: Int) -> GalleryItemID {
        .init(timelineItemID: .randomEvent, mediaIndex: index)
    }
}

nonisolated extension GalleryItem {
    static func mockImage(index: Int = 0,
                          filename: String = "image.jpg",
                          source: MediaSourceProxy = ImageInfoProxy.mockImage.source,
                          thumbnailSource: MediaSourceProxy? = ImageInfoProxy.mockThumbnail.source,
                          blurhash: String? = "L%KUc%kqS$RP?Ks,WEf8OlrqaekW",
                          contentType: UTType? = .jpeg) -> GalleryItem {
        let imageInfo = ImageInfoProxy(source: source, width: 1920, height: 1080, mimeType: nil, fileSize: nil)
        let thumbnailInfo = thumbnailSource.map { ImageInfoProxy(source: $0, width: 1920, height: 1080, mimeType: nil, fileSize: nil) }
        return .image(id: .mock(index),
                      .init(filename: filename, imageInfo: imageInfo, thumbnailInfo: thumbnailInfo, blurhash: blurhash, contentType: contentType))
    }
    
    static func mockVideo(index: Int = 0,
                          filename: String = "clip.mp4",
                          thumbnailSource: MediaSourceProxy? = ImageInfoProxy.mockVideoThumbnail.source,
                          duration: TimeInterval = 42,
                          blurhash: String? = "L%KUc%kqS$RP?Ks,WEf8OlrqaekW",
                          contentType: UTType? = .mpeg4Movie) -> GalleryItem {
        let thumbnailInfo = thumbnailSource.map { ImageInfoProxy(source: $0, width: 1920, height: 1080, mimeType: nil, fileSize: nil) }
        return .video(id: .mock(index),
                      .init(filename: filename, videoInfo: .mockVideo(duration: duration), thumbnailInfo: thumbnailInfo, blurhash: blurhash, contentType: contentType))
    }
    
    static func mockFile(index: Int = 0,
                         filename: String = "document.pdf",
                         source: MediaSourceProxy? = nil,
                         thumbnailSource: MediaSourceProxy? = nil,
                         contentType: UTType? = .pdf) -> GalleryItem {
        .file(id: .mock(index),
              .init(filename: filename, source: source, fileSize: nil, thumbnailSource: thumbnailSource, contentType: contentType))
    }
    
    static func mockAudio(index: Int = 0,
                          filename: String = "audio.m4a",
                          source: MediaSourceProxy? = nil,
                          duration: TimeInterval = 65,
                          contentType: UTType? = .mpeg4Audio) -> GalleryItem {
        .audio(id: .mock(index),
               .init(filename: filename, duration: duration, waveform: nil, source: source, fileSize: nil, contentType: contentType))
    }
}
