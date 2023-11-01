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

import AVFoundation
import Combine
import Foundation
import UIKit

class AudioRecorder: AudioRecorderProtocol {
    private var audioEngine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private let audioSession = AVAudioSession.sharedInstance()
    private var audioFormat: AVAudioFormat {
        let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: 48000,
                        AVEncoderBitRateKey: 128_000,
                        AVNumberOfChannelsKey: 1,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
        
        guard let audioFormat = AVAudioFormat(settings: settings) else {
            fatalError("Invalid audio settings.")
        }
        return audioFormat
    }
    
    private var cancellables = Set<AnyCancellable>()
    private let actionsSubject: PassthroughSubject<AudioRecorderAction, Never> = .init()
    var actions: AnyPublisher<AudioRecorderAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    private let silenceThreshold: Float = -50.0
    private var meterLevel: Float = 0

    private(set) var audioFileUrl: URL?
    
    var currentTime: TimeInterval = .zero
    
    var isRecording: Bool {
        audioEngine.isRunning
    }
        
    private let dispatchQueue = DispatchQueue(label: "io.element.elementx.audio_recorder", qos: .userInitiated)
    private var stopped = false
        
    func record(with recordID: AudioRecordingIdentifier) async {
        stopped = false
        guard await requestRecordPermission() else {
            actionsSubject.send(.didFailWithError(error: .recordPermissionNotGranted))
            return
        }
        let result = await startRecording(with: recordID)
        switch result {
        case .success:
            actionsSubject.send(.didStartRecording)
        case .failure(let error):
            actionsSubject.send(.didFailWithError(error: error))
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
        
    private func addObservers() {
        // Stop recording uppon UIApplication.didEnterBackgroundNotification notification
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                MXLog.warning("Application will resign active while recording.")
                Task { await self.stopRecording() }
            }
            .store(in: &cancellables)
        
        // Stop recording if audio route changes
        NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
            .sink { [weak self] notification in
                guard let self else { return }
                self.handleRouteChange(notification: notification)
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
    
    private func requestRecordPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            audioSession.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    private func setupAudioSession() {
        MXLog.info("setup audio session")
        do {
            try audioSession.setAllowHapticsAndSystemSoundsDuringRecording(true)
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            MXLog.error("Could not redirect audio playback to speakers.")
        }
        addObservers()
    }
    
    private func releaseAudioSession() {
        MXLog.info("releasing audio session")
        try? audioSession.setActive(false)
        removeObservers()
    }
    
    func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        MXLog.info("Audio session route changed (\(reason)). route: \(audioSession.currentRoute), category: \(audioSession.category)")
        audioEngine.pause()
        do {
            try audioEngine.start()
        } catch {
            MXLog.error("failed to resume audio engine after route change. \(error)")
        }
    }
    
    func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            MXLog.warning("AudioSession was interrupted: \(notification)")
            actionsSubject.send(.didFailWithError(error: .interrupted))
        case .ended:
            MXLog.debug("Interruption ended: \(notification)")
        @unknown default:
            break
        }
    }
    
    private func startRecording(with recordID: AudioRecordingIdentifier) async -> Result<Void, AudioRecorderError> {
        await withCheckedContinuation { continuation in
            startRecording(with: recordID) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    private func startRecording(with recordID: AudioRecordingIdentifier, completion: @escaping (Result<Void, AudioRecorderError>) -> Void) {
        dispatchQueue.async { [weak self] in
            guard let self, !self.stopped else {
                completion(.failure(.recordingCancelled))
                return
            }
            
            MXLog.debug("setting up audio session")
            setupAudioSession()

            let outputURL = URL.temporaryDirectory.appendingPathComponent("voice-message-\(recordID.identifier).m4a")
            audioFileUrl = outputURL
            do {
                MXLog.debug("creating audio file")
                let inputFormat = audioEngine.inputNode.inputFormat(forBus: 0)
                let fileFormat = audioFormat

                MXLog.debug("audio input format: \(inputFormat)")
                MXLog.debug("audio file format: \(fileFormat)")
                
                try audioFile = AVAudioFile(forWriting: outputURL, settings: fileFormat.settings)
                
                MXLog.debug("install tap")
                audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, time in
                    guard let self else { return }
                    
                    // Update the recording duration
                    self.currentTime += Double(buffer.frameLength) / buffer.format.sampleRate
                    
                    // Compute the sample value for the waveform
                    updateMeterLevel(buffer)
                    
                    // Write the buffer into the audio file
                    do {
                        try audioFile?.write(from: buffer)
                    } catch {
                        MXLog.error("failed to write sample. \(error)")
                    }
                }
                
                MXLog.debug("preparing audio engine")
                audioEngine.prepare()
                MXLog.debug("starting audio engine")
                try audioEngine.start()
                MXLog.debug("audio engine started")
                completion(.success(()))

            } catch {
                MXLog.error("audio recording failed to start. \(error)")
                releaseAudioSession()
                completion(.failure(.internalError(error: error)))
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
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
            audioFile = nil // this will close the file
            releaseAudioSession()
            MXLog.debug("audio recorder stopped")
            actionsSubject.send(.didStopRecording)
        }
    }
    
    private func deleteRecording(completion: @escaping () -> Void) {
        dispatchQueue.async { [weak self] in
            defer {
                completion()
            }
            guard let self else { return }
            if let audioFileUrl {
                try? FileManager.default.removeItem(at: audioFileUrl)
            }
            audioFileUrl = nil
        }
    }
    
    // MARK: Audio metering
    
    // https://www.kodeco.com/21672160-avaudioengine-tutorial-for-ios-getting-started?page=2

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
        guard let channelData = buffer.floatChannelData else {
            return
        }
        
        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0,
                                           to: Int(buffer.frameLength),
                                           by: buffer.stride)
            .map { channelDataValue[$0] }
        
        let rms = sqrt(channelDataValueArray.map { $0 * $0 }
            .reduce(0, +) / Float(buffer.frameLength))
        
        let avgPower = 20 * log10(rms)
        meterLevel = scaledPower(power: avgPower)
    }
}
