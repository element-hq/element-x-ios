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
    
    private var cancellables = Set<AnyCancellable>()
    private let actionsSubject: PassthroughSubject<AudioRecorderAction, Never> = .init()
    var actions: AnyPublisher<AudioRecorderAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    var url: URL? {
        audioRecorder?.url
    }
    
    var currentTime: TimeInterval {
        audioRecorder?.currentTime ?? 0
    }
    
    var isRecording: Bool {
        audioRecorder?.isRecording ?? false
    }
    
    private let dispatchQueue = DispatchQueue(label: "io.element.elementx.audio_recorder", qos: .userInitiated)
    private var stopped = false
    
    func record(with recordID: AudioRecordingIdentifier) async -> Result<Void, AudioRecorderError> {
        stopped = false
        guard await requestRecordPermission() else {
            return .failure(.recordPermissionNotGranted)
        }
        let result = await startRecording(with: recordID)
        switch result {
        case .success:
            actionsSubject.send(.didStartRecording)
        case .failure(let error):
            actionsSubject.send(.didFailWithError(error: error))
        }
        return result
    }
    
    func stopRecording() async {
        await withCheckedContinuation { continuation in
            stopRecording {
                continuation.resume()
            }
        }
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
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                Task { await self.stopRecording() }
            }
            .store(in: &cancellables)
    }
    
    private func removeObservers() {
        cancellables.removeAll()
    }
    
    private func requestRecordPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    // MARK: - Private
    
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
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setAllowHapticsAndSystemSoundsDuringRecording(true)
                try audioSession.setCategory(.playAndRecord, mode: .default)
                try audioSession.setActive(true)
                let url = URL.temporaryDirectory.appendingPathComponent("voice-message-\(recordID.identifier).m4a")
                let audioRecorder = try AVAudioRecorder(url: url, settings: settings)
                audioRecorder.delegate = self
                audioRecorder.isMeteringEnabled = true
                if audioRecorder.record() {
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
    
    // MARK: - AVAudioRecorderDelegate
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully success: Bool) {
        try? AVAudioSession.sharedInstance().setActive(false)
        if success {
            actionsSubject.send(.didStopRecording)
        } else {
            MXLog.error("audio recorder did finish recording with an error.")
            actionsSubject.send(.didFailWithError(error: AudioRecorderError.genericError))
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        try? AVAudioSession.sharedInstance().setActive(false)
        MXLog.error("audio recorder encode error did occur. \(error?.localizedDescription ?? "")")
        actionsSubject.send(.didFailWithError(error: error ?? AudioRecorderError.genericError))
    }
    
    private func normalizedPowerLevelFromDecibels(_ decibels: Float) -> Float {
        decibels / silenceThreshold
    }
}
