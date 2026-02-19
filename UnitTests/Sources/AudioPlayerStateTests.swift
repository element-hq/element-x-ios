//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Foundation
import Testing

@MainActor
@Suite
struct AudioPlayerStateTests {
    static let audioDuration = 10.0
    private var audioPlayerState: AudioPlayerState!
    private var audioPlayerMock: AudioPlayerMock!
    
    private var audioPlayerActionsSubject: PassthroughSubject<AudioPlayerAction, Never>!
    private var audioPlayerActions: AnyPublisher<AudioPlayerAction, Never> {
        audioPlayerActionsSubject.eraseToAnyPublisher()
    }
    
    private var audioPlayerSeekCallsSubject: PassthroughSubject<Double, Never>!
    
    private func buildAudioPlayerMock() -> AudioPlayerMock {
        let audioPlayerMock = AudioPlayerMock()
        audioPlayerMock.underlyingActions = audioPlayerActions
        audioPlayerMock.state = .stopped
        audioPlayerMock.currentTime = 0.0
        audioPlayerMock.duration = 0.0
        audioPlayerMock.playbackSpeed = 1.0
        audioPlayerMock.seekToClosure = { [audioPlayerSeekCallsSubject] progress in
            audioPlayerSeekCallsSubject?.send(progress)
        }
        return audioPlayerMock
    }
    
    init() async {
        audioPlayerActionsSubject = .init()
        audioPlayerSeekCallsSubject = .init()
        audioPlayerState = AudioPlayerState(id: .timelineItemIdentifier(.randomEvent), title: "", duration: Self.audioDuration)
        audioPlayerMock = buildAudioPlayerMock()
        audioPlayerMock.seekToClosure = { [audioPlayerMock] progress in
            audioPlayerMock?.currentTime = Self.audioDuration * progress
        }
    }
    
    @Test
    func attach() {
        audioPlayerState.attachAudioPlayer(audioPlayerMock)
        
        #expect(audioPlayerState.isAttached)
        #expect(audioPlayerState.playbackState == .loading)
    }
    
    @Test
    mutating func detach() {
        audioPlayerState.attachAudioPlayer(audioPlayerMock)
        
        audioPlayerState.detachAudioPlayer()
        #expect(audioPlayerMock.stopCalled)
        #expect(!audioPlayerState.isAttached)
        #expect(audioPlayerState.playbackState == .stopped)
        #expect(!audioPlayerState.showProgressIndicator)
    }
    
    @Test
    func delayedState() async throws {
        audioPlayerState.attachAudioPlayer(audioPlayerMock)
        
        #expect(audioPlayerState.isAttached)
        #expect(audioPlayerState.playbackState == .loading)
        #expect(audioPlayerState.playerButtonPlaybackState == .stopped)
        
        let deferred = deferFulfillment(audioPlayerState.$playerButtonPlaybackState) { output in
            switch output {
            case .loading:
                return true
            default:
                return false
            }
        }
        try await deferred.fulfill()
        
        #expect(audioPlayerState.playerButtonPlaybackState == .loading)
    }
    
    @Test
    func otherActionsAreNotDelayed() async throws {
        audioPlayerState.attachAudioPlayer(audioPlayerMock)
        #expect(audioPlayerState.playbackState == .loading)
        #expect(audioPlayerState.playerButtonPlaybackState == .stopped)
        
        let deferred = deferFulfillment(audioPlayerState.$playerButtonPlaybackState) { output in
            switch output {
            case .playing:
                return true
            default:
                return false
            }
        }
        
        audioPlayerActionsSubject.send(.didStartPlaying)
        try await deferred.fulfill()
        #expect(audioPlayerState.playbackState == .playing)
        #expect(audioPlayerState.playerButtonPlaybackState == .playing)
    }
    
    @Test
    mutating func reportError() {
        #expect(audioPlayerState.playbackState == .stopped)
        audioPlayerState.reportError()
        #expect(audioPlayerState.playbackState == .error)
    }
    
    @Test
    mutating func updateProgress() async {
        audioPlayerState.attachAudioPlayer(audioPlayerMock)
        
        // If we try to set a negative progress, the new progress must be 0.0
        await audioPlayerState.updateState(progress: -5.0)
        #expect(audioPlayerState.progress == 0.0)
        #expect(audioPlayerMock.seekToReceivedProgress == 0.0)
        
        // If we try to set a progress > 1.0, the new progress must be 1.0
        await audioPlayerState.updateState(progress: 1.5)
        #expect(audioPlayerState.progress == 1.0)
        #expect(audioPlayerMock.seekToReceivedProgress == 1.0)
        
        audioPlayerMock.state = .stopped
        await audioPlayerState.updateState(progress: 0.4)
        #expect(audioPlayerState.progress == 0.4)
        #expect(audioPlayerMock.seekToReceivedProgress == 0.4)
        #expect(!audioPlayerState.isPublishingProgress)
        
        audioPlayerMock.state = .playing
        await audioPlayerState.updateState(progress: 0.4)
        #expect(audioPlayerState.progress == 0.4)
        #expect(audioPlayerMock.seekToReceivedProgress == 0.4)
        #expect(audioPlayerState.isPublishingProgress)
    }
    
    @Test
    func handlingAudioPlayerActionDidStartLoading() async throws {
        audioPlayerState.attachAudioPlayer(audioPlayerMock)
        
        let deferred = deferFulfillment(audioPlayerState.$playbackState) { action in
            switch action {
            case .loading:
                return true
            default:
                return false
            }
        }
        
        audioPlayerActionsSubject.send(.didStartLoading)
        try await deferred.fulfill()
        #expect(audioPlayerState.playbackState == .loading)
    }
    
