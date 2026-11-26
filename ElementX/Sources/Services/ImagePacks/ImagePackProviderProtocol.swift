//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum ImagePackProviderError: Error {
    case sdkError(Error)
}

/// A pack of custom images (emoticons and/or stickers) that can be used in a room.
struct ImagePack: Identifiable {
    /// A custom emoticon or sticker from an image pack.
    struct Image: Hashable {
        let shortcode: String
        /// A description of the image, falling back to its shortcode.
        let body: String
        let mediaSource: MediaSourceProxy
        /// Metadata about the image, sent along with it as a sticker.
        var info: ImageInfo?
        
        // `ImageInfo` isn't `Hashable`, and only describes the media anyway.
        static func == (lhs: Image, rhs: Image) -> Bool {
            lhs.shortcode == rhs.shortcode && lhs.body == rhs.body && lhs.mediaSource == rhs.mediaSource
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(shortcode)
            hasher.combine(body)
            hasher.combine(mediaSource)
        }
    }
    
    let id: String
    let displayName: String?
    /// Credits the original author or source of the pack.
    var attribution: String?
    let isEmoticonPack: Bool
    let isStickerPack: Bool
    let images: [Image]
}

extension ImagePack {
    init(rustValue: MatrixRustSDK.ImagePack) {
        id = "\(rustValue.roomId)-\(rustValue.stateKey)"
        displayName = rustValue.displayName
        attribution = rustValue.attribution
        isEmoticonPack = rustValue.isEmoticonPack
        isStickerPack = rustValue.isStickerPack
        images = rustValue.images.compactMap { image in
            guard let url = URL(string: image.url),
                  let mediaSource = try? MediaSourceProxy(url: url, mimeType: image.info?.mimetype) else {
                return nil
            }
            return Image(shortcode: image.shortcode, body: image.body, mediaSource: mediaSource, info: image.info)
        }
    }
}

// sourcery: AutoMockable
protocol ImagePackProviderProtocol {
    /// The image packs that can be used in the room.
    func imagePacks() async -> Result<[ImagePack], ImagePackProviderError>
}
