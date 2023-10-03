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

    private var audioPlayer: AudioPlayerProtocol?
    private var cancellables: Set<AnyCancellable> = []
    private var cancellableTimer: AnyCancellable?
    
    init(duration: Double, waveform: Waveform? = nil, progress: Double = 0.0) {
        self.duration = duration
        self.waveform = waveform ?? Waveform(data: [])
        self.progress = progress
        playbackState = .stopped
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
        self.audioPlayer = audioPlayer
        subscribeToAudioPlayer(audioPlayer: audioPlayer)
    }
    
    func detachAudioPlayer() {
        stopPublishProgression()
        cancellables = []
        audioPlayer = nil
        playbackState = .stopped
    }
    
    // MARK: - Private
    
    private func subscribeToAudioPlayer(audioPlayer: AudioPlayerProtocol) {
        audioPlayer.actions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                guard let self else {
                    return
                }
                self.handleAudioPlayerAction(action)
            }
            .store(in: &cancellables)
    }
    
    private func handleAudioPlayerAction(_ action: AudioPlayerAction) {
        switch action {
        case .didStartLoading:
            playbackState = .loading
        case .didFinishLoading:
            if let audioPlayer {
                Task {
                    await restoreAudioPlayerState(audioPlayer: audioPlayer)
                }
            }
            playbackState = .readyToPlay
        case .didStartPlaying:
            playbackState = .playing
            startPublishProgress()
            disableIdleTimer(true)
        case .didPausePlaying, .didStopPlaying, .didFinishPlaying:
            stopPublishProgression()
            playbackState = .stopped
            disableIdleTimer(false)
            if case .didFinishPlaying = action {
                progress = 0.0
            }
        case .didFailWithError:
            stopPublishProgression()
        }
    }
    
    private func startPublishProgress() {
        cancellableTimer?.cancel()

        cancellableTimer = Timer.publish(every: 0.2, on: .main, in: .default)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                guard let self else { return }
                if let currentTime = self.audioPlayer?.currentTime, self.duration > 0 {
                    self.progress = currentTime / self.duration
                }
            })
    }
    
    private func stopPublishProgression() {
        cancellableTimer?.cancel()
    }
    
    private func restoreAudioPlayerState(audioPlayer: AudioPlayerProtocol) async {
        await audioPlayer.seek(to: progress)
    }
    
    private func disableIdleTimer(_ disabled: Bool) {
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = disabled
        }
    }
}
