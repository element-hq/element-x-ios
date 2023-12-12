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

import Combine
import Foundation
import UIKit

enum AudioPlayerPlaybackState {
    case loading
    case readyToPlay
    case playing
    case stopped
    case error
}

enum AudioPlayerStateIdentifier {
    case timelineItemIdentifier(TimelineItemIdentifier)
    case recorderPreview
}

@MainActor
class AudioPlayerState: ObservableObject, Identifiable {
    let id: AudioPlayerStateIdentifier
    private(set) var duration: Double
    let waveform: EstimatedWaveform
    @Published private(set) var playbackState: AudioPlayerPlaybackState
    /// It's similar to `playbackState`, with the a difference: `.loading`
    /// updates are delayed by a fixed amount of time
    @Published private(set) var playerButtonPlaybackState: AudioPlayerPlaybackState
    @Published private(set) var progress: Double
    var showProgressIndicator: Bool {
        progress > 0
    }

    private weak var audioPlayer: AudioPlayerProtocol?
    private var audioPlayerSubscription: AnyCancellable?
    private var playbackStateSubscription: AnyCancellable?
    private var displayLink: CADisplayLink?

    /// The file url that the last player attached to this object has loaded.
    /// The file url persists even if the AudioPlayer will be detached later.
    private(set) var fileURL: URL?

    var isAttached: Bool {
        audioPlayer != nil
    }
    
    var isPublishingProgress: Bool {
        displayLink != nil
    }

    init(id: AudioPlayerStateIdentifier, duration: Double, waveform: EstimatedWaveform? = nil, progress: Double = 0.0) {
        self.id = id
        self.duration = duration
        self.waveform = waveform ?? EstimatedWaveform(data: [])
        self.progress = progress
        playbackState = .stopped
        playerButtonPlaybackState = .stopped
        setupPlaybackStateSubscription()
    }
    
    deinit {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    func updateState(progress: Double) async {
        let progress = max(0.0, min(progress, 1.0))
        self.progress = progress
        if let audioPlayer {
            var shouldResumeProgressPublishing = false
            if audioPlayer.state == .playing {
                shouldResumeProgressPublishing = true
                stopPublishProgress()
            }
            await audioPlayer.seek(to: progress)
            if shouldResumeProgressPublishing, audioPlayer.state == .playing {
                startPublishProgress()
            }
        }
    }
    
    func attachAudioPlayer(_ audioPlayer: AudioPlayerProtocol) {
        if self.audioPlayer != nil {
            detachAudioPlayer()
        }
        playbackState = .loading
        self.audioPlayer = audioPlayer
        subscribeToAudioPlayer(audioPlayer: audioPlayer)
    }
    
    func detachAudioPlayer() {
        audioPlayer?.stop()
        stopPublishProgress()
        audioPlayerSubscription = nil
        audioPlayer = nil
        playbackState = .stopped
    }
    
    func reportError() {
        playbackState = .error
    }
    
    // MARK: - Private
    
    private func subscribeToAudioPlayer(audioPlayer: AudioPlayerProtocol) {
        audioPlayerSubscription = audioPlayer.actions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                guard let self else {
                    return
                }
                Task {
                    await self.handleAudioPlayerAction(action)
                }
            }
    }
    
    private func handleAudioPlayerAction(_ action: AudioPlayerAction) async {
        switch action {
        case .didStartLoading:
            playbackState = .loading
        case .didFinishLoading:
            if let audioPlayerDuration = audioPlayer?.duration, audioPlayerDuration != duration {
                MXLog.info("updating duration: \(duration) -> \(audioPlayerDuration)")
                duration = audioPlayerDuration
            }
            fileURL = audioPlayer?.url
            playbackState = .readyToPlay
        case .didStartPlaying:
            if let audioPlayer {
                await restoreAudioPlayerState(audioPlayer: audioPlayer)
            }
            startPublishProgress()
            playbackState = .playing
        case .didPausePlaying, .didStopPlaying, .didFinishPlaying:
            stopPublishProgress()
            playbackState = .stopped
            if case .didFinishPlaying = action {
                progress = 0.0
            }
        case .didFailWithError:
            stopPublishProgress()
            playbackState = .error
        }
    }
    
    private func startPublishProgress() {
        if displayLink != nil {
            stopPublishProgress()
        }
        displayLink = CADisplayLink(target: self, selector: #selector(updateProgress))
        displayLink?.preferredFrameRateRange = .init(minimum: 10, maximum: 20)
        displayLink?.add(to: .current, forMode: .common)
    }
    
    @objc private func updateProgress() {
        if let currentTime = audioPlayer?.currentTime, duration > 0 {
            progress = currentTime / duration
        }
    }
    
    private func stopPublishProgress() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    private func restoreAudioPlayerState(audioPlayer: AudioPlayerProtocol) async {
        await audioPlayer.seek(to: progress)
    }
    
    private func setupPlaybackStateSubscription() {
        playbackStateSubscription = $playbackState
            .map { state in
                switch state {
                case .loading:
                    return Just(state)
                        .delay(for: .seconds(2), scheduler: RunLoop.main)
                        .eraseToAnyPublisher()
                case .playing, .stopped, .error, .readyToPlay:
                    return Just(state)
                        .eraseToAnyPublisher()
                }
            }
            .switchToLatest()
            .removeDuplicates()
            .weakAssign(to: \.playerButtonPlaybackState, on: self)
    }
}

extension AudioPlayerState: Equatable {
    nonisolated static func == (lhs: AudioPlayerState, rhs: AudioPlayerState) -> Bool {
        lhs.id == rhs.id
    }
}
