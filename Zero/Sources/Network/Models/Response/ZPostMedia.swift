//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct ZPostMedia: Codable {
    let media: ZPostMediaInfo
    let signedUrl: String
}

struct ZPostMediaInfo: Codable {
    let id: String
    let userId: String?
    let centralizedStorageKey: String?
    let mimeType: String?
    let uploadStatus: String?
    let width: CGFloat
    let height: CGFloat
    let fileSize: String?
    let createdAt: String?
}
