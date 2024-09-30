//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Accelerate
import AVFoundation
import Combine
import Foundation
import UIKit

private enum InternalAudioRecorderState: Equatable {
    case recording
    case suspended
    case stopped
    case error(AudioRecorderError)
}

class AudioRecorder: AudioRecorderProtocol {
    private let audioSession: AudioSessionProtocol
    private var audioEngine: AVAudioEngine?
    private var mixer: AVAudioMixerNode?
    private var audioFile: AVAudioFile?
    private var audioConverter: AVAudioConverter?
    private var internalState = InternalAudioRecorderState.stopped
    
    private var cancellables = Set<AnyCancellable>()
    private let actionsSubject: PassthroughSubject<AudioRecorderAction, Never> = .init()
    var actions: AnyPublisher<AudioRecorderAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var recordingFormat: AVAudioFormat!
    private let maximumRecordingTime: TimeInterval = 1800 // 30 minutes
    private let silenceThreshold: Float = -50.0
    private var meterLevel: Float = 0

    private(set) var audioFileURL: URL?
    var currentTime: TimeInterval = .zero
    var isRecording: Bool {
        audioEngine?.isRunning ?? false
    }
    
    private let dispatchQueue = DispatchQueue(label: "io.element.elementx.audio_recorder", qos: .userInitiated)
    private var stopped = false
    
    init(audioSession: AudioSessionProtocol = AVAudioSession.sharedInstance()) {
        self.audioSession = audioSession
    }
    
    deinit {
        if isRecording {
            // Cleanup
            cleanupAudioEngine()
            deleteRecordingFile()
        }
    }
    
    func record(audioFileURL: URL) async {
        stopped = false
        guard await requestRecordPermission() else {
            setInternalState(.error(.recordPermissionNotGranted))
            return
        }
        let result = await startRecording(audioFileURL: audioFileURL)
        switch result {
        case .success:
            setInternalState(.recording)
        case .failure(let error):
            setInternalState(.error(error))
        }
    }
    
    func stopRecording() async {
        await withCheckedContinuation { continuation in
            stopRecording {
                continuation.resume()
            }
        }
    }
    
    func cancelRecording() async {
        await stopRecording()
        await deleteRecording()
    }
    
    func deleteRecording() async {
        await withCheckedContinuation { continuation in
            deleteRecording {
                continuation.resume()
            }
        }
    }
        
    func averagePower() -> Float {
        meterLevel
    }
    
    // MARK: - Private
    
