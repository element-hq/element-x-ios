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
@testable import ElementX
import Foundation
import XCTest

@MainActor
class MediaPlayerProviderTests: XCTestCase {
    private var mediaPlayerProvider: MediaPlayerProvider!
    
    private let oggMimeType = "audio/ogg"
    private let someURL = URL("/some/url")
    private let someOtherURL = URL("/some/other/url")
    
    override func setUp() async throws {
        mediaPlayerProvider = MediaPlayerProvider()
    }
    
    func testPlayerForWrongMediaType() async throws {
        let mediaSourceWithoutMimeType = MediaSourceProxy(url: someURL, mimeType: nil)
        switch mediaPlayerProvider.player(for: mediaSourceWithoutMimeType) {
        case .failure(.unsupportedMediaType):
            // Ok
            break
        default:
            XCTFail("An error is expected")
        }

        let mediaSourceVideo = MediaSourceProxy(url: someURL, mimeType: "video/mp4")
        switch mediaPlayerProvider.player(for: mediaSourceVideo) {
        case .failure(.unsupportedMediaType):
            // Ok
            break
        default:
            XCTFail("An error is expected")
        }
    }
    
    func testPlayerFor() async throws {
        let mediaSource = MediaSourceProxy(url: someURL, mimeType: oggMimeType)
        guard case .success(let playerA) = mediaPlayerProvider.player(for: mediaSource) else {
            XCTFail("A valid player is expected")
            return
        }
        
        // calling it again with another mediasource must returns the same player
        let otherMediaSource = MediaSourceProxy(url: someOtherURL, mimeType: oggMimeType)
        guard case .success(let playerB) = mediaPlayerProvider.player(for: otherMediaSource) else {
            XCTFail("A valid player is expected")
            return
        }

        XCTAssert(playerA === playerB)
    }
    
    func testPlayerStates() async throws {
        let audioPlayerStateId = AudioPlayerStateIdentifier.timelineItemIdentifier(.random)
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
        
        let audioPlayerStates = Array(repeating: AudioPlayerState(id: .timelineItemIdentifier(.random), title: "", duration: 0), count: 10)
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
        
        let audioPlayerStates = Array(repeating: AudioPlayerState(id: .timelineItemIdentifier(.random), title: "", duration: 0), count: 10)
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
