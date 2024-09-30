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
class VoiceMessageRecorderTests: XCTestCase {
    private var voiceMessageRecorder: VoiceMessageRecorder!
    
    private var audioRecorder: AudioRecorderMock!
    private var audioRecorderActionsSubject: PassthroughSubject<AudioRecorderAction, Never> = .init()
    private var audioRecorderActions: AnyPublisher<AudioRecorderAction, Never> {
        audioRecorderActionsSubject.eraseToAnyPublisher()
    }

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
        audioRecorder.averagePowerReturnValue = 0
        audioRecorder.actions = audioRecorderActions
        
        audioPlayer = AudioPlayerMock()
        audioPlayer.actions = audioPlayerActions
        audioPlayer.state = .stopped
        
        mediaPlayerProvider = MediaPlayerProviderMock()
        mediaPlayerProvider.playerForClosure = { _ in
            .success(self.audioPlayer)
        }
        audioConverter = AudioConverterMock()
        voiceMessageCache = VoiceMessageCacheMock()
        voiceMessageCache.urlForRecording = FileManager.default.temporaryDirectory.appendingPathComponent("test-voice-message").appendingPathExtension("m4a")
        
        voiceMessageRecorder = VoiceMessageRecorder(audioRecorder: audioRecorder,
                                                    mediaPlayerProvider: mediaPlayerProvider,
                                                    voiceMessageCache: voiceMessageCache)
    }
    
    private func setRecordingComplete() async throws {
        audioRecorder.audioFileURL = recordingURL
        audioRecorder.currentTime = 5

        let deferred = deferFulfillment(voiceMessageRecorder.actions) { action in
            switch action {
            case .didStopRecording(_, let url) where url == self.recordingURL:
                return true
            default:
                return false
            }
        }
        audioRecorderActionsSubject.send(.didStopRecording)
        try await deferred.fulfill()
    }
    
    func testRecordingURL() async throws {
        audioRecorder.audioFileURL = recordingURL
        XCTAssertEqual(voiceMessageRecorder.recordingURL, recordingURL)
    }
    
    func testRecordingDuration() async throws {
        audioRecorder.currentTime = 10.3
        XCTAssertEqual(voiceMessageRecorder.recordingDuration, 10.3)
    }
    
    func testStartRecording() async throws {
        _ = await voiceMessageRecorder.startRecording()
        XCTAssert(audioRecorder.recordAudioFileURLCalled)
    }
    
    func testStopRecording() async throws {
        _ = await voiceMessageRecorder.stopRecording()
        // Internal audio recorder must have been stopped
        XCTAssert(audioRecorder.stopRecordingCalled)
    }
    
    func testCancelRecording() async throws {
        await voiceMessageRecorder.cancelRecording()
        // Internal audio recorder must have been stopped
        XCTAssert(audioRecorder.stopRecordingCalled)
        // The recording audio file must have been deleted
        XCTAssert(audioRecorder.deleteRecordingCalled)
    }

    func testDeleteRecording() async throws {
        await voiceMessageRecorder.deleteRecording()
        // The recording audio file must have been deleted
        XCTAssert(audioRecorder.deleteRecordingCalled)
    }

    func testStartPlaybackNoPreview() async throws {
        guard case .failure(.previewNotAvailable) = await voiceMessageRecorder.startPlayback() else {
            XCTFail("An error is expected")
            return
        }
    }
    
    func testStartPlayback() async throws {
        try await setRecordingComplete()
        
        guard case .success = await voiceMessageRecorder.startPlayback() else {
            XCTFail("Playback should start")
            return
        }
        XCTAssertEqual(voiceMessageRecorder.previewAudioPlayerState?.isAttached, true)
        XCTAssert(audioPlayer.loadMediaSourceUsingAutoplayCalled)
        XCTAssertEqual(audioPlayer.loadMediaSourceUsingAutoplayReceivedArguments?.url, recordingURL)
        XCTAssertEqual(audioPlayer.loadMediaSourceUsingAutoplayReceivedArguments?.mediaSource.mimeType, "audio/m4a")
        XCTAssertEqual(audioPlayer.loadMediaSourceUsingAutoplayReceivedArguments?.mediaSource.url, recordingURL)
        XCTAssertEqual(audioPlayer.loadMediaSourceUsingAutoplayReceivedArguments?.autoplay, true)
        XCTAssertFalse(audioPlayer.playCalled)
    }
    
    func testPausePlayback() async throws {
        try await setRecordingComplete()

        _ = await voiceMessageRecorder.startPlayback()
        XCTAssertEqual(voiceMessageRecorder.previewAudioPlayerState?.isAttached, true)

        voiceMessageRecorder.pausePlayback()
        XCTAssert(audioPlayer.pauseCalled)
    }
    
    func testResumePlayback() async throws {
        try await setRecordingComplete()
        audioPlayer.url = recordingURL

        guard case .success = await voiceMessageRecorder.startPlayback() else {
            XCTFail("Playback should start")
            return
        }
        XCTAssertEqual(voiceMessageRecorder.previewAudioPlayerState?.isAttached, true)
        // The media must not have been reloaded
        XCTAssertFalse(audioPlayer.loadMediaSourceUsingAutoplayCalled)
        XCTAssertTrue(audioPlayer.playCalled)
    }

    func testStopPlayback() async throws {
        try await setRecordingComplete()

        _ = await voiceMessageRecorder.startPlayback()
        XCTAssertEqual(voiceMessageRecorder.previewAudioPlayerState?.isAttached, true)
        
        await voiceMessageRecorder.stopPlayback()
        XCTAssertEqual(voiceMessageRecorder.previewAudioPlayerState?.isAttached, false)
        XCTAssert(audioPlayer.stopCalled)
    }
    
    func testSeekPlayback() async throws {
        try await setRecordingComplete()

        _ = await voiceMessageRecorder.startPlayback()
        XCTAssertEqual(voiceMessageRecorder.previewAudioPlayerState?.isAttached, true)

        await voiceMessageRecorder.seekPlayback(to: 0.4)
        XCTAssertEqual(audioPlayer.seekToReceivedProgress, 0.4)
    }
    
    func testBuildRecordedWaveform() async throws {
        // If there is no recording file, an error is expected
        audioRecorder.audioFileURL = nil
        guard case .failure(.missingRecordingFile) = await voiceMessageRecorder.buildRecordingWaveform() else {
            XCTFail("An error is expected")
            return
        }
        
        guard let audioFileURL = Bundle(for: Self.self).url(forResource: "test_audio", withExtension: "mp3") else {
            XCTFail("Test audio file is missing")
            return
        }
        audioRecorder.audioFileURL = audioFileURL
        guard case .success(let data) = await voiceMessageRecorder.buildRecordingWaveform() else {
            XCTFail("A waveform is expected")
            return
        }
        XCTAssert(!data.isEmpty)
    }
    
    func testSendVoiceMessage_NoRecordingFile() async throws {
        let roomProxy = JoinedRoomProxyMock()

        // If there is no recording file, an error is expected
        audioRecorder.audioFileURL = nil
        guard case .failure(.missingRecordingFile) = await voiceMessageRecorder.sendVoiceMessage(inRoom: roomProxy, audioConverter: audioConverter) else {
            XCTFail("An error is expected")
            return
        }
    }
    
    func testSendVoiceMessage_ConversionError() async throws {
        audioRecorder.audioFileURL = recordingURL
        // If the converter returns an error
        audioConverter.convertToOpusOggSourceURLDestinationURLThrowableError = AudioConverterError.conversionFailed(nil)
        
        let roomProxy = JoinedRoomProxyMock()
        guard case .failure(.failedSendingVoiceMessage) = await voiceMessageRecorder.sendVoiceMessage(inRoom: roomProxy, audioConverter: audioConverter) else {
            XCTFail("An error is expected")
            return
        }
    }
    
    func testSendVoiceMessage_InvalidFile() async throws {
        guard let audioFileURL = Bundle(for: Self.self).url(forResource: "test_voice_message", withExtension: "m4a") else {
            XCTFail("Test audio file is missing")
            return
        }
        audioRecorder.audioFileURL = audioFileURL
        audioConverter.convertToOpusOggSourceURLDestinationURLClosure = { _, destination in
            try? FileManager.default.removeItem(at: destination)
        }
        
        let timelineProxy = TimelineProxyMock()
        let roomProxy = JoinedRoomProxyMock()
        roomProxy.timeline = timelineProxy
        timelineProxy.sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleReturnValue = .failure(.sdkError(SDKError.generic))
        guard case .failure(.failedSendingVoiceMessage) = await voiceMessageRecorder.sendVoiceMessage(inRoom: roomProxy, audioConverter: audioConverter) else {
            XCTFail("An error is expected")
            return
        }
    }
    
    func testSendVoiceMessage_WaveformAnlyseFailed() async throws {
        guard let imageFileURL = Bundle(for: Self.self).url(forResource: "test_image", withExtension: "png") else {
            XCTFail("Test audio file is missing")
            return
        }
        audioRecorder.audioFileURL = imageFileURL
        audioConverter.convertToOpusOggSourceURLDestinationURLClosure = { _, destination in
            try? FileManager.default.removeItem(at: destination)
            try? FileManager.default.copyItem(at: imageFileURL, to: destination)
        }
        
        let timelineProxy = TimelineProxyMock()
        let roomProxy = JoinedRoomProxyMock()
        roomProxy.timeline = timelineProxy
        timelineProxy.sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleReturnValue = .failure(.sdkError(SDKError.generic))
        guard case .failure(.failedSendingVoiceMessage) = await voiceMessageRecorder.sendVoiceMessage(inRoom: roomProxy, audioConverter: audioConverter) else {
            XCTFail("An error is expected")
            return
        }
    }
    
    func testSendVoiceMessage_SendError() async throws {
        guard let audioFileURL = Bundle(for: Self.self).url(forResource: "test_voice_message", withExtension: "m4a") else {
            XCTFail("Test audio file is missing")
            return
        }
        audioRecorder.audioFileURL = audioFileURL
        audioConverter.convertToOpusOggSourceURLDestinationURLClosure = { source, destination in
            try? FileManager.default.removeItem(at: destination)
            let internalConverter = AudioConverter()
            try internalConverter.convertToOpusOgg(sourceURL: source, destinationURL: destination)
        }
        
        // If the media upload fails
        let timelineProxy = TimelineProxyMock()
        let roomProxy = JoinedRoomProxyMock()
        roomProxy.timeline = timelineProxy
        timelineProxy.sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleReturnValue = .failure(.sdkError(SDKError.generic))
        guard case .failure(.failedSendingVoiceMessage) = await voiceMessageRecorder.sendVoiceMessage(inRoom: roomProxy, audioConverter: audioConverter) else {
            XCTFail("An error is expected")
            return
        }
    }
    
    func testSendVoiceMessage() async throws {
        guard let imageFileURL = Bundle(for: Self.self).url(forResource: "test_voice_message", withExtension: "m4a") else {
            XCTFail("Test audio file is missing")
            return
        }
        
        let timelineProxy = TimelineProxyMock()
        let roomProxy = JoinedRoomProxyMock()
        roomProxy.timeline = timelineProxy
        audioRecorder.currentTime = 42
        audioRecorder.audioFileURL = imageFileURL
        _ = await voiceMessageRecorder.startRecording()
        _ = await voiceMessageRecorder.stopRecording()
        
        var convertedFileURL: URL?
        var convertedFileSize: UInt64?
        
        audioConverter.convertToOpusOggSourceURLDestinationURLClosure = { source, destination in
            convertedFileURL = destination
            try? FileManager.default.removeItem(at: destination)
            let internalConverter = AudioConverter()
            try internalConverter.convertToOpusOgg(sourceURL: source, destinationURL: destination)
            convertedFileSize = try? UInt64(FileManager.default.sizeForItem(at: destination))
            // the source URL must be the recorded file
            XCTAssertEqual(source, imageFileURL)
            // check the converted file extension
            XCTAssertEqual(destination.pathExtension, "ogg")
        }
        
        timelineProxy.sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleClosure = { url, audioInfo, waveform, _, _ in
            XCTAssertEqual(url, convertedFileURL)
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
        XCTAssert(timelineProxy.sendVoiceMessageUrlAudioInfoWaveformProgressSubjectRequestHandleCalled)
        
        // the converted file must have been deleted
        if let convertedFileURL {
            XCTAssertFalse(FileManager.default.fileExists(atPath: convertedFileURL.path()))
        } else {
            XCTFail("converted file URL is missing")
        }
    }
    
    func testAudioRecorderActionHandling_didStartRecording() async throws {
        let deferred = deferFulfillment(voiceMessageRecorder.actions) { action in
            switch action {
            case .didStartRecording:
                return true
            default:
                return false
            }
        }
        audioRecorderActionsSubject.send(.didStartRecording)
        try await deferred.fulfill()
    }
    
    func testAudioRecorderActionHandling_didStopRecording() async throws {
        audioRecorder.audioFileURL = recordingURL
        audioRecorder.currentTime = 5

        let deferred = deferFulfillment(voiceMessageRecorder.actions) { action in
            switch action {
            case .didStopRecording(_, let url) where url == self.recordingURL:
                return true
            default:
                return false
            }
        }
        audioRecorderActionsSubject.send(.didStopRecording)
        try await deferred.fulfill()
    }
    
    func testAudioRecorderActionHandling_didFailed() async throws {
        audioRecorder.audioFileURL = recordingURL
        
        let deferred = deferFulfillment(voiceMessageRecorder.actions) { action in
            switch action {
            case .didFailWithError:
                return true
            default:
                return false
            }
        }
        audioRecorderActionsSubject.send(.didFailWithError(error: .audioEngineFailure))
        try await deferred.fulfill()
    }
}

private enum SDKError: Error {
    case generic
}
