//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
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

nonisolated struct GalleryItem: Hashable, Identifiable {
    enum Kind: Hashable {
        case image
        case video
        case audio
        case file
        case other
    }
    
    let id: String
    let filename: String
    let kind: Kind
    let mediaSource: MediaSourceProxy?
    let thumbnailSource: MediaSourceProxy?
    let size: CGSize?
    let blurhash: String?
    let duration: TimeInterval?
    let contentType: UTType?
    
    var isImage: Bool {
        kind == .image
    }
    
    var isVideo: Bool {
        kind == .video
    }
    
    var isAudio: Bool {
        kind == .audio
    }
    
    var isFile: Bool {
        kind == .file
    }
    
    /// Whether the item can render a visible thumbnail. Images always can (their `mediaSource`
    /// IS the image); for everything else we need an explicit `thumbnailSource`.
    var hasThumbnail: Bool {
        isImage || thumbnailSource != nil
    }
}
