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

enum VoiceMessageMediaManagerError: Error {
    case unsupportedMimeTye
}

class VoiceMessageMediaManager: VoiceMessageMediaManagerProtocol {
    private let mediaProvider: MediaProviderProtocol
    private let cache: VoiceMessageCache

    private let supportedMimeTypePrefix = "audio/"
    /// File extensions supported for playing voice messages without conversion
    private let supportedAudioExtensions = ["mp3", "mp4", "m4a", "wav", "aac"]
    /// Preferred audio file extension
    private let preferredAudioExtension = "m4a"

    init(mediaProvider: MediaProviderProtocol) {
        self.mediaProvider = mediaProvider
        cache = VoiceMessageCache()
    }
    
    deinit {
        cache.clearCache()
    }
    
    func loadVoiceMessageFromSource(_ source: MediaSourceProxy, body: String?) async throws -> URL {
        guard let mimeType = source.mimeType, mimeType.starts(with: supportedMimeTypePrefix) else {
            throw VoiceMessageMediaManagerError.unsupportedMimeTye
        }
        
        if !cache.fileExists(for: source) {
            guard case .success(let fileHandle) = await mediaProvider.loadFileFromSource(source, body: body) else {
                throw MediaProviderError.failedRetrievingFile
            }
            try cache.cache(mediaSource: source, using: fileHandle.url)
        }
        
        var url = cache.cacheURL(for: source)
    
        // Convert from ogg if needed
        if !hasSupportedAudioExtension(url) {
            let audioConverter = AudioConverter()
            let originalURL = url
            url = cache.cacheURL(for: source, replacingExtension: preferredAudioExtension)
            // Do we already have a converted version?
            if !cache.fileExists(for: source, withExtension: preferredAudioExtension) {
                try audioConverter.convertToMPEG4AAC(sourceURL: originalURL, destinationURL: url)
            }
            
            // we don't need the original file anymore
            try? FileManager.default.removeItem(at: originalURL)
        }
        
        return url
    }
    
    // MARK: - Private
    
    /// Returns true if the URL has a supported audio extension
    private func hasSupportedAudioExtension(_ url: URL) -> Bool {
        supportedAudioExtensions.contains(url.pathExtension.lowercased())
    }
}
