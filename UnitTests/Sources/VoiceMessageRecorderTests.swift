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
class VoiceMessageRecorderTests: XCTestCase {
    private var voiceMessageRecorder: VoiceMessageRecorder!
    
    private var audioRecorder: AudioRecorderMock!
    private var mediaPlayerProvider: MediaPlayerProviderMock!
    private var audioConverter: AudioConverterMock!
    private var voiceMessageCache: VoiceMessageCacheMock!

    private var audioPlayer: AudioPlayerMock!
    private var audioPlayerActionsSubject: PassthroughSubject<AudioPlayerAction, Never> = .init()
    private var audioPlayerActions: AnyPublisher<AudioPlayerAction, Never> {
        audioPlayerActionsSubject.eraseToAnyPublisher()
    }

    private let recordingURL = URL("/some/url")
    
    override func setUp() async throws {
        audioRecorder = AudioRecorderMock()
        audioRecorder.underlyingCurrentTime = 0
        audioPlayer = AudioPlayerMock()
        audioPlayer.actions = audioPlayerActions
        
        mediaPlayerProvider = MediaPlayerProviderMock()
        mediaPlayerProvider.playerForClosure = { _ in
            self.audioPlayer
        }
        audioConverter = AudioConverterMock()
        voiceMessageCache = VoiceMessageCacheMock()
        
        voiceMessageRecorder = VoiceMessageRecorder(audioRecorder: audioRecorder,
                                                    mediaPlayerProvider: mediaPlayerProvider,
                                                    audioConverter: audioConverter,
                                                    voiceMessageCache: voiceMessageCache)
    }
    
    func testStop() async throws {
        audioRecorder.isRecording = true
        audioRecorder.url = recordingURL
        try await voiceMessageRecorder.stop()
        XCTAssert(audioRecorder.stopRecordingCalled)
        XCTAssert(audioPlayer.stopCalled)
    }
    
    func testStartRecording() async throws {
        audioRecorder.url = recordingURL
        let returnedAudioRecorder = voiceMessageRecorder.startRecording()
        XCTAssert(audioRecorder.recordCalled)
        XCTAssertEqual(returnedAudioRecorder.url, audioRecorder.url)
    }
    
    func testStopRecording() async throws {
        audioRecorder.isRecording = true
        audioRecorder.currentTime = 14.0
        audioRecorder.url = recordingURL
        
        try await voiceMessageRecorder.stopRecording()
        
        // Internal audio recorder must have been stopped
        XCTAssert(audioRecorder.stopRecordingCalled)
        
        // A preview player state must be available
        let previewPlayerState = voiceMessageRecorder.previewPlayerState
        XCTAssertNotNil(previewPlayerState)
        XCTAssertEqual(previewPlayerState?.duration, audioRecorder.currentTime)
    }
    
    func testCancelRecording() async throws {
        audioRecorder.isRecording = true
        
        try await voiceMessageRecorder.cancelRecording()
        
        // The recording audio file must have been deleted
        XCTAssert(audioRecorder.deleteRecordingCalled)
    }
    
    func testStartPlayback() async throws {
        audioRecorder.isRecording = false
        audioRecorder.url = recordingURL

        // Calling stop will generate the preview player state
        try await voiceMessageRecorder.stopRecording()

        // if the player url doesn't match the recording url
        audioPlayer.url = nil
        try await voiceMessageRecorder.startPlayback()
        
        XCTAssert(audioPlayer.loadMediaSourceUsingAutoplayCalled)
        XCTAssertEqual(audioPlayer.loadMediaSourceUsingAutoplayReceivedArguments?.url, recordingURL)
        XCTAssertEqual(audioPlayer.loadMediaSourceUsingAutoplayReceivedArguments?.mediaSource.mimeType, "audio/m4a")
        XCTAssertEqual(audioPlayer.loadMediaSourceUsingAutoplayReceivedArguments?.mediaSource.url, recordingURL)
        XCTAssertEqual(audioPlayer.loadMediaSourceUsingAutoplayReceivedArguments?.autoplay, true)
        XCTAssertFalse(audioPlayer.playCalled)
    }
    
    func testResumePlayback() async throws {
        audioRecorder.isRecording = false
        audioRecorder.url = recordingURL

        // Calling stop will generate the preview player state
        try await voiceMessageRecorder.stopRecording()

        // if the player url matches the recording url
        audioPlayer.url = recordingURL
        try await voiceMessageRecorder.startPlayback()
        
        XCTAssertFalse(audioPlayer.loadMediaSourceUsingAutoplayCalled)
        XCTAssert(audioPlayer.playCalled)
    }
    
    func testPausePlayback() async throws {
        audioRecorder.url = recordingURL

        // Calling stop will generate the preview player state needed to have an audio player
        try await voiceMessageRecorder.stopRecording()

        voiceMessageRecorder.pausePlayback()
        XCTAssert(audioPlayer.pauseCalled)
    }
    
    func testStopPlayback() async throws {
        audioRecorder.url = recordingURL

        // Calling stop will generate the preview player state needed to have an audio player
        try await voiceMessageRecorder.stopRecording()
        
        await voiceMessageRecorder.stopPlayback()
        XCTAssertEqual(voiceMessageRecorder.previewPlayerState?.isAttached, false)
        XCTAssert(audioPlayer.stopCalled)
    }
    
    func testSeekPlayback() async throws {
        audioRecorder.url = recordingURL
        
        // Calling stop will generate the preview player state needed to have an audio player
        try await voiceMessageRecorder.stopRecording()
        voiceMessageRecorder.previewPlayerState?.attachAudioPlayer(audioPlayer)
        
        await voiceMessageRecorder.seekPlayback(to: 0.4)
        XCTAssert(audioPlayer.seekToCalled)
        XCTAssertEqual(audioPlayer.seekToReceivedProgress, 0.4)
    }
    
    func testDeleteRecording() async throws {
        voiceMessageRecorder.deleteRecording()
        XCTAssert(audioRecorder.deleteRecordingCalled)
    }
}
