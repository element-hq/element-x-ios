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

import AVFoundation
import Combine
import Foundation
import UIKit

private enum InternalAudioPlayerState {
    case none
    case loading
    case readyToPlay
    case playing
    case paused
    case stopped
    case finishedPlaying
    case error(Error)
}

enum AudioPlayerError: Error {
    case genericError
    case loadFileError
}

class AudioPlayer: NSObject, AudioPlayerProtocol {
    var mediaSource: MediaSourceProxy?
    
    private var playerItem: AVPlayerItem?
    private var audioPlayer: AVQueuePlayer?
    
    private var cancellables = Set<AnyCancellable>()
    private let actionsSubject: PassthroughSubject<AudioPlayerAction, Never> = .init()
    var actions: AnyPublisher<AudioPlayerAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var internalState = InternalAudioPlayerState.none
    
    private var statusObserver: NSKeyValueObservation?
    private var rateObserver: NSKeyValueObservation?
    private var playToEndObserver: NSObjectProtocol?
    private var appBackgroundObserver: NSObjectProtocol?
    
    private(set) var url: URL?
    
    var duration: TimeInterval {
        abs(CMTimeGetSeconds(audioPlayer?.currentItem?.duration ?? .zero))
    }
    
    var currentTime: TimeInterval {
        let currentTime = abs(CMTimeGetSeconds(audioPlayer?.currentTime() ?? .zero))
        return currentTime.isFinite ? currentTime : .zero
    }
    
    var state: MediaPlayerState {
        if case .loading = internalState {
            return .loading
        }
        if case .stopped = internalState {
            return .stopped
        }
        if case .playing = internalState {
            return .playing
        }
        if case .paused = internalState {
            return .paused
        }
        if case .error = internalState {
            return .error
        }
        return .stopped
    }
    
    private var isStopped = true
    
    deinit {
        stop()
        unloadContent()
    }
    
    func load(mediaSource: MediaSourceProxy, using url: URL) {
        unloadContent()
        setInternalState(.loading)
        self.mediaSource = mediaSource
        self.url = url
        playerItem = AVPlayerItem(url: url)
        audioPlayer = AVQueuePlayer(playerItem: playerItem)
        addObservers()
    }
    
    func play() {
        isStopped = false
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            MXLog.error("Could not redirect audio playback to speakers.")
        }
        audioPlayer?.play()
    }
    
    func pause() {
        guard case .playing = internalState else { return }
        audioPlayer?.pause()
    }
    
    func stop() {
        guard !isStopped else { return }
        isStopped = true
        audioPlayer?.pause()
        audioPlayer?.seek(to: .zero)
    }
    
    func seek(to progress: Double) async {
        guard let audioPlayer else { return }
        let time = progress * duration
        await audioPlayer.seek(to: CMTime(seconds: time, preferredTimescale: 60000))
    }
    
    // MARK: - Private
    
    private func unloadContent() {
        mediaSource = nil
        url = nil
        audioPlayer?.replaceCurrentItem(with: nil)
        audioPlayer = nil
        playerItem = nil
        removeObservers()
    }

    private func addObservers() {
        guard let audioPlayer, let playerItem else {
            return
        }
        
        statusObserver = playerItem.observe(\.status, options: [.old, .new]) { [weak self] _, _ in
            guard let self else { return }
            
            switch playerItem.status {
            case .failed:
                self.setInternalState(.error(playerItem.error ?? AudioPlayerError.genericError))
            case .readyToPlay:
                guard state == .loading else { return }
                self.setInternalState(.readyToPlay)
            default:
                break
            }
        }
                
        rateObserver = audioPlayer.observe(\.rate, options: [.old, .new]) { [weak self] _, _ in
            guard let self else { return }
            
            if audioPlayer.rate == 0 {
                if self.isStopped {
                    self.setInternalState(.stopped)
                } else {
                    self.setInternalState(.paused)
                }
            } else {
                self.setInternalState(.playing)
            }
        }
                
        NotificationCenter.default.publisher(for: Notification.Name.AVPlayerItemDidPlayToEndTime)
            .sink { [weak self] _ in
                guard let self else { return }
                self.setInternalState(.finishedPlaying)
            }
            .store(in: &cancellables)
        
        // Pause playback uppon UIApplication.didBecomeActiveNotification notification
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                self.pause()
            }
            .store(in: &cancellables)
    }
    
    private func removeObservers() {
        statusObserver?.invalidate()
        rateObserver?.invalidate()
        cancellables.removeAll()
    }
    
    private func setInternalState(_ state: InternalAudioPlayerState) {
        internalState = state
        switch state {
        case .none:
            break
        case .loading:
            actionsSubject.send(.didStartLoading)
        case .readyToPlay:
            actionsSubject.send(.didFinishLoading)
            play()
        case .playing:
            actionsSubject.send(.didStartPlaying)
        case .paused:
            actionsSubject.send(.didPausePlaying)
        case .stopped:
            actionsSubject.send(.didStopPlaying)
        case .finishedPlaying:
            actionsSubject.send(.didFinishPlaying)
            unloadContent()
        case .error(let error):
            MXLog.error("audio player did fail. \(error)")
            actionsSubject.send(.didFailWithError(error: error))
        }
    }
}
