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

    private let supportedVoiceMessageMimeType = "audio/ogg"

    /// Preferred audio file extension after conversion
    private let preferredAudioExtension = "m4a"

    init(mediaProvider: MediaProviderProtocol) {
        self.mediaProvider = mediaProvider
        cache = VoiceMessageCache()
    }
    
    deinit {
        cache.clearCache()
    }
    
    func loadVoiceMessageFromSource(_ source: MediaSourceProxy, body: String?) async throws -> URL {
        guard let mimeType = source.mimeType, mimeType == supportedVoiceMessageMimeType else {
            throw VoiceMessageMediaManagerError.unsupportedMimeTye
        }
        
        // Do we already have a converted version?
        if let fileURL = cache.fileURL(for: source, withExtension: preferredAudioExtension) {
            return fileURL
        }
        
        // Otherwise, load the file from source
        guard case .success(let fileHandle) = await mediaProvider.loadFileFromSource(source, body: body) else {
            throw MediaProviderError.failedRetrievingFile
        }
        let fileURL = try cache.cache(mediaSource: source, using: fileHandle.url)
                
        // Convert from ogg
        let audioConverter = AudioConverter()
        let convertedFileURL = cache.cacheURL(for: source, replacingExtension: preferredAudioExtension)
        try audioConverter.convertToMPEG4AAC(sourceURL: fileURL, destinationURL: convertedFileURL)
        
        // we don't need the original file anymore
        try? FileManager.default.removeItem(at: fileURL)
        
        return convertedFileURL
    }
}
