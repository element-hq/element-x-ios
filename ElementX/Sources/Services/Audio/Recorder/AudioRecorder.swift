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

enum AudioRecorderError: Error {
    case genericError
}

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
    
    func record() {
        let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: 48000,
                        AVEncoderBitRateKey: 128_000,
                        AVNumberOfChannelsKey: 1,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            let url = URL.temporaryDirectory.appendingPathComponent("voice-message.m4a")
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            actionsSubject.send(.didStartRecording)
        } catch {
            MXLog.error("audio recording failed: \(error)")
            actionsSubject.send(.didFailWithError(error: error))
        }
    }
    
    func stopRecording() async throws {
        guard let audioRecorder, audioRecorder.isRecording else {
            return
        }
        audioRecorder.stop()
    }
    
    func deleteRecording() {
        audioRecorder?.deleteRecording()
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
        // Stop recording uppon UIApplication.didBecomeActiveNotification notification
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                Task { try? await self.stopRecording() }
            }
            .store(in: &cancellables)
    }
    
    private func removeObservers() {
        cancellables.removeAll()
    }
        
    // MARK: - AVAudioRecorderDelegate
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully success: Bool) {
        try? AVAudioSession.sharedInstance().setActive(false)
        if success {
            actionsSubject.send(.didStopRecording)
        } else {
            actionsSubject.send(.didFailWithError(error: AudioRecorderError.genericError))
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        try? AVAudioSession.sharedInstance().setActive(false)
        actionsSubject.send(.didFailWithError(error: error ?? AudioRecorderError.genericError))
    }
    
    private func normalizedPowerLevelFromDecibels(_ decibels: Float) -> Float {
        decibels / silenceThreshold
    }
}
