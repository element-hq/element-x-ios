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
struct ImagePack: Identifiable, Hashable {
    /// A custom emoticon or sticker from an image pack.
    struct Image: Hashable {
        let shortcode: String
        /// A description of the image, falling back to its shortcode.
        let body: String
        let mediaSource: MediaSourceProxy
    }
    
    let id: String
    let displayName: String?
    var attribution: String?
    /// The pack's own avatar, if it has one.
    var avatar: MediaSourceProxy?
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
            return Image(shortcode: image.shortcode, body: image.body, mediaSource: mediaSource)
        }
        avatar = rustValue.avatarUrl.flatMap { URL(string: $0) }.flatMap { try? MediaSourceProxy(url: $0, mimeType: nil) }
    }
}

// sourcery: AutoMockable
protocol ImagePackProviderProtocol {
    /// The image packs that can be used in the room.
    func imagePacks() async -> Result<[ImagePack], ImagePackProviderError>
    /// The image packs defined in the room itself.
    func roomImagePacks() async -> Result<[ImagePack], ImagePackProviderError>
}
