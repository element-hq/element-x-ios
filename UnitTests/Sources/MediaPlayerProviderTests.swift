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
struct MediaPlayerProviderTests {
    private var mediaPlayerProvider: MediaPlayerProvider
    
    private let oggMimeType = "audio/ogg"
    private let someURL = URL.mockMXCAudio
    private let someOtherURL = URL.mockMXCFile
    
    init() async {
        mediaPlayerProvider = MediaPlayerProvider()
    }
    
    @Test
    func playerStates() {
        let audioPlayerStateId = AudioPlayerStateIdentifier.timelineItemIdentifier(.randomEvent)
        // By default, there should be no player state
        #expect(mediaPlayerProvider.playerState(for: audioPlayerStateId) == nil)
        
        let audioPlayerState = AudioPlayerState(id: audioPlayerStateId, title: "", duration: 10.0)
        mediaPlayerProvider.register(audioPlayerState: audioPlayerState)
        #expect(audioPlayerState == mediaPlayerProvider.playerState(for: audioPlayerStateId))
        
        mediaPlayerProvider.unregister(audioPlayerState: audioPlayerState)
        #expect(mediaPlayerProvider.playerState(for: audioPlayerStateId) == nil)
    }
    
    @Test
    func detachAllStates() {
        let audioPlayer = AudioPlayerMock()
        audioPlayer.actions = PassthroughSubject<AudioPlayerAction, Never>().eraseToAnyPublisher()
        
        let audioPlayerStates = Array(repeating: AudioPlayerState(id: .timelineItemIdentifier(.randomEvent), title: "", duration: 0), count: 10)
        for audioPlayerState in audioPlayerStates {
            mediaPlayerProvider.register(audioPlayerState: audioPlayerState)
            audioPlayerState.attachAudioPlayer(audioPlayer)
            let isAttached = audioPlayerState.isAttached
            #expect(isAttached)
        }
        
        mediaPlayerProvider.detachAllStates(except: nil)
        for audioPlayerState in audioPlayerStates {
            let isAttached = audioPlayerState.isAttached
            #expect(!isAttached)
        }
    }
    
    @Test
    func detachAllStatesWithException() {
        let audioPlayer = AudioPlayerMock()
        audioPlayer.actions = PassthroughSubject<AudioPlayerAction, Never>().eraseToAnyPublisher()
        
        let audioPlayerStates = Array(repeating: AudioPlayerState(id: .timelineItemIdentifier(.randomEvent), title: "", duration: 0), count: 10)
        for audioPlayerState in audioPlayerStates {
            mediaPlayerProvider.register(audioPlayerState: audioPlayerState)
            audioPlayerState.attachAudioPlayer(audioPlayer)
            let isAttached = audioPlayerState.isAttached
            #expect(isAttached)
        }
        
        let exception = audioPlayerStates[1]
        mediaPlayerProvider.detachAllStates(except: exception)
        for audioPlayerState in audioPlayerStates {
            let isAttached = audioPlayerState.isAttached
            if audioPlayerState == exception {
                #expect(isAttached)
            } else {
                #expect(!isAttached)
            }
        }
    }
}
