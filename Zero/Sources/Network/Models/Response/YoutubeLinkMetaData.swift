//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct YoutubeLinkMetaData: Codable {
    let title: String
    let authorName: String
    let authorURL: String
    let thumbnailHeight: CGFloat
    let thumbnailWidth: CGFloat
    let thumbnailURL: String
    
    enum CodingKeys: String, CodingKey {
        case title
        case authorName = "author_name"
        case authorURL = "author_url"
        case thumbnailHeight = "thumbnail_height"
        case thumbnailWidth = "thumbnail_width"
        case thumbnailURL = "thumbnail_url"
    }
}

extension YoutubeLinkMetaData {
    func toLinkPreview(_ youtubeUrl: String) -> ZLinkPreview {
        ZLinkPreview(url: youtubeUrl,
                     type: nil,
                     title: title,
                     html: nil,
                     description: authorURL,
                     providerName: "Youtube",
                     authorName: authorName,
                     thumbnail: .init(url: thumbnailURL, width: thumbnailWidth, height: thumbnailHeight))
    }
}
