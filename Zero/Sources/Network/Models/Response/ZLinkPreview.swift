//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct ZLinkPreview: Codable, Hashable {
    let url: String
    let type: String?
    let title: String?
    let html: String?
    let description: String?
    let providerName: String?
    let authorName: String?
    let thumbnail: Thumbnail?
}

struct Thumbnail: Codable, Hashable {
    let url: String
    let width: CGFloat
    let height: CGFloat
}

extension ZLinkPreview {
    var thumbnailURL: URL? {
        guard let thumbnailURLString = thumbnail?.url as? String else {
            return nil
        }
        return URL(string: thumbnailURLString)
    }
    
    var linkURL: URL? {
        return URL(string: url)
    }
}

extension Thumbnail {
    var aspectRatio: CGFloat {
        width / height
    }
}
