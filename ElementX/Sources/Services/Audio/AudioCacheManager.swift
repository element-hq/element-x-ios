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

class AudioCacheManager {
    private var temporaryFilesFolderURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("media/audio")
    }
        
    func cacheURL(for mediaSource: MediaSourceProxy, replacingExtension newExtension: String? = nil) -> URL {
        var newURL = temporaryFilesFolderURL.appendingPathComponent(mediaSource.url.lastPathComponent)
        if let newExtension {
            newURL = newURL.deletingPathExtension().appendingPathExtension(newExtension)
        }
        return newURL
    }
    
    func fileExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path())
    }

    func setupTemporaryFilesFolder() throws {
        let url = temporaryFilesFolderURL
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
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
}
