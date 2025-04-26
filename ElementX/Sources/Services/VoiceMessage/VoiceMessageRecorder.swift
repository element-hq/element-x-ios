//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import AVFoundation
import Combine
import DSWaveformImage
import Foundation
import MatrixRustSDK
import Speech

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

// Apple Speech Framework transcription implementation
class AppleSpeechTranscription {
    private let speechRecognizer: SFSpeechRecognizer
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let callback: (String) -> Void
    private var isRunning = false
    private var finalTranscript = ""
    
    init(callback: @escaping (String) -> Void, language: String) throws {
        self.callback = callback
        
        // Create speech recognizer with the specified language locale
        guard let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: language)) else {
            MXLog.error("Failed to create speech recognizer for language: \(language)")
            throw NSError(domain: "AppleSpeechTranscription", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unsupported language"])
        }
        
        self.speechRecognizer = speechRecognizer
        
        // Check if speech recognition is available
        if !speechRecognizer.isAvailable {
            MXLog.error("Speech recognition is not available right now")
            throw NSError(domain: "AppleSpeechTranscription", code: 2, userInfo: [NSLocalizedDescriptionKey: "Speech recognition unavailable"])
        }
        
        // Request authorization for speech recognition
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                MXLog.debug("Speech recognition authorization granted")
            case .denied:
                MXLog.error("Speech recognition authorization denied")
            case .restricted, .notDetermined:
                MXLog.error("Speech recognition not authorized")
            @unknown default:
                MXLog.error("Speech recognition unknown authorization status")
            }
        }
    }
    
    func startRecognition() throws {
        // Cancel any existing recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session for recording
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create and configure the speech recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "AppleSpeechTranscription", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
        }
        
        // Configure for continuous recognition
        recognitionRequest.shouldReportPartialResults = true
        
        // Create an input node for audio capture
        let inputNode = audioEngine.inputNode
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                // Get the transcription text
                let transcription = result.bestTranscription.formattedString
                self.finalTranscript = transcription
                isFinal = result.isFinal
                
                // Send the transcription to the callback
                self.callback(transcription)
            }
            
            if error != nil || isFinal {
                // Stop audio engine and end recognition
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                if error != nil {
                    MXLog.error("Speech recognition error: \(error!)")
                }
            }
        }
        
        // Configure the microphone input and install a tap on the audio engine
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // Start the audio engine
        audioEngine.prepare()
        try audioEngine.start()
        isRunning = true
        
        MXLog.debug("Apple Speech recognition started")
    }
    
    func addAudioData(data: Data) {
        // This method is not used with Apple's Speech framework as we're using the AVAudioEngine directly
        // It's included for API compatibility with AudioStreamTranscription
    }
    
    func stop() throws -> String {
        // Stop the audio engine and recognition task
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        // Clean up resources
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest = nil
        recognitionTask = nil
        isRunning = false
        
        MXLog.debug("Apple Speech recognition stopped, final transcript: \(finalTranscript)")
        
        // Create a JSON string with the transcript similar to the Deepgram format
        let transcriptDict: [String: Any] = [
            "text": finalTranscript,
            "words": [] // Empty array as Apple doesn't provide word timing by default
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: transcriptDict),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        } else {
            return "{\"text\":\"\(finalTranscript)\", \"words\":[]}"
        }
    }
}

class VoiceMessageRecorder: VoiceMessageRecorderProtocol {
    let audioRecorder: AudioRecorderProtocol
    private let voiceMessageCache: VoiceMessageCacheProtocol
    private let mediaPlayerProvider: MediaPlayerProviderProtocol
    private let roomProxy: JoinedRoomProxyProtocol?
    
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
    private(set) var useAppleTranscription = true // Flag to switch between implementations
    private var audioTranscription: AudioStreamTranscription?
    private var appleSpeechTranscription: AppleSpeechTranscription?
    private(set) var currentTranscript = ""
    
