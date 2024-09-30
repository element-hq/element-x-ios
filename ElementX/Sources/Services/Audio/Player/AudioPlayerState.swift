//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation
import MediaPlayer
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
    let title: String
    private(set) var duration: Double
    let waveform: EstimatedWaveform
    @Published private(set) var progress: Double
    
    @Published private(set) var playbackState: AudioPlayerPlaybackState
    /// It's similar to `playbackState`, with the a difference: `.loading`
    /// updates are delayed by a fixed amount of time
    @Published private(set) var playerButtonPlaybackState: AudioPlayerPlaybackState

    private weak var audioPlayer: AudioPlayerProtocol?
    private var audioPlayerSubscription: AnyCancellable?
    private var playbackStateSubscription: AnyCancellable?
    private var displayLink: CADisplayLink?

    /// The file url that the last player attached to this object has loaded.
    /// The file url persists even if the AudioPlayer will be detached later.
    private(set) var fileURL: URL?
    
    var showProgressIndicator: Bool {
        progress > 0
    }

    var isAttached: Bool {
        audioPlayer != nil
    }
    
    var isPublishingProgress: Bool {
        displayLink != nil
    }

    init(id: AudioPlayerStateIdentifier, title: String, duration: Double, waveform: EstimatedWaveform? = nil, progress: Double = 0.0) {
        self.id = id
        self.title = title
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
            setUpRemoteCommandCenter()
        case .didPausePlaying:
            stopPublishProgress()
            playbackState = .stopped
        case .didStopPlaying:
            playbackState = .stopped
            stopPublishProgress()
            tearDownRemoteCommandCenter()
        case .didFinishPlaying:
            playbackState = .stopped
            progress = 0.0
            stopPublishProgress()
            tearDownRemoteCommandCenter()
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
    
    // periphery:ignore:parameters displayLink - required for objc selector
    @objc private func updateProgress(displayLink: CADisplayLink) {
        if let currentTime = audioPlayer?.currentTime, duration > 0 {
            progress = currentTime / duration
        }
        
        updateNowPlayingInfoCenter()
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
    
    private func setUpRemoteCommandCenter() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let audioPlayer = self?.audioPlayer else {
                return MPRemoteCommandHandlerStatus.commandFailed
            }
            
            audioPlayer.play()
            
            return MPRemoteCommandHandlerStatus.success
        }
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let audioPlayer = self?.audioPlayer else {
                return MPRemoteCommandHandlerStatus.commandFailed
            }
            
            audioPlayer.pause()

            return MPRemoteCommandHandlerStatus.success
        }
        
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.removeTarget(nil)
        commandCenter.skipForwardCommand.addTarget { [weak self] event in
            guard let audioPlayer = self?.audioPlayer, let skipEvent = event as? MPSkipIntervalCommandEvent else {
                return MPRemoteCommandHandlerStatus.commandFailed
            }
            
            Task {
                await audioPlayer.seek(to: audioPlayer.currentTime + skipEvent.interval)
            }
            
            return MPRemoteCommandHandlerStatus.success
        }
        
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.removeTarget(nil)
        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
            guard let audioPlayer = self?.audioPlayer, let skipEvent = event as? MPSkipIntervalCommandEvent else {
                return MPRemoteCommandHandlerStatus.commandFailed
            }
            
            Task {
                await audioPlayer.seek(to: audioPlayer.currentTime - skipEvent.interval)
            }
            
            return MPRemoteCommandHandlerStatus.success
        }
    }
    
    private func tearDownRemoteCommandCenter() {
        UIApplication.shared.endReceivingRemoteControlEvents()
        
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        nowPlayingInfoCenter.nowPlayingInfo = nil
        nowPlayingInfoCenter.playbackState = .stopped
        
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = false
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.isEnabled = false
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.skipForwardCommand.removeTarget(nil)
        commandCenter.skipBackwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.removeTarget(nil)
    }
    
    private func updateNowPlayingInfoCenter() {
        guard let audioPlayer else {
            return
        }
        
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        nowPlayingInfoCenter.nowPlayingInfo = [MPMediaItemPropertyTitle: title,
                                               MPMediaItemPropertyPlaybackDuration: audioPlayer.duration as Any,
                                               MPNowPlayingInfoPropertyElapsedPlaybackTime: audioPlayer.currentTime as Any]
    }
}

extension AudioPlayerState: Equatable {
    nonisolated static func == (lhs: AudioPlayerState, rhs: AudioPlayerState) -> Bool {
        lhs.id == rhs.id
    }
}
