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

@Suite
@MainActor
struct VoiceMessageRecorderTests {
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
    
    init() async throws {
        audioRecorder = AudioRecorderMock()
        audioRecorder.underlyingCurrentTime = 0
        audioRecorder.averagePowerReturnValue = 0
        audioRecorder.actions = audioRecorderActions
        
        audioPlayer = AudioPlayerMock()
        audioPlayer.actions = audioPlayerActions
        audioPlayer.state = .stopped
        audioPlayer.playbackSpeed = 1.0
        
        mediaPlayerProvider = MediaPlayerProviderMock()
        mediaPlayerProvider.player = audioPlayer
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
            case .didStopRecording(_, let url) where url == recordingURL:
                return true
            default:
                return false
            }
        }
        audioRecorderActionsSubject.send(.didStopRecording)
        try await deferred.fulfill()
    }
    
    @Test
    func recorderRecordingURL() {
        audioRecorder.audioFileURL = recordingURL
        #expect(voiceMessageRecorder.recordingURL == recordingURL)
    }
    
    @Test
    func recorderRecordingDuration() {
        audioRecorder.currentTime = 10.3
        #expect(voiceMessageRecorder.recordingDuration == 10.3)
    }
    
    @Test
    func startRecording() async {
        _ = await voiceMessageRecorder.startRecording()
        #expect(audioRecorder.recordAudioFileURLCalled)
    }
    
    @Test
    func stopRecording() async {
        _ = await voiceMessageRecorder.stopRecording()
        // Internal audio recorder must have been stopped
        #expect(audioRecorder.stopRecordingCalled)
    }
    
    @Test
    func cancelRecording() async {
        await voiceMessageRecorder.cancelRecording()
        // Internal audio recorder must have been stopped
        #expect(audioRecorder.stopRecordingCalled)
        // The recording audio file must have been deleted
        #expect(audioRecorder.deleteRecordingCalled)
    }

    @Test
    func deleteRecording() async {
        await voiceMessageRecorder.deleteRecording()
        // The recording audio file must have been deleted
        #expect(audioRecorder.deleteRecordingCalled)
    }

    @Test
    func startPlaybackNoPreview() async {
        guard case .failure(.previewNotAvailable) = await voiceMessageRecorder.startPlayback() else {
            Issue.record("An error is expected")
            return
        }
    }
    
    @Test
    func startPlayback() async throws {
        try await setRecordingComplete()
        
        guard case .success = await voiceMessageRecorder.startPlayback() else {
            Issue.record("Playback should start")
            return
        }
        #expect(voiceMessageRecorder.previewAudioPlayerState?.isAttached == true)
        #expect(audioPlayer.loadSourceURLPlaybackURLAutoplayCalled)
        #expect(audioPlayer.loadSourceURLPlaybackURLAutoplayReceivedArguments?.sourceURL == recordingURL)
        #expect(audioPlayer.loadSourceURLPlaybackURLAutoplayReceivedArguments?.playbackURL == recordingURL)
        #expect(audioPlayer.loadSourceURLPlaybackURLAutoplayReceivedArguments?.autoplay == true)
        #expect(!audioPlayer.playCalled)
    }
    
    @Test
    func pausePlayback() async throws {
        try await setRecordingComplete()

        _ = await voiceMessageRecorder.startPlayback()
        #expect(voiceMessageRecorder.previewAudioPlayerState?.isAttached == true)

        voiceMessageRecorder.pausePlayback()
        #expect(audioPlayer.pauseCalled)
    }
    
    @Test
    func resumePlayback() async throws {
        try await setRecordingComplete()
        audioPlayer.playbackURL = recordingURL

        guard case .success = await voiceMessageRecorder.startPlayback() else {
            Issue.record("Playback should start")
            return
        }
        #expect(voiceMessageRecorder.previewAudioPlayerState?.isAttached == true)
        // The media must not have been reloaded
        #expect(!audioPlayer.loadSourceURLPlaybackURLAutoplayCalled)
        #expect(audioPlayer.playCalled)
    }

    @Test
    func stopPlayback() async throws {
        try await setRecordingComplete()

        _ = await voiceMessageRecorder.startPlayback()
        #expect(voiceMessageRecorder.previewAudioPlayerState?.isAttached == true)
        
        await voiceMessageRecorder.stopPlayback()
        #expect(voiceMessageRecorder.previewAudioPlayerState?.isAttached == false)
        #expect(audioPlayer.stopCalled)
    }
    
    @Test
    func seekPlayback() async throws {
        try await setRecordingComplete()

        _ = await voiceMessageRecorder.startPlayback()
        #expect(voiceMessageRecorder.previewAudioPlayerState?.isAttached == true)

        await voiceMessageRecorder.seekPlayback(to: 0.4)
        #expect(audioPlayer.seekToReceivedProgress == 0.4)
    }
    
    @Test
    func buildRecordedWaveform() async throws {
        // If there is no recording file, an error is expected
        audioRecorder.audioFileURL = nil
        guard case .failure(.missingRecordingFile) = await voiceMessageRecorder.buildRecordingWaveform() else {
            Issue.record("An error is expected")
            return
        }
        
        let audioFileURL = try #require(Bundle(for: UnitTestsAppCoordinator.self).url(forResource: "test_audio", withExtension: "mp3"), "Test audio file is missing")
        audioRecorder.audioFileURL = audioFileURL
        guard case .success(let data) = await voiceMessageRecorder.buildRecordingWaveform() else {
            Issue.record("A waveform is expected")
            return
        }
        #expect(!data.isEmpty)
    }
    
    @Test
    func sendVoiceMessage_NoRecordingFile() async {
        let timelineController = MockTimelineController()
        
        // If there is no recording file, an error is expected
        audioRecorder.audioFileURL = nil
        guard case .failure(.missingRecordingFile) = await voiceMessageRecorder.sendVoiceMessage(timelineController: timelineController,
                                                                                                 audioConverter: audioConverter) else {
            Issue.record("An error is expected")
            return
        }
    }
    
    @Test
    func sendVoiceMessage_ConversionError() async {
        audioRecorder.audioFileURL = recordingURL
        // If the converter returns an error
        audioConverter.convertToOpusOggSourceURLDestinationURLThrowableError = AudioConverterError.conversionFailed(nil)
        
        let timelineController = MockTimelineController()
        guard case .failure(.failedSendingVoiceMessage) = await voiceMessageRecorder.sendVoiceMessage(timelineController: timelineController,
                                                                                                      audioConverter: audioConverter) else {
            Issue.record("An error is expected")
            return
        }
    }
    
    @Test
    func sendVoiceMessage_InvalidFile() async throws {
        let audioFileURL = try #require(Bundle(for: UnitTestsAppCoordinator.self).url(forResource: "test_voice_message", withExtension: "m4a"), "Test audio file is missing")
        audioRecorder.audioFileURL = audioFileURL
        audioConverter.convertToOpusOggSourceURLDestinationURLClosure = { _, destination in
            try? FileManager.default.removeItem(at: destination)
        }
        
        let timelineProxy = TimelineProxyMock()
        let timelineController = MockTimelineController(timelineProxy: timelineProxy)
        timelineProxy.sendVoiceMessageUrlAudioInfoWaveformRequestHandleReturnValue = .failure(.sdkError(SDKError.generic))
        guard case .failure(.failedSendingVoiceMessage) = await voiceMessageRecorder.sendVoiceMessage(timelineController: timelineController,
                                                                                                      audioConverter: audioConverter) else {
            Issue.record("An error is expected")
            return
        }
    }
    
    @Test
    func sendVoiceMessage_WaveformAnlyseFailed() async throws {
        let imageFileURL = try #require(Bundle(for: UnitTestsAppCoordinator.self).url(forResource: "test_image", withExtension: "png"), "Test image file is missing")
        audioRecorder.audioFileURL = imageFileURL
        audioConverter.convertToOpusOggSourceURLDestinationURLClosure = { _, destination in
            try? FileManager.default.removeItem(at: destination)
            try? FileManager.default.copyItem(at: imageFileURL, to: destination)
        }
        
        let timelineProxy = TimelineProxyMock()
        let timelineController = MockTimelineController(timelineProxy: timelineProxy)
        timelineProxy.sendVoiceMessageUrlAudioInfoWaveformRequestHandleReturnValue = .failure(.sdkError(SDKError.generic))
        guard case .failure(.failedSendingVoiceMessage) = await voiceMessageRecorder.sendVoiceMessage(timelineController: timelineController,
                                                                                                      audioConverter: audioConverter) else {
            Issue.record("An error is expected")
            return
        }
    }
    
    @Test
    func sendVoiceMessage_SendError() async throws {
        let audioFileURL = try #require(Bundle(for: UnitTestsAppCoordinator.self).url(forResource: "test_voice_message", withExtension: "m4a"), "Test audio file is missing")
        audioRecorder.audioFileURL = audioFileURL
        audioConverter.convertToOpusOggSourceURLDestinationURLClosure = { source, destination in
            try? FileManager.default.removeItem(at: destination)
            let internalConverter = AudioConverter()
            try internalConverter.convertToOpusOgg(sourceURL: source, destinationURL: destination)
        }
        
        // If the media upload fails
        let timelineProxy = TimelineProxyMock()
        let timelineController = MockTimelineController(timelineProxy: timelineProxy)
        timelineProxy.sendVoiceMessageUrlAudioInfoWaveformRequestHandleReturnValue = .failure(.sdkError(SDKError.generic))
        guard case .failure(.failedSendingVoiceMessage) = await voiceMessageRecorder.sendVoiceMessage(timelineController: timelineController,
                                                                                                      audioConverter: audioConverter) else {
            Issue.record("An error is expected")
            return
        }
    }
    
    @Test
    func sendVoiceMessage() async throws {
        let imageFileURL = try #require(Bundle(for: UnitTestsAppCoordinator.self).url(forResource: "test_voice_message", withExtension: "m4a"), "Test audio file is missing")
        
        let timelineProxy = TimelineProxyMock()
        let timelineController = MockTimelineController(timelineProxy: timelineProxy)
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
            #expect(source == imageFileURL)
            // check the converted file extension
            #expect(destination.pathExtension == "ogg")
        }
        
        timelineProxy.sendVoiceMessageUrlAudioInfoWaveformRequestHandleClosure = { url, audioInfo, waveform, _ in
            #expect(url == convertedFileURL)
            #expect(audioInfo.duration == audioRecorder.currentTime)
            #expect(audioInfo.size == convertedFileSize)
            #expect(audioInfo.mimetype == "audio/ogg")
            #expect(!waveform.isEmpty)
            
            return .success(())
        }
        
        guard case .success = await voiceMessageRecorder.sendVoiceMessage(timelineController: timelineController, audioConverter: audioConverter) else {
            Issue.record("A success is expected")
            return
        }
        
        #expect(audioConverter.convertToOpusOggSourceURLDestinationURLCalled)
        #expect(timelineProxy.sendVoiceMessageUrlAudioInfoWaveformRequestHandleCalled)
        
        // the converted file must have been deleted
        if let convertedFileURL {
            #expect(!FileManager.default.fileExists(atPath: convertedFileURL.path()))
        } else {
            Issue.record("converted file URL is missing")
        }
    }
    
    @Test
    func audioRecorderActionHandling_didStartRecording() async throws {
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
    
    @Test
    func audioRecorderActionHandling_didStopRecording() async throws {
        audioRecorder.audioFileURL = recordingURL
        audioRecorder.currentTime = 5

        let deferred = deferFulfillment(voiceMessageRecorder.actions) { action in
            switch action {
            case .didStopRecording(_, let url) where url == recordingURL:
                return true
            default:
                return false
            }
        }
        audioRecorderActionsSubject.send(.didStopRecording)
        try await deferred.fulfill()
    }
    
    @Test
    func audioRecorderActionHandling_didFailed() async throws {
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
