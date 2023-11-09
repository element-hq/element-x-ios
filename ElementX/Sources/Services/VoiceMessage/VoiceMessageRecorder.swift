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
import DSWaveformImage
import Foundation
import MatrixRustSDK

class VoiceMessageRecorder: VoiceMessageRecorderProtocol {
    let audioRecorder: AudioRecorderProtocol
    private let audioConverter: AudioConverterProtocol
    private let voiceMessageCache: VoiceMessageCacheProtocol
    private let mediaPlayerProvider: MediaPlayerProviderProtocol
    
    private let actionsSubject: PassthroughSubject<VoiceMessageRecorderAction, Never> = .init()
    var actions: AnyPublisher<VoiceMessageRecorderAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    private let mp4accMimeType = "audio/m4a"
    private let waveformSamplesCount = 100
    
    var isRecording: Bool {
        audioRecorder.isRecording
    }
    
    var recordingURL: URL? {
        audioRecorder.audioFileUrl
    }
    
    var recordingDuration: TimeInterval {
        audioRecorder.currentTime
    }
    
    private var recordingCancelled = false

    private(set) var previewAudioPlayerState: AudioPlayerState?
    private(set) var previewAudioPlayer: AudioPlayerProtocol?
    private var cancellables = Set<AnyCancellable>()
        
