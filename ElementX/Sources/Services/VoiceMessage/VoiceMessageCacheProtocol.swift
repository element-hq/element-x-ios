//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum VoiceMessageCacheError: Error {
    case invalidFileExtension
    case failedStoringFileInCache
}

protocol VoiceMessageCacheProtocol {
    /// URL to use for recording
    var urlForRecording: URL { get }
    
    /// Returns the URL of the cached audio file for a given media source
    /// - Parameter mediaSource: the media source
    /// - Returns: the URL of the cached audio file or nil if the file doesn't exist
    func fileURL(for mediaSource: MediaSourceProxy) -> URL?
    
    /// Adds a file in the cache
    /// - Parameters:
    ///   - mediaSource: the media source
    ///   - fileURL: the source file
    ///   - move: wheter to move or copy the source file
    /// - Returns: the cached URL
    func cache(mediaSource: MediaSourceProxy, using fileURL: URL, move: Bool) -> Result<URL, VoiceMessageCacheError>
        
    /// Clears the cache
    func clearCache()
}

// sourcery: AutoMockable
extension VoiceMessageCacheProtocol { }
