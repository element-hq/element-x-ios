//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import DSWaveformImage
import Foundation
import MatrixRustSDK

// Proper callback implementation for UniFFI
class TranscriptCallbackImpl: TranscriptUpdateCallback {
    private let callback: (String) -> Void
    
    init(callback: @escaping (String) -> Void) {
        self.callback = callback
    }
    
    func onTranscriptUpdate(transcript: String) {
        callback(transcript)
    }
}

class VoiceMessageRecorder: VoiceMessageRecorderProtocol {
    let audioRecorder: AudioRecorderProtocol
    private let voiceMessageCache: VoiceMessageCacheProtocol
    private let mediaPlayerProvider: MediaPlayerProviderProtocol
    
    private let actionsSubject: PassthroughSubject<VoiceMessageRecorderAction, Never> = .init()
    var actions: AnyPublisher<VoiceMessageRecorderAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    private let mp4accMimeType = "audio/m4a"
    
    var isRecording: Bool {
        audioRecorder.isRecording
    }
    
    var recordingURL: URL? {
        audioRecorder.audioFileURL
    }
    
    var recordingDuration: TimeInterval {
        audioRecorder.currentTime
    }
    
    private var recordingCancelled = false

    // --- Live Transcription ---
    private var audioTranscription: AudioStreamTranscription?
    private(set) var currentTranscript = ""
    // -------------------------

    private(set) var previewAudioPlayerState: AudioPlayerState?
    private(set) var previewAudioPlayer: AudioPlayerProtocol?
    private var cancellables = Set<AnyCancellable>()
        
    init(audioRecorder: AudioRecorderProtocol = AudioRecorder(),
         mediaPlayerProvider: MediaPlayerProviderProtocol,
         voiceMessageCache: VoiceMessageCacheProtocol = VoiceMessageCache()) {
        self.audioRecorder = audioRecorder
        self.mediaPlayerProvider = mediaPlayerProvider
        self.voiceMessageCache = voiceMessageCache
        
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    // MARK: - Recording
    
    func startRecording() async {
        await stopPlayback()
        previewAudioPlayer?.reset()
        recordingCancelled = false

        // --- Live Transcription Setup ---
        let apiKey = ProcessInfo.processInfo.environment["TRANSCRIPTION_API_KEY"] ?? "default-api-key"
        let language = "en" // TODO: Get from user settings if needed
        do {
            // Create a callback implementation that conforms to the TranscriptUpdateCallback protocol
            class TranscriptCallbackImpl: TranscriptUpdateCallback {
                private let onUpdate: (String) -> Void
                
                init(onUpdate: @escaping (String) -> Void) {
                    self.onUpdate = onUpdate
                }
                
                func onTranscriptUpdate(transcript: String) {
                    onUpdate(transcript)
                }
            }
            
            let callback = TranscriptCallbackImpl { [weak self] transcript in
                DispatchQueue.main.async {
                    self?.currentTranscript = transcript
                    MXLog.info("Transcript update: \(transcript)")
                }
            }
            audioTranscription = try AudioStreamTranscription(callback: callback,
                                                              language: language,
                                                              apiKey: apiKey)
        } catch {
            MXLog.error("Failed to initialize transcription: \(error)")
            audioTranscription = nil
        }
        // -------------------------------

        // Start recording and hook up audio data streaming for transcription
        await audioRecorder.record(audioFileURL: voiceMessageCache.urlForRecording)
        
        // Set up audio buffer processing if your AudioRecorder supports it
        audioRecorder.setAudioBufferCallback { [weak self] (buffer: [UInt8]) in
            guard let self = self, let audioTranscription = self.audioTranscription else { return }
            
            // Convert buffer to Data object expected by the Rust SDK bindings
            let data = Data(buffer)
            audioTranscription.addAudioData(data: data)
        }
    }
    
    func stopRecording() async {
        recordingCancelled = false
        await audioRecorder.stopRecording()
        // Stop transcription and get the final transcript
        if let audioTranscription = audioTranscription {
            do {
                let finalTranscript = try audioTranscription.stop()
                MXLog.info("Final transcript: \(finalTranscript)")
                // Store the final transcript for later use (e.g., sending with the voice message)
                currentTranscript = finalTranscript
            } catch {
                MXLog.error("Error stopping transcription: \(error)")
            }
        }
        audioTranscription = nil
    }
    
    func cancelRecording() async {
        MXLog.info("Cancel recording.")
        recordingCancelled = true
        await audioRecorder.stopRecording()
        await audioRecorder.deleteRecording()
        previewAudioPlayerState = nil
        previewAudioPlayer?.reset()
        // Clean up transcription
        audioTranscription = nil
        currentTranscript = ""
    }
    
    func deleteRecording() async {
        MXLog.info("Delete recording.")
        await stopPlayback()
        await audioRecorder.deleteRecording()
        previewAudioPlayer?.reset()
        previewAudioPlayerState = nil
    }

    // MARK: - Preview
    
    func startPlayback() async -> Result<Void, VoiceMessageRecorderError> {
        guard let previewAudioPlayerState, let url = audioRecorder.audioFileURL else {
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
        previewAudioPlayer?.pause()
    }
    
    func stopPlayback() async {
        guard let previewAudioPlayerState else {
            return
        }
        await previewAudioPlayerState.detachAudioPlayer()
        previewAudioPlayer?.stop()
    }
    
    func seekPlayback(to progress: Double) async {
        await previewAudioPlayerState?.updateState(progress: progress)
    }
    
    func buildRecordingWaveform() async -> Result<[UInt16], VoiceMessageRecorderError> {
        guard let url = audioRecorder.audioFileURL else {
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
    
    func sendVoiceMessage(inRoom roomProxy: JoinedRoomProxyProtocol, audioConverter: AudioConverterProtocol) async -> Result<Void, VoiceMessageRecorderError> {
        guard let url = audioRecorder.audioFileURL else {
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
        
        let result = await roomProxy.timeline.sendVoiceMessage(url: oggFile,
                                                               audioInfo: audioInfo,
                                                               waveform: waveform,
                                                               progressSubject: nil) { _ in }
        
        // Check if voice message was sent successfully
        if case .success(let eventId) = result {
            // Voyzme: at the moment STT is not available yet; let's pretend it's there at the moment the audio is ready to be
            // sent, and use gibberish data.
            let result_stt = await roomProxy.timeline.sendTranscriptEvent(transcript: "test", relatedEventId: eventId)
            MXLog.info("Finished sending transcript event: \(result_stt)")
        } else if case .failure(let error) = result {
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
                    guard let recordingURL = audioRecorder.audioFileURL, let previewAudioPlayerState else {
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
        guard let url = audioRecorder.audioFileURL, audioRecorder.currentTime > 0 else {
            return .failure(.previewNotAvailable)
        }

        // Build the preview audio player state
        previewAudioPlayerState = await AudioPlayerState(id: .recorderPreview, title: L10n.commonVoiceMessage, duration: recordingDuration, waveform: EstimatedWaveform(data: []))

        // Build the preview audio player
        let mediaSource = MediaSourceProxy(url: url, mimeType: mp4accMimeType)
        guard case .success(let mediaPlayer) = await mediaPlayerProvider.player(for: mediaSource), let audioPlayer = mediaPlayer as? AudioPlayerProtocol else {
            return .failure(.previewNotAvailable)
        }
        previewAudioPlayer = audioPlayer
        
        return .success(())
    }
}
