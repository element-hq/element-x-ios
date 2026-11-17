//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum ShareExtensionConstants {
    static let urlPath = "share"
}

enum ShareExtensionPayload: Hashable, Codable {
    case mediaFiles(roomID: String?, mediaFiles: [ShareExtensionMediaFile])
    case text(roomID: String?, text: String)
    
    var roomID: String? {
        switch self {
        case .mediaFiles(let roomID, _),
             .text(let roomID, _):
            roomID
        }
    }
    
    /// Moves the unique folder holding each file in the payload from our `appGroupTemporaryDirectory`
    /// to the system's `temporaryDirectory` returning a modified payload with updated file URLs.
    func withDefaultTemporaryDirectory() throws -> Self {
        switch self {
        case .mediaFiles(let roomID, let mediaFiles):
            return try .mediaFiles(roomID: roomID, mediaFiles: mediaFiles.map { mediaFile in
                let folderURL = mediaFile.url.standardizedFileURL.deletingLastPathComponent()
                // Any app can open the share URL, so only move folders the share extension created.
                guard folderURL.deletingLastPathComponent().pathComponents == URL.appGroupTemporaryDirectory.pathComponents else {
                    throw ShareExtensionPayloadError.fileOutsideAppGroupTemporaryDirectory
                }
                
                let newFolderURL = URL.temporaryDirectory.appending(component: folderURL.lastPathComponent, directoryHint: .isDirectory)
                
                try? FileManager.default.removeItem(at: newFolderURL)
                try FileManager.default.moveItem(at: folderURL, to: newFolderURL)
                
                return mediaFile.replacingURL(with: newFolderURL.appending(component: mediaFile.url.lastPathComponent))
            })
        case .text:
            return self
        }
    }
}

enum ShareExtensionPayloadError: Error {
    case fileOutsideAppGroupTemporaryDirectory
}

struct ShareExtensionMediaFile: Hashable, Codable {
    let url: URL
    let suggestedName: String?
    
    fileprivate func replacingURL(with newURL: URL) -> ShareExtensionMediaFile {
        ShareExtensionMediaFile(url: newURL, suggestedName: suggestedName)
    }
}
