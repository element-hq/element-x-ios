//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Foundation
import XCTest

@MainActor
class MediaPlayerProviderTests: XCTestCase {
    private var mediaPlayerProvider: MediaPlayerProvider!
    
    private let oggMimeType = "audio/ogg"
    private let someURL = URL.mockMXCAudio
    private let someOtherURL = URL.mockMXCFile
    
    override func setUp() async throws {
        mediaPlayerProvider = MediaPlayerProvider()
    }
    
    func testPlayerStates() async throws {
        let audioPlayerStateId = AudioPlayerStateIdentifier.timelineItemIdentifier(.randomEvent)
        // By default, there should be no player state
        XCTAssertNil(mediaPlayerProvider.playerState(for: audioPlayerStateId))
        
        let audioPlayerState = AudioPlayerState(id: audioPlayerStateId, title: "", duration: 10.0)
        mediaPlayerProvider.register(audioPlayerState: audioPlayerState)
        XCTAssertEqual(audioPlayerState, mediaPlayerProvider.playerState(for: audioPlayerStateId))
        
        mediaPlayerProvider.unregister(audioPlayerState: audioPlayerState)
        XCTAssertNil(mediaPlayerProvider.playerState(for: audioPlayerStateId))
    }
    
    func testDetachAllStates() async throws {
        let audioPlayer = AudioPlayerMock()
        audioPlayer.actions = PassthroughSubject<AudioPlayerAction, Never>().eraseToAnyPublisher()
        
        let audioPlayerStates = Array(repeating: AudioPlayerState(id: .timelineItemIdentifier(.randomEvent), title: "", duration: 0), count: 10)
        for audioPlayerState in audioPlayerStates {
            mediaPlayerProvider.register(audioPlayerState: audioPlayerState)
            audioPlayerState.attachAudioPlayer(audioPlayer)
            let isAttached = audioPlayerState.isAttached
            XCTAssertTrue(isAttached)
        }
        
        mediaPlayerProvider.detachAllStates(except: nil)
        for audioPlayerState in audioPlayerStates {
            let isAttached = audioPlayerState.isAttached
            XCTAssertFalse(isAttached)
        }
    }
    
    func testDetachAllStatesWithException() async throws {
        let audioPlayer = AudioPlayerMock()
        audioPlayer.actions = PassthroughSubject<AudioPlayerAction, Never>().eraseToAnyPublisher()
        
        let audioPlayerStates = Array(repeating: AudioPlayerState(id: .timelineItemIdentifier(.randomEvent), title: "", duration: 0), count: 10)
        for audioPlayerState in audioPlayerStates {
            mediaPlayerProvider.register(audioPlayerState: audioPlayerState)
            audioPlayerState.attachAudioPlayer(audioPlayer)
            let isAttached = audioPlayerState.isAttached
            XCTAssertTrue(isAttached)
        }
        
        let exception = audioPlayerStates[1]
        mediaPlayerProvider.detachAllStates(except: exception)
        for audioPlayerState in audioPlayerStates {
            let isAttached = audioPlayerState.isAttached
            if audioPlayerState == exception {
                XCTAssertTrue(isAttached)
            } else {
                XCTAssertFalse(isAttached)
            }
        }
    }
}
