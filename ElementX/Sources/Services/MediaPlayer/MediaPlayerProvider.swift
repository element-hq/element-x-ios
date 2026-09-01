//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVFoundation
import Foundation

class MediaPlayerProvider: MediaPlayerProviderProtocol {
    private lazy var audioPlayer = AudioPlayer()
    private var audioPlayerStates: [String: AudioPlayerState] = [:]
    /// Held onto for the duration of the playback, an unowned player is silent.
    private var soundEffectPlayer: AVAudioPlayer?
    
    var player: AudioPlayerProtocol {
        audioPlayer
    }
    
    deinit {
        audioPlayerStates = [:]
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
    
    /// Doesn't configure an audio session, so that it can be used alongside any existing player or session.
    func play(soundEffect: SoundEffect) {
        do {
            let player = try AVAudioPlayer(contentsOf: soundEffect.fileURL)
            soundEffectPlayer = player
            player.play()
        } catch {
            MXLog.error("Failed playing the sound effect: \(error)")
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
