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
import UniformTypeIdentifiers

class MediaPlayerProvider: MediaPlayerProviderProtocol {
    private let mediaProvider: MediaProviderProtocol
    private var audioPlayer: AudioPlayerProtocol?
    private var audioCacheManager = AudioCacheManager()
            
    init(mediaProvider: MediaProviderProtocol) {
        self.mediaProvider = mediaProvider
    }
    
    deinit {
        audioPlayer = nil
        audioCacheManager.clearCache()
    }
    
    func player(for mediaSource: MediaSourceProxy) -> MediaPlayerProtocol? {
        guard let mimeType = mediaSource.mimeType else {
            MXLog.error("Unknown mime type")
            return nil
        }
        
        if mimeType.starts(with: "audio/") {
            if audioPlayer == nil {
                audioCacheManager.setupTemporaryFilesFolder()
                audioPlayer = AudioPlayer(cacheManager: audioCacheManager)
            }
            return audioPlayer
        } else {
            MXLog.error("Unsupported media type: \(mediaSource.mimeType ?? "unknown")")
            return nil
        }
    }
}
