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
}

class VoiceMessageCache {
    private let preferredFileExtension = "m4a"
    private var temporaryFilesFolderURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("media/voice-message")
    }
        
    func fileURL(for mediaSource: MediaSourceProxy) -> URL? {
        let url = cacheURL(for: mediaSource)
        return FileManager.default.fileExists(atPath: url.path()) ? url : nil
    }

    func cache(mediaSource: MediaSourceProxy, using fileURL: URL, move: Bool = false) throws -> URL {
        guard fileURL.pathExtension == preferredFileExtension else {
            throw VoiceMessageCacheError.invalidFileExtension
        }
        setupTemporaryFilesFolder()
        let url = cacheURL(for: mediaSource)
        try? FileManager.default.removeItem(at: url)
        if move {
            try FileManager.default.moveItem(at: fileURL, to: url)
        } else {
            try FileManager.default.copyItem(at: fileURL, to: url)
        }
        return url
    }
    
    func clearCache() {
        if FileManager.default.fileExists(atPath: temporaryFilesFolderURL.path) {
            do {
                try FileManager.default.removeItem(at: temporaryFilesFolderURL)
            } catch {
                MXLog.error("Failed clearing cached disk files", context: error)
            }
        }
    }
    
    // MARK: - Private
    
    private func setupTemporaryFilesFolder() {
        do {
            try FileManager.default.createDirectoryIfNeeded(at: temporaryFilesFolderURL, withIntermediateDirectories: true)
        } catch {
            MXLog.error("Failed to setup audio cache manager.")
        }
    }
    
    private func cacheURL(for mediaSource: MediaSourceProxy) -> URL {
        temporaryFilesFolderURL.appendingPathComponent(mediaSource.url.lastPathComponent).appendingPathExtension(preferredFileExtension)
    }
}
