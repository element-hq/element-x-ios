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

class AudioRecorder: NSObject, AudioRecorderProtocol, AVAudioRecorderDelegate {
    private let silenceThreshold: Float = -50.0
    
    private var audioRecorder: AVAudioRecorder?
    private let audioSession = AVAudioSession.sharedInstance()
    private var cancellables = Set<AnyCancellable>()
    private let actionsSubject: PassthroughSubject<AudioRecorderAction, Never> = .init()
    var actions: AnyPublisher<AudioRecorderAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var displayLink: CADisplayLink?

    var url: URL? {
        audioRecorder?.url
    }
    
    private(set) var currentTime: TimeInterval = 0.0
    
    var isRecording: Bool {
        audioRecorder?.isRecording ?? false
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
        
    func peakPowerForChannelNumber(_ channelNumber: Int) -> Float {
        guard isRecording, let audioRecorder else {
            return 0.0
        }
        
        audioRecorder.updateMeters()
        return normalizedPowerLevelFromDecibels(audioRecorder.peakPower(forChannel: channelNumber))
    }
    
    func averagePowerForChannelNumber(_ channelNumber: Int) -> Float {
        guard isRecording, let audioRecorder else {
            return 0.0
        }
        
        audioRecorder.updateMeters()
        return normalizedPowerLevelFromDecibels(audioRecorder.averagePower(forChannel: channelNumber))
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
            let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                            AVSampleRateKey: 48000,
                            AVEncoderBitRateKey: 128_000,
                            AVNumberOfChannelsKey: 1,
                            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
            
            do {
                setupAudioSession()
                let url = URL.temporaryDirectory.appendingPathComponent("voice-message-\(recordID.identifier).m4a")
                let audioRecorder = try AVAudioRecorder(url: url, settings: settings)
                audioRecorder.delegate = self
                audioRecorder.isMeteringEnabled = true
                if audioRecorder.record() {
                    MXLog.debug("starting display link - audio")
                    displayLink = CADisplayLink(target: self, selector: #selector(updateRecordingTime))
                    displayLink?.preferredFrameRateRange = .init(minimum: 5, maximum: 10)
                    displayLink?.add(to: RunLoop.main, forMode: .common)
                    self.audioRecorder = audioRecorder
                    completion(.success(()))
                } else {
                    MXLog.error("audio recording failed to start")
                    completion(.failure(.recordingFailed))
                }
            } catch {
                MXLog.error("audio recording failed to start. \(error)")
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
            guard let audioRecorder, audioRecorder.isRecording else {
                return
            }
            audioRecorder.stop()
            MXLog.debug("audio recorder stopped")
        }
    }
    
    private func deleteRecording(completion: @escaping () -> Void) {
        dispatchQueue.async { [weak self] in
            defer {
                completion()
            }
            guard let self else { return }
            audioRecorder?.deleteRecording()
        }
    }
    
    @objc private func updateRecordingTime(displayLink: CADisplayLink) {
        if let audioRecorder, audioRecorder.isRecording {
            if audioRecorder.currentTime > 0 {
                currentTime = audioRecorder.currentTime
            }
        } else {
            MXLog.debug("invalidating display link - audio")
            displayLink.invalidate()
        }
    }
    
    private func audioRecorderDidStop() {
        actionsSubject.send(.didStopRecording)
    }
    
    // MARK: - AVAudioRecorderDelegate
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully success: Bool) {
        releaseAudioSession()
        if success {
            MXLog.info("audio recorder did finish recording.")
            audioRecorderDidStop()
        } else {
            MXLog.error("audio recorder did finish recording with an error.")
            actionsSubject.send(.didFailWithError(error: AudioRecorderError.genericError))
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        releaseAudioSession()
        MXLog.error("audio recorder encode error did occur. \(error?.localizedDescription ?? "")")
        if let error {
            actionsSubject.send(.didFailWithError(error: .internalError(error: error)))
        } else {
            actionsSubject.send(.didFailWithError(error: .genericError))
        }
    }
    
    private func normalizedPowerLevelFromDecibels(_ decibels: Float) -> Float {
        decibels / silenceThreshold
    }
}