    @Test
    mutating func handlingAudioPlayerActionDidFinishLoading() async throws {
        audioPlayerMock.duration = 10.0
        
        audioPlayerState = AudioPlayerState(id: .timelineItemIdentifier(.randomEvent), title: "", duration: 0)
        audioPlayerState.attachAudioPlayer(audioPlayerMock)
        
        let deferred = deferFulfillment(audioPlayerState.$playbackState) { action in
            switch action {
            case .readyToPlay:
                return true
            default:
                return false
            }
        }
        
        audioPlayerActionsSubject.send(.didFinishLoading)
        try await deferred.fulfill()
        
        // The state is expected to be .readyToPlay
        #expect(audioPlayerState.playbackState == .readyToPlay)
        // The duration should have been updated with the player's duration
        #expect(audioPlayerState.duration == audioPlayerMock.duration)
    }
    
    @Test
    mutating func handlingAudioPlayerActionDidStartPlaying() async throws {
        await audioPlayerState.updateState(progress: 0.4)
        audioPlayerState.attachAudioPlayer(audioPlayerMock)
        
        let deferred = deferFulfillment(audioPlayerState.$playbackState) { action in
            switch action {
            case .playing:
                return true
            default:
                return false
            }
        }
        
        audioPlayerActionsSubject.send(.didStartPlaying)
        try await deferred.fulfill()
        #expect(audioPlayerMock.seekToReceivedProgress == 0.4)
        #expect(audioPlayerState.playbackState == .playing)
        #expect(audioPlayerState.isPublishingProgress)
        #expect(audioPlayerState.showProgressIndicator)
    }
    
    @Test
    mutating func handlingAudioPlayerActionDidPausePlaying() async throws {
        await audioPlayerState.updateState(progress: 0.4)
        audioPlayerState.attachAudioPlayer(audioPlayerMock)
        
        let deferred = deferFulfillment(audioPlayerState.$playbackState) { action in
            switch action {
            case .stopped:
                return true
            default:
                return false
            }
        }
        
        audioPlayerActionsSubject.send(.didPausePlaying)
        try await deferred.fulfill()
        #expect(audioPlayerState.playbackState == .stopped)
        #expect(audioPlayerState.progress == 0.4)
        #expect(!audioPlayerState.isPublishingProgress)
        #expect(audioPlayerState.showProgressIndicator)
    }
    
    @Test
    mutating func handlingAudioPlayerActionsidStopPlaying() async throws {
        await audioPlayerState.updateState(progress: 0.4)
        audioPlayerState.attachAudioPlayer(audioPlayerMock)
        
        let deferred = deferFulfillment(audioPlayerState.$playbackState) { action in
            switch action {
            case .stopped:
                return true
            default:
                return false
            }
        }
        
        audioPlayerActionsSubject.send(.didStopPlaying)
        try await deferred.fulfill()
        #expect(audioPlayerState.playbackState == .stopped)
        #expect(audioPlayerState.progress == 0.4)
        #expect(!audioPlayerState.isPublishingProgress)
        #expect(audioPlayerState.showProgressIndicator)
    }
    
    @Test
    mutating func audioPlayerActionsDidFinishPlaying() async throws {
        await audioPlayerState.updateState(progress: 0.4)
        audioPlayerState.attachAudioPlayer(audioPlayerMock)
        
        let deferred = deferFulfillment(audioPlayerState.$playbackState) { action in
            switch action {
            case .stopped:
                return true
            default:
                return false
            }
        }
        
        audioPlayerActionsSubject.send(.didFinishPlaying)
        try await deferred.fulfill()
        #expect(audioPlayerState.playbackState == .stopped)
        // Progress should be reset to 0
        #expect(audioPlayerState.progress == 0.0)
        #expect(!audioPlayerState.isPublishingProgress)
        #expect(!audioPlayerState.showProgressIndicator)
    }
    
    @Test
    func setPlaybackSpeed() {
        audioPlayerState.attachAudioPlayer(audioPlayerMock)

        #expect(audioPlayerState.playbackSpeed == .default)

        audioPlayerState.setPlaybackSpeed(.fast)
        #expect(audioPlayerState.playbackSpeed == .fast)
        #expect(audioPlayerMock.setPlaybackSpeedReceivedSpeed == 1.5)

        audioPlayerState.setPlaybackSpeed(.fastest)
        #expect(audioPlayerState.playbackSpeed == .fastest)
        #expect(audioPlayerMock.setPlaybackSpeedReceivedSpeed == 2.0)

        audioPlayerState.setPlaybackSpeed(.slow)
        #expect(audioPlayerState.playbackSpeed == .slow)
        #expect(audioPlayerMock.setPlaybackSpeedReceivedSpeed == 0.5)
    }

    @Test
    func audioPlayerActionsDidFailed() async throws {
        audioPlayerState.attachAudioPlayer(audioPlayerMock)
        
        let deferredPlayingState = deferFulfillment(audioPlayerState.$playbackState) { action in
            switch action {
            case .playing:
                return true
            default:
                return false
            }
        }
        audioPlayerActionsSubject.send(.didStartPlaying)
        try await deferredPlayingState.fulfill()
        #expect(!audioPlayerState.showProgressIndicator)
        
        let deferred = deferFulfillment(audioPlayerState.$playbackState) { action in
            switch action {
            case .error:
                return true
            default:
                return false
            }
        }
        
        audioPlayerActionsSubject.send(.didFailWithError(error: AudioPlayerError.genericError))
        try await deferred.fulfill()
        #expect(audioPlayerState.playbackState == .error)
        #expect(!audioPlayerState.isPublishingProgress)
        #expect(!audioPlayerState.showProgressIndicator)
    }
}
