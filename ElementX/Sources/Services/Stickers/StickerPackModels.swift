//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// MARK: - Sticker Pack

struct StickerPack: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let stickers: [Sticker]
}

// MARK: - Sticker

struct Sticker: Codable, Identifiable, Equatable {
    let id: String
    let body: String
    let url: String // MXC URL
    let msgtype: String? // Should be "m.sticker"
    let info: StickerInfo

    enum CodingKeys: String, CodingKey {
        case id, body, url, msgtype, info
    }
}

// MARK: - Sticker Info

struct StickerInfo: Codable, Equatable {
    let w: Int
    let h: Int
    let size: Int
    let mimetype: String
    let thumbnailUrl: String?
    let thumbnailInfo: ThumbnailInfo?

    enum CodingKeys: String, CodingKey {
        case w, h, size, mimetype
        case thumbnailUrl = "thumbnail_url"
        case thumbnailInfo = "thumbnail_info"
    }
}

// MARK: - Thumbnail Info

struct ThumbnailInfo: Codable, Equatable {
    let w: Int
    let h: Int
    let size: Int
    let mimetype: String
}
