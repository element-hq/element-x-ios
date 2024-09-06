//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

class MediaPlayerProvider: MediaPlayerProviderProtocol {
    private lazy var audioPlayer = AudioPlayer()
    private var audioPlayerStates: [String: AudioPlayerState] = [:]
    
    deinit {
        audioPlayerStates = [:]
    }
    
    func player(for mediaSource: MediaSourceProxy) -> Result<MediaPlayerProtocol, MediaPlayerProviderError> {
        guard let mimeType = mediaSource.mimeType else {
            MXLog.error("Unknown mime type")
            return .failure(.unsupportedMediaType)
        }
        
        if mimeType.starts(with: "audio/") {
            return .success(audioPlayer)
        } else {
            MXLog.error("Unsupported media type: \(mediaSource.mimeType ?? "unknown")")
            return .failure(.unsupportedMediaType)
        }
    }
    
    // MARK: - AudioPlayer
    
    func playerState(for id: AudioPlayerStateIdentifier) -> AudioPlayerState? {
        guard let audioPlayerStateID = audioPlayerStateID(for: id) else {
            MXLog.error("Failed to build an ID using: \(id)")
            return nil
        }
        return audioPlayerStates[audioPlayerStateID]
    }
    
    func register(audioPlayerState: AudioPlayerState) {
        guard let audioPlayerStateID = audioPlayerStateID(for: audioPlayerState.id) else {
            MXLog.error("Failed to build a key to register this audioPlayerState: \(audioPlayerState)")
            return
        }
        audioPlayerStates[audioPlayerStateID] = audioPlayerState
    }
    
    func unregister(audioPlayerState: AudioPlayerState) {
        guard let audioPlayerStateID = audioPlayerStateID(for: audioPlayerState.id) else {
            MXLog.error("Failed to build a key to register this audioPlayerState: \(audioPlayerState)")
            return
        }
        audioPlayerStates[audioPlayerStateID] = nil
    }
    
    func detachAllStates(except exception: AudioPlayerState?) {
        for key in audioPlayerStates.keys {
            if let exception, key == audioPlayerStateID(for: exception.id) {
                continue
            }
            audioPlayerStates[key]?.detachAudioPlayer()
        }
    }
    
    // MARK: - Private
    
    private func audioPlayerStateID(for identifier: AudioPlayerStateIdentifier) -> String? {
        switch identifier {
        case .timelineItemIdentifier(let timelineItemIdentifier):
            return timelineItemIdentifier.eventID
        case .recorderPreview:
            return "recorderPreviewAudioPlayerState"
        }
    }
}
