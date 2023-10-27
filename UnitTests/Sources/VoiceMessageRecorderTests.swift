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
        audioRecorder.recordWithReturnValue = .success(())
        audioRecorder.underlyingCurrentTime = 0
        audioRecorder.averagePowerForChannelNumberReturnValue = 0
        audioPlayer = AudioPlayerMock()
        audioPlayer.actions = audioPlayerActions
        audioPlayer.state = .stopped
        
        mediaPlayerProvider = MediaPlayerProviderMock()
        mediaPlayerProvider.playerForClosure = { _ in
            .success(self.audioPlayer)
        }
        audioConverter = AudioConverterMock()
        voiceMessageCache = VoiceMessageCacheMock()
        
        voiceMessageRecorder = VoiceMessageRecorder(audioRecorder: audioRecorder,
                                                    mediaPlayerProvider: mediaPlayerProvider,
                                                    audioConverter: audioConverter,
                                                    voiceMessageCache: voiceMessageCache)
    }
        
    func testStartRecording() async throws {
        audioRecorder.url = recordingURL
        _ = await voiceMessageRecorder.startRecording()
        XCTAssert(audioRecorder.recordWithCalled)
        XCTAssertEqual(voiceMessageRecorder.recordingURL, audioRecorder.url)
    }
    
    func testStopRecording() async throws {
        audioRecorder.isRecording = true
        audioRecorder.currentTime = 14.0
        audioRecorder.url = recordingURL
        
        _ = await voiceMessageRecorder.startRecording()
        _ = await voiceMessageRecorder.stopRecording()
        
        // Internal audio recorder must have been stopped
        XCTAssert(audioRecorder.stopRecordingCalled)
        
        // A preview player state must be available
        let previewPlayerState = voiceMessageRecorder.previewAudioPlayerState
        XCTAssertNotNil(previewPlayerState)
        XCTAssertEqual(previewPlayerState?.duration, audioRecorder.currentTime)
    }
    
    func testCancelRecording() async throws {
        audioRecorder.isRecording = true
        
        await voiceMessageRecorder.cancelRecording()
        
        // The recording audio file must have been deleted
        XCTAssert(audioRecorder.deleteRecordingCalled)
    }
    
    func testDeleteRecording() async throws {
        await voiceMessageRecorder.deleteRecording()
        XCTAssert(audioRecorder.deleteRecordingCalled)
    }
    
    func testStartPlayback() async throws {
        audioRecorder.url = recordingURL
        _ = await voiceMessageRecorder.startRecording()
        _ = await voiceMessageRecorder.stopRecording()

        // if the player url doesn't match the recording url
        guard case .success = await voiceMessageRecorder.startPlayback() else {
            XCTFail("Playback should start")
            return
        }
        
        XCTAssert(audioPlayer.loadMediaSourceUsingAutoplayCalled)
        XCTAssertEqual(audioPlayer.loadMediaSourceUsingAutoplayReceivedArguments?.url, recordingURL)
        XCTAssertEqual(audioPlayer.loadMediaSourceUsingAutoplayReceivedArguments?.mediaSource.mimeType, "audio/m4a")
        XCTAssertEqual(audioPlayer.loadMediaSourceUsingAutoplayReceivedArguments?.mediaSource.url, recordingURL)
        XCTAssertEqual(audioPlayer.loadMediaSourceUsingAutoplayReceivedArguments?.autoplay, true)
        XCTAssertFalse(audioPlayer.playCalled)
    }
    
    func testResumePlayback() async throws {
        audioRecorder.url = recordingURL
        _ = await voiceMessageRecorder.startRecording()
        _ = await voiceMessageRecorder.stopRecording()
        
        // if the player url matches the recording url
        audioPlayer.url = recordingURL
        guard case .success = await voiceMessageRecorder.startPlayback() else {
            XCTFail("Playback should start")
            return
        }
        
        XCTAssertFalse(audioPlayer.loadMediaSourceUsingAutoplayCalled)
        XCTAssert(audioPlayer.playCalled)
    }
    
    func testPausePlayback() async throws {
        audioRecorder.url = recordingURL
        switch await voiceMessageRecorder.startRecording() {
        case .failure(let error):
            XCTFail("Recording should start. \(error)")
        case .success:
            break
        }
        _ = await voiceMessageRecorder.stopRecording()

        voiceMessageRecorder.pausePlayback()
        XCTAssert(audioPlayer.pauseCalled)
    }
    
    func testStopPlayback() async throws {
        audioRecorder.url = recordingURL
        _ = await voiceMessageRecorder.startRecording()
        _ = await voiceMessageRecorder.stopRecording()
        
        await voiceMessageRecorder.stopPlayback()
        XCTAssertEqual(voiceMessageRecorder.previewAudioPlayerState?.isAttached, false)
        XCTAssert(audioPlayer.stopCalled)
    }
    
    func testSeekPlayback() async throws {
        audioRecorder.url = recordingURL
        // Calling stop will generate the preview player state needed to have an audio player
        _ = await voiceMessageRecorder.startRecording()
        _ = await voiceMessageRecorder.stopRecording()
        voiceMessageRecorder.previewAudioPlayerState?.attachAudioPlayer(audioPlayer)
        
        await voiceMessageRecorder.seekPlayback(to: 0.4)
        XCTAssert(audioPlayer.seekToCalled)
        XCTAssertEqual(audioPlayer.seekToReceivedProgress, 0.4)
    }
    
    func testBuildRecordedWaveform() async throws {
        guard let audioFileUrl = Bundle(for: Self.self).url(forResource: "test_audio", withExtension: "mp3") else {
            XCTFail("Test audio file is missing")
            return
        }
        audioRecorder.url = audioFileUrl
        _ = await voiceMessageRecorder.startRecording()
        _ = await voiceMessageRecorder.stopRecording()
        
        guard case .success(let data) = await voiceMessageRecorder.buildRecordingWaveform() else {
            XCTFail("A waveform is expected")
            return
        }
        XCTAssert(!data.isEmpty)
    }
    
    func testSendVoiceMessage() async throws {
        guard let audioFileUrl = Bundle(for: Self.self).url(forResource: "test_voice_message", withExtension: "m4a") else {
            XCTFail("Test audio file is missing")
            return
        }
        audioRecorder.currentTime = 42
        audioRecorder.url = audioFileUrl
        _ = await voiceMessageRecorder.startRecording()
        _ = await voiceMessageRecorder.stopRecording()
        
        let roomProxy = RoomProxyMock()
        let audioConverter = AudioConverterMock()
        var convertedFileUrl: URL?
        var convertedFileSize: UInt64?
        
        audioConverter.convertToOpusOggSourceURLDestinationURLClosure = { source, destination in
            convertedFileUrl = destination
            try? FileManager.default.removeItem(at: destination)
            let internalConverter = AudioConverter()
            try internalConverter.convertToOpusOgg(sourceURL: source, destinationURL: destination)
            convertedFileSize = try? UInt64(FileManager.default.sizeForItem(at: destination))
            // the source URL must be the recorded file
            XCTAssertEqual(source, audioFileUrl)
            // check the converted file extension
            XCTAssertEqual(destination.pathExtension, "ogg")
        }
        
        roomProxy.sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleClosure = { url, audioInfo, waveform, _, _ in
            XCTAssertEqual(url, convertedFileUrl)
            XCTAssertEqual(audioInfo.duration, self.audioRecorder.currentTime)
            XCTAssertEqual(audioInfo.size, convertedFileSize)
            XCTAssertEqual(audioInfo.mimetype, "audio/ogg")
            XCTAssertFalse(waveform.isEmpty)
            
            return .success(())
        }
        
        guard case .success = await voiceMessageRecorder.sendVoiceMessage(inRoom: roomProxy, audioConverter: audioConverter) else {
            XCTFail("A success is expected")
            return
        }
        
        XCTAssert(audioConverter.convertToOpusOggSourceURLDestinationURLCalled)
        XCTAssert(roomProxy.sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleCalled)
        
        // the converted file must have been deleted
        if let convertedFileUrl {
            XCTAssertFalse(FileManager.default.fileExists(atPath: convertedFileUrl.path()))
        } else {
            XCTFail("converted file URL is missing")
        }
    }
}
