//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

let ShareExtensionURLPath = "share"

enum ShareExtensionPayload: Hashable, Codable {
    case mediaFile(roomID: String, mediaFile: ShareExtensionMediaFile)
}

struct ShareExtensionMediaFile: Hashable, Codable {
    let url: URL
    let suggestedName: String?
}