    private func requestRecordPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            audioSession.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    private func setupAudioSession() throws {
        MXLog.info("setup audio session")
        
        try audioSession.setAllowHapticsAndSystemSoundsDuringRecording(true)
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth])
        try audioSession.setActive(true)
        addObservers()
    }
    
    private func releaseAudioSession() {
        MXLog.info("releasing audio session")
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        removeObservers()
    }
    
    private func startRecording(audioFileURL: URL) async -> Result<Void, AudioRecorderError> {
        await withCheckedContinuation { continuation in
            startRecording(audioFileURL: audioFileURL) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    private func createAudioFile(at recordingURL: URL) throws -> AVAudioFile {
        let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: Int(recordingFormat.sampleRate),
                        AVEncoderBitRateKey: 128_000,
                        AVNumberOfChannelsKey: 1,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
        MXLog.info("creating audio file with format: \(settings)")
        try? FileManager.default.removeItem(at: recordingURL)
        return try AVAudioFile(forWriting: recordingURL, settings: settings)
    }
    
    private func startRecording(audioFileURL: URL, completion: @escaping (Result<Void, AudioRecorderError>) -> Void) {
        dispatchQueue.async { [weak self] in
            guard let self, !self.stopped else {
                completion(.failure(.recordingCancelled))
                return
            }
            
            do {
                try setupAudioSession()
            } catch {
                MXLog.error("failed to setup audio session. \(error)")
                completion(.failure(.audioSessionFailure))
                return
            }
            
            // Initialize a new audio engine
            let audioEngine = AVAudioEngine()
            self.audioEngine = audioEngine

            let inputNode = audioEngine.inputNode
            let inputFormat = inputNode.outputFormat(forBus: 0)
            let hardwareSampleRate = audioEngine.inputNode.outputFormat(forBus: 0).sampleRate
            
            // Define a recording audio format. Force the sample rate to 48000 to ensure OGGEncoder won't crash
            guard let recordingFormat = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1) else {
                completion(.failure(.unsupportedAudioFormat))
                return
            }
            self.recordingFormat = recordingFormat
            
            // Make sure we have 1 channel at the end by using a mixer.
            // The sample rate must match the hardware sample rate.
            let mixerFormat = AVAudioFormat(standardFormatWithSampleRate: hardwareSampleRate, channels: 1)
            let mixer = AVAudioMixerNode()
            self.mixer = mixer
            audioEngine.attach(mixer)
            audioEngine.connect(audioEngine.inputNode, to: mixer, format: inputFormat)
            
            // Reset the recording duration
            currentTime = 0
            // Create an audio file
            let audioFile: AVAudioFile
            do {
                audioFile = try createAudioFile(at: audioFileURL)
                self.audioFile = audioFile
                self.audioFileURL = audioFile.url
            } catch {
                MXLog.error("failed to create an audio file. \(error)")
                completion(.failure(.audioFileCreationFailure))
                releaseAudioSession()
                return
            }
            
            // Set up an audio converter if the hardware sample rate doesn't match the recording format.
            // Note: Not all Apple devices have the same default sample rate.
            if recordingFormat.sampleRate != hardwareSampleRate {
                MXLog.info("Sample rate conversion is needed \(hardwareSampleRate) -> \(recordingFormat.sampleRate)")
                audioConverter = AVAudioConverter(from: inputFormat, to: recordingFormat)
            } else {
                audioConverter = nil
            }

            // Install tap to process audio buffers coming from the mixer
            mixer.installTap(onBus: 0, bufferSize: 1024, format: mixerFormat) { [weak self] buffer, _ in
                self?.processAudioBuffer(buffer)
            }

            do {
                try audioEngine.start()
                completion(.success(()))
            } catch {
                MXLog.error("audio recording failed to start. \(error)")
                completion(.failure(.audioEngineFailure))
            }
        }
    }
    
    private func stopRecording(completion: @escaping () -> Void) {
        dispatchQueue.async { [weak self] in
            defer {
                completion()
            }
            guard let self else { return }
            stopped = true
            cleanupAudioEngine()
            MXLog.info("audio recorder stopped")
            setInternalState(.stopped)
        }
    }
    
    private func cleanupAudioEngine() {
        MXLog.info("cleaning up the audio engine")
        if let audioEngine {
            audioEngine.stop()
            if let mixer {
                mixer.removeTap(onBus: 0)
                audioEngine.detach(mixer)
            }
        }
        audioFile = nil // this will close the file
        audioEngine = nil
        releaseAudioSession()
    }
    
    private func deleteRecording(completion: @escaping () -> Void) {
        dispatchQueue.async { [weak self] in
            defer {
                completion()
            }
            guard let self else { return }
            deleteRecordingFile()
            audioFileURL = nil
            currentTime = 0
        }
    }
    
    private func deleteRecordingFile() {
        guard let audioFileURL else { return }
        do {
            try FileManager.default.removeItem(at: audioFileURL)
            MXLog.info("recording file deleted.")
        } catch {
            MXLog.error("failed to delete recording file. \(error)")
        }
    }
    
    // MARK: Audio Processing
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let audioFile else {
            return
        }
        
        var inputBuffer = buffer
        if let audioConverter {
            // Create an AVAudioPCMBuffer instance for the converted buffer
            let conversionRatio = buffer.format.sampleRate / recordingFormat.sampleRate
            let frameCapacity = UInt32(Double(buffer.frameLength) / conversionRatio)
            guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: recordingFormat, frameCapacity: frameCapacity) else {
                MXLog.error("failed to initialize an output buffer")
                return
            }
            
            // Convert the buffer
            let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                outStatus.pointee = AVAudioConverterInputStatus.haveData
                return buffer
            }
            
            var conversionError: NSError?
            audioConverter.convert(to: convertedBuffer, error: &conversionError, withInputFrom: inputBlock)
            if let conversionError {
                MXLog.info("audio conversion failed: \(conversionError)")
                return
            }
            inputBuffer = convertedBuffer
        }
        
        // Write the buffer into the audio file
        do {
            try audioFile.write(from: inputBuffer)

            // Compute the sample value for the waveform
            updateMeterLevel(inputBuffer)
            
            // Update the recording duration only if we succeed to write the buffer
            currentTime += Double(inputBuffer.frameLength) / inputBuffer.format.sampleRate
            
            // Limit the recording time
            if currentTime >= maximumRecordingTime {
                MXLog.info("Maximum recording time reach (\(maximumRecordingTime))")
                Task { await stopRecording() }
            }
        } catch {
            MXLog.error("failed to write sample. \(error)")
        }
    }
    
    // MARK: Observers
    
    private func addObservers() {
        removeObservers()
        // Stop recording uppon UIApplication.didEnterBackgroundNotification notification
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                MXLog.warning("Application will resign active while recording.")
                Task { await self.stopRecording() }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name.AVAudioEngineConfigurationChange)
            .sink { [weak self] _ in
                guard let self else { return }
                self.handleConfigurationChange()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .sink { [weak self] notification in
                guard let self else { return }
                self.handleInterruption(notification: notification)
            }
            .store(in: &cancellables)
    }
    
    private func removeObservers() {
        cancellables.removeAll()
    }
    
    func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            MXLog.info("Interruption started: \(notification)")
            setInternalState(.suspended)
        case .ended:
            MXLog.info("Interruption ended: \(notification)")

            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                        
            if options.contains(.shouldResume) {
                do {
                    try audioEngine?.start()
                    setInternalState(.recording)
                } catch {
                    MXLog.debug("Error restarting audio: \(error)")
                    setInternalState(.error(.interrupted))
                }
            } else {
                MXLog.warning("AudioSession was interrupted: \(notification)")
                setInternalState(.error(.interrupted))
            }
            
        @unknown default:
            break
        }
    }
    
    func handleConfigurationChange() {
        guard let audioEngine else { return }
        MXLog.warning("Configuration changed: \(audioEngine.inputNode.inputFormat(forBus: 0))")
        if internalState != .suspended {
            Task { await stopRecording() }
        }
    }
    
    // MARK: Internal State
    
    private func setInternalState(_ state: InternalAudioRecorderState) {
        dispatchQueue.async { [weak self] in
            guard let self else { return }
            MXLog.debug("internal state: \(internalState) -> \(state)")
            internalState = state
            
            switch internalState {
            case .recording:
                actionsSubject.send(.didStartRecording)
            case .suspended:
                break
            case .stopped:
                actionsSubject.send(.didStopRecording)
            case .error(let error):
                cleanupAudioEngine()

                actionsSubject.send(.didFailWithError(error: error))
            }
        }
    }
    
    // MARK: Audio Metering
    
    private func scaledPower(power: Float) -> Float {
        guard power.isFinite else {
            return 0.0
        }
        
        let minDb: Float = silenceThreshold
        
        if power < minDb {
            return 0.0
        } else if power >= 1.0 {
            return 1.0
        } else {
            return (abs(minDb) - abs(power)) / abs(minDb)
        }
    }
    
    private func updateMeterLevel(_ buffer: AVAudioPCMBuffer) {
        // Get an array of pointer to each sample's data
        guard let channelData = buffer.floatChannelData else {
            return
        }
        
        // Compute RMS
        var rms: Float = .nan
        vDSP_rmsqv(channelData.pointee, buffer.stride, &rms, vDSP_Length(buffer.frameLength))
        
        // Convert to decibels
        let avgPower = 20 * log10(rms)
        
        meterLevel = scaledPower(power: avgPower)
    }
}