    init(audioRecorder: AudioRecorderProtocol = AudioRecorder(),
         mediaPlayerProvider: MediaPlayerProviderProtocol,
         audioConverter: AudioConverterProtocol = AudioConverter(),
         voiceMessageCache: VoiceMessageCacheProtocol = VoiceMessageCache()) {
        self.audioRecorder = audioRecorder
        self.mediaPlayerProvider = mediaPlayerProvider
        self.audioConverter = audioConverter
        self.voiceMessageCache = voiceMessageCache
        
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    // MARK: - Recording
    
    func startRecording() async {
        MXLog.info("Start recording.")
        await stopPlayback()
        recordingCancelled = false
        
        let recordingUrl = voiceMessageCache.urlForRecording()
        await audioRecorder.record(with: .url(recordingUrl))
    }
    
    func stopRecording() async {
        MXLog.info("Stop recording.")
        recordingCancelled = false
        await audioRecorder.stopRecording()
    }
    
    func cancelRecording() async {
        MXLog.info("Cancel recording.")
        recordingCancelled = true
        await audioRecorder.stopRecording()
        await audioRecorder.deleteRecording()
        previewAudioPlayerState = nil
    }
    
    func deleteRecording() async {
        MXLog.info("Delete recording.")
        await stopPlayback()
        await audioRecorder.deleteRecording()
        previewAudioPlayerState = nil
    }

    // MARK: - Preview
    
    func startPlayback() async -> Result<Void, VoiceMessageRecorderError> {
        MXLog.info("Start playback.")
        guard let previewAudioPlayerState, let url = audioRecorder.audioFileUrl else {
            return .failure(.previewNotAvailable)
        }
        
        guard let audioPlayer = previewAudioPlayer else {
            return .failure(.previewNotAvailable)
        }
        
        if await !previewAudioPlayerState.isAttached {
            await previewAudioPlayerState.attachAudioPlayer(audioPlayer)
        }
        
        if audioPlayer.url == url {
            audioPlayer.play()
            return .success(())
        }
        
        let pendingMediaSource = MediaSourceProxy(url: url, mimeType: mp4accMimeType)
        audioPlayer.load(mediaSource: pendingMediaSource, using: url, autoplay: true)
        return .success(())
    }
    
    func pausePlayback() {
        MXLog.info("Pause playback.")
        previewAudioPlayer?.pause()
    }
    
    func stopPlayback() async {
        guard let previewAudioPlayerState else {
            return
        }
        MXLog.info("Stop playback.")
        await previewAudioPlayerState.detachAudioPlayer()
        previewAudioPlayer?.stop()
    }
    
    func seekPlayback(to progress: Double) async {
        await previewAudioPlayerState?.updateState(progress: progress)
    }
    
    func buildRecordingWaveform() async -> Result<[UInt16], VoiceMessageRecorderError> {
        guard let url = audioRecorder.audioFileUrl else {
            return .failure(.missingRecordingFile)
        }
        // build the waveform
        var waveformData: [UInt16] = []
        let analyzer = WaveformAnalyzer()
        do {
            let samples = try await analyzer.samples(fromAudioAt: url, count: 100)
            // linearly normalized to [0, 1] (1 -> -50 dB)
            waveformData = samples.map { UInt16(max(0, (1 - $0) * 1024)) }
        } catch {
            MXLog.error("Waveform analysis failed. \(error)")
            return .failure(.waveformAnalysisError)
        }
        return .success(waveformData)
    }
    
    func sendVoiceMessage(inRoom roomProxy: RoomProxyProtocol, audioConverter: AudioConverterProtocol) async -> Result<Void, VoiceMessageRecorderError> {
        guard let url = audioRecorder.audioFileUrl else {
            return .failure(VoiceMessageRecorderError.missingRecordingFile)
        }
        
        // convert the file
        let sourceFilename = url.deletingPathExtension().lastPathComponent
        let oggFile = URL.temporaryDirectory.appendingPathComponent(sourceFilename).appendingPathExtension("ogg")
        defer {
            // delete the temporary file
            try? FileManager.default.removeItem(at: oggFile)
        }

        do {
            try audioConverter.convertToOpusOgg(sourceURL: url, destinationURL: oggFile)
        } catch {
            return .failure(.failedSendingVoiceMessage)
        }

        // send it
        let size: UInt64
        do {
            size = try UInt64(FileManager.default.sizeForItem(at: oggFile))
        } catch {
            MXLog.error("Failed to get the recording file size. \(error)")
            return .failure(.failedSendingVoiceMessage)
        }
        let audioInfo = AudioInfo(duration: recordingDuration, size: size, mimetype: "audio/ogg")
        guard case .success(let waveform) = await buildRecordingWaveform() else {
            return .failure(.failedSendingVoiceMessage)
        }
        
        let result = await roomProxy.sendVoiceMessage(url: oggFile,
                                                      audioInfo: audioInfo,
                                                      waveform: waveform,
                                                      progressSubject: nil) { _ in }
        
        if case .failure(let error) = result {
            MXLog.error("Failed to send the voice message. \(error)")
            return .failure(.failedSendingVoiceMessage)
        }
        
        return .success(())
    }
        
    // MARK: - Private
    
    private func addObservers() {
        audioRecorder.actions
            .sink { [weak self] action in
                guard let self else { return }
                self.handleAudioRecorderAction(action)
            }
            .store(in: &cancellables)
    }
    
    private func removeObservers() {
        cancellables.removeAll()
    }
    
    private func handleAudioRecorderAction(_ action: AudioRecorderAction) {
        switch action {
        case .didStartRecording:
            MXLog.info("audio recorder did start recording")
            actionsSubject.send(.didStartRecording(audioRecorder: audioRecorder))
        case .didStopRecording, .didFailWithError(error: .interrupted):
            MXLog.info("audio recorder did stop recording")
            if !recordingCancelled {
                Task {
                    guard case .success = await finalizeRecording() else {
                        actionsSubject.send(.didFailWithError(error: VoiceMessageRecorderError.previewNotAvailable))
                        return
                    }
                    guard let recordingURL = audioRecorder.audioFileUrl, let previewAudioPlayerState else {
                        actionsSubject.send(.didFailWithError(error: VoiceMessageRecorderError.previewNotAvailable))
                        return
                    }
                    await mediaPlayerProvider.register(audioPlayerState: previewAudioPlayerState)
                    actionsSubject.send(.didStopRecording(previewState: previewAudioPlayerState, url: recordingURL))
                }
            }
        case .didFailWithError(let error):
            MXLog.info("audio recorder did failed with error: \(error)")
            actionsSubject.send(.didFailWithError(error: .audioRecorderError(error)))
        }
    }
    
    private func finalizeRecording() async -> Result<Void, VoiceMessageRecorderError> {
        MXLog.info("finalize audio recording")
        guard let url = audioRecorder.audioFileUrl, audioRecorder.currentTime > 0 else {
            return .failure(.previewNotAvailable)
        }

        // Build the preview audio player state
        previewAudioPlayerState = await AudioPlayerState(id: .recorderPreview, duration: recordingDuration, waveform: EstimatedWaveform(data: []))

        // Build the preview audio player
        let mediaSource = MediaSourceProxy(url: url, mimeType: mp4accMimeType)
        guard case .success(let mediaPlayer) = await mediaPlayerProvider.player(for: mediaSource), let audioPlayer = mediaPlayer as? AudioPlayerProtocol else {
            return .failure(.previewNotAvailable)
        }
        previewAudioPlayer = audioPlayer
        
        return .success(())
    }
}
