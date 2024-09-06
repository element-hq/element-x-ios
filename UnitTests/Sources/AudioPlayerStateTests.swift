//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
@testable import ElementX
import Foundation
import XCTest

@MainActor
class AudioPlayerStateTests: XCTestCase {
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
        audioPlayerMock.seekToClosure = { [audioPlayerSeekCallsSubject] progress in
            audioPlayerSeekCallsSubject?.send(progress)
        }
        return audioPlayerMock
    }
    
    override func setUp() async throws {
        audioPlayerActionsSubject = .init()
        audioPlayerSeekCallsSubject = .init()
        audioPlayerState = AudioPlayerState(id: .timelineItemIdentifier(.random), title: "", duration: Self.audioDuration)
        audioPlayerMock = buildAudioPlayerMock()
        audioPlayerMock.seekToClosure = { [weak self] progress in
            self?.audioPlayerMock.currentTime = Self.audioDuration * progress
        }
    }
    
    func testAttach() async throws {
        audioPlayerState.attachAudioPlayer(audioPlayerMock)
        
        XCTAssert(audioPlayerState.isAttached)
        XCTAssertEqual(audioPlayerState.playbackState, .loading)
    }
    
    func testDetach() async throws {
        audioPlayerState.attachAudioPlayer(audioPlayerMock)
        
        audioPlayerState.detachAudioPlayer()
        XCTAssert(audioPlayerMock.stopCalled)
        XCTAssertFalse(audioPlayerState.isAttached)
        XCTAssertEqual(audioPlayerState.playbackState, .stopped)
        XCTAssertFalse(audioPlayerState.showProgressIndicator)
    }
    
    func testDelayedState() async throws {
        audioPlayerState.attachAudioPlayer(audioPlayerMock)
        
        XCTAssert(audioPlayerState.isAttached)
        XCTAssertEqual(audioPlayerState.playbackState, .loading)
        XCTAssertEqual(audioPlayerState.playerButtonPlaybackState, .stopped)
        
        let deferred = deferFulfillment(audioPlayerState.$playerButtonPlaybackState) { output in
            switch output {
            case .loading:
                return true
            default:
                return false
            }
        }
        try await deferred.fulfill()
        
        XCTAssertEqual(audioPlayerState.playerButtonPlaybackState, .loading)
    }
    
    func testOtherActionsAreNotDelayed() async throws {
        audioPlayerState.attachAudioPlayer(audioPlayerMock)
        XCTAssertEqual(audioPlayerState.playbackState, .loading)
        XCTAssertEqual(audioPlayerState.playerButtonPlaybackState, .stopped)
        
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
        XCTAssertEqual(audioPlayerState.playbackState, .playing)
        XCTAssertEqual(audioPlayerState.playerButtonPlaybackState, .playing)
    }
    
    func testReportError() async throws {
        XCTAssertEqual(audioPlayerState.playbackState, .stopped)
        audioPlayerState.reportError()
        XCTAssertEqual(audioPlayerState.playbackState, .error)
    }
    
    func testUpdateProgress() async throws {
        audioPlayerState.attachAudioPlayer(audioPlayerMock)

        // If we try to set a negative progress, the new progress must be 0.0
        do {
            await audioPlayerState.updateState(progress: -5.0)
            XCTAssertEqual(audioPlayerState.progress, 0.0)
            XCTAssertEqual(audioPlayerMock.seekToReceivedProgress, 0.0)
        }

        // If we try to set a progress > 1.0, the new progress must be 1.0
        do {
            await audioPlayerState.updateState(progress: 1.5)
            XCTAssertEqual(audioPlayerState.progress, 1.0)
            XCTAssertEqual(audioPlayerMock.seekToReceivedProgress, 1.0)
        }
        
        do {
            audioPlayerMock.state = .stopped
            await audioPlayerState.updateState(progress: 0.4)
            XCTAssertEqual(audioPlayerState.progress, 0.4)
            XCTAssertEqual(audioPlayerMock.seekToReceivedProgress, 0.4)
            XCTAssertFalse(audioPlayerState.isPublishingProgress)
        }

        do {
            audioPlayerMock.state = .playing
            await audioPlayerState.updateState(progress: 0.4)
            XCTAssertEqual(audioPlayerState.progress, 0.4)
            XCTAssertEqual(audioPlayerMock.seekToReceivedProgress, 0.4)
            XCTAssert(audioPlayerState.isPublishingProgress)
        }
    }

    func testHandlingAudioPlayerActionDidStartLoading() async throws {
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
        XCTAssertEqual(audioPlayerState.playbackState, .loading)
    }

    func testHandlingAudioPlayerActionDidFinishLoading() async throws {
        audioPlayerMock.duration = 10.0
        
        audioPlayerState = AudioPlayerState(id: .timelineItemIdentifier(.random), title: "", duration: 0)
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
        XCTAssertEqual(audioPlayerState.playbackState, .readyToPlay)
        // The duration should have been updated with the player's duration
        XCTAssertEqual(audioPlayerState.duration, audioPlayerMock.duration)
    }
    
    func testHandlingAudioPlayerActionDidStartPlaying() async throws {
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
        XCTAssertEqual(audioPlayerMock.seekToReceivedProgress, 0.4)
        XCTAssertEqual(audioPlayerState.playbackState, .playing)
        XCTAssert(audioPlayerState.isPublishingProgress)
        XCTAssert(audioPlayerState.showProgressIndicator)
    }
    
    func testHandlingAudioPlayerActionDidPausePlaying() async throws {
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
        XCTAssertEqual(audioPlayerState.playbackState, .stopped)
        XCTAssertEqual(audioPlayerState.progress, 0.4)
        XCTAssertFalse(audioPlayerState.isPublishingProgress)
        XCTAssert(audioPlayerState.showProgressIndicator)
    }
    
    func testHandlingAudioPlayerActionsidStopPlaying() async throws {
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
        XCTAssertEqual(audioPlayerState.playbackState, .stopped)
        XCTAssertEqual(audioPlayerState.progress, 0.4)
        XCTAssertFalse(audioPlayerState.isPublishingProgress)
        XCTAssert(audioPlayerState.showProgressIndicator)
    }
    
    func testAudioPlayerActionsDidFinishPlaying() async throws {
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
        XCTAssertEqual(audioPlayerState.playbackState, .stopped)
        // Progress should be reset to 0
        XCTAssertEqual(audioPlayerState.progress, 0.0)
        XCTAssertFalse(audioPlayerState.isPublishingProgress)
        XCTAssertFalse(audioPlayerState.showProgressIndicator)
    }
    
    func testAudioPlayerActionsDidFailed() async throws {
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
        XCTAssertFalse(audioPlayerState.showProgressIndicator)

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
        XCTAssertEqual(audioPlayerState.playbackState, .error)
        XCTAssertFalse(audioPlayerState.isPublishingProgress)
        XCTAssertFalse(audioPlayerState.showProgressIndicator)
    }
}
