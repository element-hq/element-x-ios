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

@MainActor
class AudioPlayerState: ObservableObject {
    let duration: Double
    let waveform: Waveform
    @Published private(set) var playbackState: AudioPlayerPlaybackState
    @Published private(set) var progress: Double

    private weak var audioPlayer: AudioPlayerProtocol?
    private var cancellables: Set<AnyCancellable> = []
    private var displayLink: CADisplayLink?

    var isAttached: Bool {
        audioPlayer != nil
    }
    
    var isPublishingProgress: Bool {
        displayLink != nil
    }

    init(duration: Double, waveform: Waveform? = nil, progress: Double = 0.0) {
        self.duration = duration
        self.waveform = waveform ?? Waveform(data: [])
        self.progress = progress
        playbackState = .stopped
    }
    
    deinit {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    func updateState(progress: Double) async {
        let progress = max(0.0, min(progress, 1.0))
        self.progress = progress
        if let audioPlayer {
            await audioPlayer.seek(to: progress)
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
        guard audioPlayer != nil else { return }
        audioPlayer?.stop()
        stopPublishProgress()
        cancellables = []
        audioPlayer = nil
        playbackState = .stopped
    }
    
    func reportError(_ error: Error) {
        playbackState = .error
    }
    
    // MARK: - Private
    
    private func subscribeToAudioPlayer(audioPlayer: AudioPlayerProtocol) {
        audioPlayer.actions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                guard let self else {
                    return
                }
                Task {
                    await self.handleAudioPlayerAction(action)
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleAudioPlayerAction(_ action: AudioPlayerAction) async {
        switch action {
        case .didStartLoading:
            playbackState = .loading
        case .didFinishLoading:
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
        }
    }
    
    private func startPublishProgress() {
        if displayLink != nil {
            displayLink?.invalidate()
        }
        displayLink = CADisplayLink(target: self, selector: #selector(updateProgress))
        displayLink?.preferredFrameRateRange = .init(minimum: 10, maximum: 20)
        displayLink?.add(to: .current, forMode: .common)
    }
    
    @objc private func updateProgress(displayLink: CADisplayLink) {
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
}
