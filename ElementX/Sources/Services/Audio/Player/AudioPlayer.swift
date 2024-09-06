//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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

class AudioPlayer: NSObject, AudioPlayerProtocol {
    var mediaSource: MediaSourceProxy?
    
    private var playerItem: AVPlayerItem?
    private var internalAudioPlayer: AVQueuePlayer?
    
    private var cancellables = Set<AnyCancellable>()
    private let actionsSubject: PassthroughSubject<AudioPlayerAction, Never> = .init()
    var actions: AnyPublisher<AudioPlayerAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var internalState = InternalAudioPlayerState.none
    
    private var statusObserver: NSKeyValueObservation?
    private var rateObserver: NSKeyValueObservation?
    private var autoplay = false
    
    private let audioSession = AVAudioSession.sharedInstance()
    
    // periphery:ignore - when set to nil is automatically cancelled
    @CancellableTask private var releaseAudioSessionTask: Task<Void, Never>?
    
    private let releaseAudioSessionTimeoutInterval = 5.0
    
    private(set) var url: URL?
    
    private var deinitInProgress = false
    
    var duration: TimeInterval {
        abs(CMTimeGetSeconds(internalAudioPlayer?.currentItem?.duration ?? .zero))
    }
    
    var currentTime: TimeInterval {
        let currentTime = abs(CMTimeGetSeconds(internalAudioPlayer?.currentTime() ?? .zero))
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
        deinitInProgress = true
        stop()
        unloadContent()
    }
    
    func load(mediaSource: MediaSourceProxy, using url: URL, autoplay: Bool) {
        unloadContent()
        setInternalState(.loading)
        self.mediaSource = mediaSource
        self.url = url
        self.autoplay = autoplay
        playerItem = AVPlayerItem(url: url)
        internalAudioPlayer = AVQueuePlayer(playerItem: playerItem)
        addObservers()
    }
    
    func reset() {
        stop()
        unloadContent()
    }
    
    func play() {
        isStopped = false
        setupAudioSession()
        internalAudioPlayer?.play()
    }
    
    func pause() {
        guard case .playing = internalState else { return }
        internalAudioPlayer?.pause()
        releaseAudioSession(after: releaseAudioSessionTimeoutInterval)
    }
    
    func stop() {
        guard !isStopped else { return }
        isStopped = true
        internalAudioPlayer?.pause()
        internalAudioPlayer?.seek(to: .zero)
        releaseAudioSession(after: releaseAudioSessionTimeoutInterval)
    }
    
    func seek(to progress: Double) async {
        guard let internalAudioPlayer else { return }
        let time = progress * duration
        await internalAudioPlayer.seek(to: CMTime(seconds: time, preferredTimescale: 60))
    }
    
    // MARK: - Private
    
    private func setupAudioSession() {
        releaseAudioSessionTask = nil
        do {
            try audioSession.setCategory(.playback)
            try audioSession.setActive(true)
        } catch {
            MXLog.error("Could not redirect audio playback to speakers.")
        }
    }
    
    private func releaseAudioSession(after timeInterval: TimeInterval) {
        guard !deinitInProgress else {
            releaseAudioSession()
            return
        }
        releaseAudioSessionTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(timeInterval))
            guard !Task.isCancelled else { return }
            
            self?.releaseAudioSession()
        }
    }
    
    private func releaseAudioSession() {
        releaseAudioSessionTask = nil
        if audioSession.category == .playback, !audioSession.isOtherAudioPlaying {
            MXLog.info("releasing audio session")
            try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
    
    private func unloadContent() {
        mediaSource = nil
        url = nil
        internalAudioPlayer?.replaceCurrentItem(with: nil)
        internalAudioPlayer = nil
        playerItem = nil
        removeObservers()
    }

    private func addObservers() {
        guard let internalAudioPlayer, let playerItem else {
            return
        }
        
        statusObserver = playerItem.observe(\.status, options: [.old, .new]) { [weak self] _, _ in
            guard let self else { return }
            
            switch playerItem.status {
            case .failed:
                setInternalState(.error(playerItem.error ?? AudioPlayerError.genericError))
            case .readyToPlay:
                guard state == .loading else { return }
                setInternalState(.readyToPlay)
            default:
                break
            }
        }
                
        rateObserver = internalAudioPlayer.observe(\.rate, options: [.old, .new]) { [weak self] _, _ in
            guard let self else { return }
            
            if internalAudioPlayer.rate == 0 {
                if isStopped {
                    setInternalState(.stopped)
                } else {
                    setInternalState(.paused)
                }
            } else {
                setInternalState(.playing)
            }
        }
                
        NotificationCenter.default.publisher(for: Notification.Name.AVPlayerItemDidPlayToEndTime)
            .sink { [weak self] _ in
                guard let self else { return }
                setInternalState(.finishedPlaying)
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
            if autoplay {
                autoplay = false
                play()
            }
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
