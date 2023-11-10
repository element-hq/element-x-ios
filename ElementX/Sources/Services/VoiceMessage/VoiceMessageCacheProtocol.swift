//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
