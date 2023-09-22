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

class MediaPlayerProvider: MediaPlayerProviderProtocol {
    private let mediaProvider: MediaProviderProtocol
    private var audioPlayer: AudioPlayerProtocol?
        
    init(mediaProvider: MediaProviderProtocol) {
        self.mediaProvider = mediaProvider
    }
    
    func player(for mediaSource: MediaSourceProxy) async -> MediaPlayerProtocol? {
        let audioPlayer = audioPlayer ?? AudioPlayer()
        
        if audioPlayer.url == mediaSource.url {
            return audioPlayer
        }
        
        if audioPlayer.url != mediaSource.url {
            audioPlayer.stop()
            audioPlayer.unloadContent()
        }
        
        if audioPlayer.url == nil {
            guard case .success(let fileHandle) = await mediaProvider.loadFileFromSource(mediaSource) else {
                return nil
            }

            do {
                try await audioPlayer.load(mediaSource: mediaSource, mediaFileHandle: fileHandle)
            } catch {
                MXLog.error("[MediaPlayerProvider] failed to load media: \(error)")
                return nil
            }
        }
        
        self.audioPlayer = audioPlayer
        return audioPlayer
    }
}