    /// Set the transcription method to use
    /// - Parameter useApple: If true, use Apple's Speech framework. If false, use Deepgram.
    func setTranscriptionMethod(useApple: Bool) {
        useAppleTranscription = useApple
        MXLog.info("Transcription method set to: \(useApple ? "Apple Speech" : "Deepgram")")
    }

    // -------------------------

    private(set) var previewAudioPlayerState: AudioPlayerState?
    private(set) var previewAudioPlayer: AudioPlayerProtocol?
    private var cancellables = Set<AnyCancellable>()
        
    init(audioRecorder: AudioRecorderProtocol = AudioRecorder(),
         mediaPlayerProvider: MediaPlayerProviderProtocol,
         voiceMessageCache: VoiceMessageCacheProtocol = VoiceMessageCache(),
         roomProxy: JoinedRoomProxyProtocol? = nil,
         useAppleTranscription: Bool = true) {
        self.audioRecorder = audioRecorder
        self.mediaPlayerProvider = mediaPlayerProvider
        self.voiceMessageCache = voiceMessageCache
        self.roomProxy = roomProxy
        self.useAppleTranscription = useAppleTranscription
        
        MXLog.debug("VoiceMessageRecorder initialized with audioRecorder: \(type(of: audioRecorder)), useAppleTranscription: \(useAppleTranscription)")
        
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

        // Get the transcription language from the settings
        var language = "en" // Default to English
        
        // Dump all keys in shared UserDefaults for debugging
        MXLog.debug("Checking for transcription language in UserDefaults")
        if let userDefaults = UserDefaults(suiteName: "group.io.element.elementx") {
            MXLog.debug("All keys in shared UserDefaults:")
            for (key, value) in userDefaults.dictionaryRepresentation() {
                if key.contains("transcription") {
                    MXLog.debug("  \(key): \(value)")
                }
            }
            
            if let roomProxy = roomProxy {
                // Fallback to roomProxy if available
                let roomID = roomProxy.id
                let key = "transcriptionLanguage-\(roomID)"
                MXLog.debug("Looking for room-specific transcription language with key: \(key)")
                
                if let languageString = userDefaults.string(forKey: key) {
                    language = languageString
                    MXLog.debug("Using room-specific transcription language: \(language)")
                }
            }
        }
        
        MXLog.debug("Starting voice recording with transcription, language: \(language), using Apple transcription: \(useAppleTranscription)")
        MXLog.debug("Using audioRecorder instance: \(type(of: audioRecorder)), isRecording: \(audioRecorder.isRecording)")
        
        if useAppleTranscription {
            // Apple Speech Framework implementation
            do {
                // Create a callback to update the transcript
                let transcriptCallback = { [weak self] (transcript: String) in
                    DispatchQueue.main.async {
                        self?.currentTranscript = transcript
                        MXLog.info("Apple transcript update received: '\(transcript)'")
                        MXLog.info("Transcript length: \(transcript.count) characters")
                        
                        // Post notification with the updated transcript for UI updates
                        NotificationCenter.default.post(name: Notification.Name("VoiceMessageTranscriptUpdate"), object: transcript)
                    }
                }
                
                // Initialize the Apple Speech transcription
                MXLog.debug("Initializing Apple Speech transcription engine")
                appleSpeechTranscription = try AppleSpeechTranscription(callback: transcriptCallback, language: language)
                
                // Start the recognition process
                try appleSpeechTranscription?.startRecognition()
                MXLog.info("Successfully started Apple Speech transcription")
                
                // Start recording audio
                await audioRecorder.record(audioFileURL: voiceMessageCache.urlForRecording)
            } catch {
                MXLog.error("Failed to initialize Apple Speech transcription: \(error)")
                appleSpeechTranscription = nil
            }
        } else {
            // Deepgram implementation (original)
            let apiKey = ProcessInfo.processInfo.environment["TRANSCRIPTION_API_KEY"] ?? "72c5eb32007f5e45904c20a8176756c168f8f018"
            
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
                    MXLog.info("Deepgram transcript update received: '\(transcript)'")
                    MXLog.info("Transcript length: \(transcript.count) characters")
                    
                    // Post notification with the updated transcript for UI updates
                    NotificationCenter.default.post(name: Notification.Name("VoiceMessageTranscriptUpdate"), object: transcript)
                }
            }
            
