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

private extension URL {
    /// Returns true if the URL has a supported audio extension
    var hasSupportedAudioExtension: Bool {
        let supportedExtensions = ["mp3", "mp4", "m4a", "wav", "aac"]
        return supportedExtensions.contains(pathExtension.lowercased())
    }
}

class AudioPlayer: NSObject, AudioPlayerProtocol {
    private(set) var mediaSource: MediaSourceProxy?
    
    private var playerItem: AVPlayerItem?
    private var audioPlayer: AVQueuePlayer?
    
    private var cancellables = Set<AnyCancellable>()
    private let callbacksSubject: PassthroughSubject<AudioPlayerCallback, Never> = .init()
    var callbacks: AnyPublisher<AudioPlayerCallback, Never> {
        callbacksSubject.eraseToAnyPublisher()
    }
    
    private var internalState = InternalAudioPlayerState.none
    
    private var statusObserver: NSKeyValueObservation?
    private var rateObserver: NSKeyValueObservation?
    private var playToEndObserver: NSObjectProtocol?
    private var appBackgroundObserver: NSObjectProtocol?
    
    private let cacheManager: AudioCacheManager
    @CancellableTask private var loadingTask: Task<URL?, Error>?
    
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
    
    init(cacheManager: AudioCacheManager) {
        self.cacheManager = cacheManager
        super.init()
    }
    
    deinit {
        stop()
        unloadContent()
        disableIdleTimer(false)
    }
    
    func play(mediaSource: MediaSourceProxy, mediaProvider: MediaProviderProtocol) async throws {
        if state != .error, self.mediaSource == mediaSource {
            return
        }
        
        unloadContent()
        setInternalState(.loading)

        loadingTask = Task<URL?, Error> {
            if !cacheManager.fileExists(for: mediaSource) {
                guard case .success(let fileHandle) = await mediaProvider.loadFileFromSource(mediaSource) else {
                    throw AudioPlayerError.loadFileError
                }
                
                try cacheManager.cache(mediaSource: mediaSource, using: fileHandle.url)
            }
            var url = cacheManager.cacheURL(for: mediaSource)
            
            // Convert from ogg if needed
            if !url.hasSupportedAudioExtension {
                let audioConverter = AudioConverter()
                let originalURL = url
                url = cacheManager.cacheURL(for: mediaSource, replacingExtension: "m4a")
                // Do we already have a converted version?
                if !cacheManager.fileExists(for: mediaSource, withExtension: "m4a") {
                    try await audioConverter.convertToMPEG4AAC(sourceURL: originalURL, destinationURL: url)
                }
                
                // we don't need the original file anymore
                try? FileManager.default.removeItem(at: originalURL)
            }
            
            guard !Task.isCancelled else {
                MXLog.debug("loading task has been cancelled.")
                return nil
            }

            return url
        }
        
        do {
            // if the task value is nil, then the task has been cancelled
            if let url = try await loadingTask?.value {
                self.mediaSource = mediaSource
                self.url = url
                playerItem = AVPlayerItem(url: url)
                audioPlayer = AVQueuePlayer(playerItem: playerItem)
                
                addObservers()
            }
        } catch {
            setInternalState(.error(error))
            throw error
        }
    }

    func resume() async throws {
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
        guard case .playing = internalState else {
            MXLog.error("Cannot pause playback (not playing)")
            return
        }
        audioPlayer?.pause()
    }
    
    func stop() {
        if isStopped {
            return
        }
        
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
                self.setInternalState(.readyToPlay)
            default:
                break
            }
        }
                
        rateObserver = audioPlayer.observe(\.rate, options: [.old, .new]) { [weak self] _, _ in
            guard let self else { return }
            
            if audioPlayer.rate == 0.0 {
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
            dispatchCallback(.didStartLoading)
        case .readyToPlay:
            dispatchCallback(.didFinishLoading)
            audioPlayer?.play()
        case .playing:
            dispatchCallback(.didStartPlaying)
        case .paused:
            dispatchCallback(.didPausePlaying)
        case .stopped:
            dispatchCallback(.didStopPlaying)
        case .finishedPlaying:
            dispatchCallback(.didFinishPlaying)
        case .error(let error):
            MXLog.error("audio player did fail. \(error)")
            dispatchCallback(.didFailWithError(error: error))
        }
    }
    
    private func dispatchCallback(_ callback: AudioPlayerCallback) {
        switch callback {
        case .didStartLoading, .didFinishLoading:
            break
        case .didStartPlaying:
            disableIdleTimer(true)
        case .didPausePlaying, .didStopPlaying, .didFinishPlaying:
            disableIdleTimer(false)
        case .didFailWithError:
            disableIdleTimer(false)
        }
        callbacksSubject.send(callback)
    }
    
    private func disableIdleTimer(_ disabled: Bool) {
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = disabled
        }
    }
}
