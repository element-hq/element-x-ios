//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum ShareExtensionConstants {
    static let urlPath = "share"
}

enum ShareExtensionPayload: Hashable, Codable {
    case mediaFile(roomID: String?, mediaFile: ShareExtensionMediaFile)
    case text(roomID: String?, text: String)
    
    var roomID: String? {
        switch self {
        case .mediaFile(let roomID, _),
             .text(let roomID, _):
            roomID
        }
    }
}

struct ShareExtensionMediaFile: Hashable, Codable {
    let url: URL
    let suggestedName: String?
}
