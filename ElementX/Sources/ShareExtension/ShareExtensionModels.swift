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
    
    /// Moves any files in the payload from our `appGroupTemporaryDirectory` to the
    /// system's `temporaryDirectory` returning a modified payload with updated file URLs.
    func withDefaultTemporaryDirectory() throws -> Self {
        switch self {
        case .mediaFile(let roomID, let mediaFile):
            let path = mediaFile.url.path.replacing(URL.appGroupTemporaryDirectory.path, with: "").trimmingPrefix("/")
            let newURL = URL.temporaryDirectory.appending(path: path)
            
            try? FileManager.default.removeItem(at: newURL)
            try FileManager.default.moveItem(at: mediaFile.url, to: newURL)
            
            return .mediaFile(roomID: roomID, mediaFile: mediaFile.replacingURL(with: newURL))
        case .text:
            return self
        }
    }
}

struct ShareExtensionMediaFile: Hashable, Codable {
    let url: URL
    let suggestedName: String?
    
    fileprivate func replacingURL(with newURL: URL) -> ShareExtensionMediaFile {
        ShareExtensionMediaFile(url: newURL, suggestedName: suggestedName)
    }
}