            // Initialize the transcription engine first
            do {
                MXLog.debug("Initializing Deepgram transcription engine")
                audioTranscription = try AudioStreamTranscription(callback: callback,
                                                                  language: language,
                                                                  apiKey: apiKey)
                MXLog.info("Successfully initialized Deepgram transcription engine")
                
                // Explicitly create a strong reference to audioRecorder to prevent potential issues
                let recorder = audioRecorder
                
                // Set up audio buffer callback BEFORE starting recording
                MXLog.debug("About to set audio buffer callback on \(type(of: recorder))")
                recorder.setAudioBufferCallback { [weak self] (buffer: [UInt8]) in
                    guard let self = self, let audioTranscription = self.audioTranscription else {
                        MXLog.warning("Audio buffer received but transcription is nil or self is deallocated")
                        return
                    }
                    
                    // Add WAV header to the buffer
                    let wavBuffer = self.createWavHeaderForBuffer(buffer)

                    MXLog.debug("Sending audio buffer: original size=\(buffer.count) bytes, with WAV header=\(wavBuffer.count) bytes")

                    // Convert buffer to Data object expected by the Rust SDK bindings
                    let data = Data(wavBuffer)
                    audioTranscription.addAudioData(data: data)
                }
                
                // Now start recording after the callback is set up
                MXLog.debug("Starting audio recording with \(type(of: recorder))")
                await recorder.record(audioFileURL: voiceMessageCache.urlForRecording)
                
            } catch {
                MXLog.error("Failed to initialize Deepgram transcription: \(error)")
                audioTranscription = nil
            }
        }
    }
    
    func stopRecording() async {
        recordingCancelled = false
        
        await audioRecorder.stopRecording()
        // Stop transcription and get the final transcript
        
        if useAppleTranscription {
            // Apple Speech Framework implementation
            let localSpeechTranscription = appleSpeechTranscription
            appleSpeechTranscription = nil // Clear this early to avoid any potential race conditions
            
            if let localSpeechTranscription = localSpeechTranscription {
                do {
                    // Stop the Apple Speech recognition and get the final transcript
                    let transcriptJson = try localSpeechTranscription.stop()
                    
                    // Process the transcript on the main thread
                    await MainActor.run {
                        MXLog.info("Apple Speech transcript received: \(transcriptJson)")
                        
                        // Parse the JSON to extract transcript
                        if let jsonData = transcriptJson.data(using: .utf8) {
                            do {
                                if let transcriptObj = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                   let plainTranscript = transcriptObj["text"] as? String {
                                    MXLog.info("Final Apple Speech transcript: \(plainTranscript)")
                                    
                                    // Store the final transcript for later use
                                    currentTranscript = plainTranscript
                                    
                                    // Post notification with the updated transcript for UI updates
                                    NotificationCenter.default.post(name: Notification.Name("VoiceMessageTranscriptUpdate"), object: plainTranscript)
                                } else {
                                    MXLog.error("Failed to extract text from Apple Speech transcript JSON")
                                }
                            } catch {
                                MXLog.error("Error parsing Apple Speech transcript JSON: \(error)")
                            }
                        } else {
                            MXLog.error("Failed to convert Apple Speech transcript to data")
                        }
                    }
                } catch {
                    await MainActor.run {
                        MXLog.error("Error stopping Apple Speech transcription: \(error)")
                    }
                }
            }
        } else {
            // Deepgram implementation (original)
            let localTranscription = audioTranscription
            audioTranscription = nil // Clear this early to avoid any potential race conditions
            
            if let localTranscription = localTranscription {
                do {
                    // Create a task to handle the potentially blocking stop operation
                    // This ensures we properly wait for the stop function to complete
                    // even though it has a delay to check all chunks have been processed
                    let transcriptWithTiming = try await Task {
                        // This executes on a background thread
                        let transcriptJson = try localTranscription.stop()
                        return transcriptJson
                    }.value
                    
                    // Ensure all UI updates happen on the main thread
                    await MainActor.run {
                        MXLog.info("Deepgram transcript with timing received: \(transcriptWithTiming)")
                        
                        // Parse the JSON to extract transcript and timing information
                        if let jsonData = transcriptWithTiming.data(using: .utf8) {
                            do {
                                // Parse the JSON object containing transcript and word timings
                                if let transcriptObj = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                   let plainTranscript = transcriptObj["text"] as? String,
                                   let wordTimings = transcriptObj["words"] as? [[String: Any]] {
                                    MXLog.info("Final Deepgram transcript: \(plainTranscript)")
                                    
                                    // Store the final transcript for later use (e.g., sending with the voice message)
                                    currentTranscript = plainTranscript
                                    
                                    // Post notification with the final transcript for UI updates
                                    NotificationCenter.default.post(name: Notification.Name("VoiceMessageTranscriptUpdate"), object: plainTranscript)
                                    
                                    // Store the timing information for potential future use
                                    // You could add a property to store this if needed
                                    MXLog.debug("Word timing information available: \(wordTimings.count) words with timing")
                                } else {
                                    MXLog.error("Failed to extract text or words from Deepgram transcript JSON")
                                }
                            } catch {
                                MXLog.error("Error parsing Deepgram transcript timing JSON: \(error)")
                            }
                        } else {
                            MXLog.error("Failed to convert Deepgram transcript timing to data")
                        }
                    }
                } catch {
                    await MainActor.run {
                        MXLog.error("Error stopping Deepgram transcription: \(error)")
                    }
                }
            }
        }
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
        appleSpeechTranscription = nil
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
            // Get the room-specific transcription language
            let roomID = roomProxy.id
            let key = "transcriptionLanguage-\(roomID)"
            var language = "en-US" // Default language
            
            if let languageString = UserDefaults.standard.string(forKey: key) {
                language = languageString
                MXLog.debug("Using room-specific transcription language: \(language)")
            }
            
            // Use the actual transcript we generated during recording
            let result_stt = await roomProxy.timeline.sendTranscriptEvent(transcript: currentTranscript, language: language, relatedEventId: eventId)
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

    // In VoiceMessageRecorder.swift, add this helper function:
    private func createWavHeaderForBuffer(_ buffer: [UInt8]) -> [UInt8] {
        let sampleRate: UInt32 = 48000 // Match your actual sample rate
        let channels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
    
        // Calculate derived values
        let bytesPerSample = bitsPerSample / 8
        let bytesPerSecond = sampleRate * UInt32(bytesPerSample) * UInt32(channels)
        let blockAlign = bytesPerSample * channels
        let dataSize = UInt32(buffer.count)
        let fileSize = dataSize + 36 // File size minus 8 bytes for RIFF header
    
        // Create header
        var header = [UInt8]()
    
        // RIFF header
        header.append(contentsOf: "RIFF".utf8)
        header.append(contentsOf: withUnsafeBytes(of: fileSize.littleEndian) { Array($0) })
        header.append(contentsOf: "WAVE".utf8)
    
        // fmt chunk
        header.append(contentsOf: "fmt ".utf8)
        header.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) }) // fmt chunk size
        header.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) }) // PCM format
        header.append(contentsOf: withUnsafeBytes(of: channels.littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: sampleRate.littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: bytesPerSecond.littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: bitsPerSample.littleEndian) { Array($0) })
    
        // data chunk
        header.append(contentsOf: "data".utf8)
        header.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian) { Array($0) })
    
        // Combine header and buffer
        var wavData = header
        wavData.append(contentsOf: buffer)
    
        return wavData
    }
}
