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

enum MediaPlayerProviderError: Error {
    case unsupportedMediaType
}

class MediaPlayerProvider: MediaPlayerProviderProtocol {
    private var audioPlayer: AudioPlayerProtocol!
    private var audioPlayerStates: [String: AudioPlayerState] = [:]
    
    deinit {
        audioPlayer = nil
        audioPlayerStates = [:]
    }
    
    func player(for mediaSource: MediaSourceProxy) throws -> MediaPlayerProtocol {
        guard let mimeType = mediaSource.mimeType else {
            MXLog.error("Unknown mime type")
            throw MediaPlayerProviderError.unsupportedMediaType
        }
        
        if mimeType.starts(with: "audio/") {
            if audioPlayer == nil {
                audioPlayer = AudioPlayer()
            }
            return audioPlayer
        } else {
            MXLog.error("Unsupported media type: \(mediaSource.mimeType ?? "unknown")")
            throw MediaPlayerProviderError.unsupportedMediaType
        }
    }
    
    // MARK: - AudioPlayer
    
    func playerState(withId id: String) -> AudioPlayerState? {
        audioPlayerStates[id]
    }
    
    func register(audioPlayerState: AudioPlayerState, withId id: String) {
        audioPlayerStates[id] = audioPlayerState
    }
    
    func unregister(withAudioPlayerStateId id: String) {
        audioPlayerStates[id] = nil
    }
    
    func detachAllStates(except exception: AudioPlayerState?) async {
        for key in audioPlayerStates.keys {
            if key == exception?.id.uuidString {
                continue
            }
            await audioPlayerStates[key]?.detachAudioPlayer()
        }
    }
}
