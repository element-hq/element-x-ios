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
import Foundation
import UIKit

enum AudioRecorderRecordingState {
    case recording
    case stopped
    case error
}

@MainActor
class AudioRecorderState: ObservableObject, Identifiable {
    let id = UUID()
    
    @Published private(set) var recordingState: AudioRecorderRecordingState = .stopped
    @Published private(set) var duration = 0.0
    @Published private(set) var waveformSamples: [Float] = []
    
    private weak var audioRecorder: AudioRecorderProtocol?
    private var cancellables: Set<AnyCancellable> = []
    private var displayLink: CADisplayLink?
    
    func attachAudioRecorder(_ audioRecorder: AudioRecorderProtocol) {
        recordingState = .stopped
        self.audioRecorder = audioRecorder
        subscribeToAudioRecorder(audioRecorder)
        if audioRecorder.isRecording {
            recordingState = .recording
            startPublishUpdates()
        }
    }
    
    func detachAudioRecorder() async {
        if let audioRecorder, audioRecorder.isRecording {
            await audioRecorder.stopRecording()
        }
        stopPublishUpdates()
        waveformSamples = []
        cancellables = []
        audioRecorder = nil
        recordingState = .stopped
    }
    
    func reportError() {
        recordingState = .error
    }
    
    // MARK: - Private
    
    private func subscribeToAudioRecorder(_ audioRecorder: AudioRecorderProtocol) {
        audioRecorder.actions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                guard let self else {
                    return
                }
                self.handleAudioRecorderAction(action)
            }
            .store(in: &cancellables)
    }
    
    private func handleAudioRecorderAction(_ action: AudioRecorderAction) {
        switch action {
        case .didStartRecording:
            startPublishUpdates()
            recordingState = .recording
        case .didStopRecording:
            stopPublishUpdates()
            recordingState = .stopped
        case .didFailWithError:
            stopPublishUpdates()
            recordingState = .stopped
        }
    }
    
    private func startPublishUpdates() {
        if displayLink != nil {
            stopPublishUpdates()
        }
        displayLink = CADisplayLink(target: self, selector: #selector(publishUpdate))
        displayLink?.preferredFrameRateRange = .init(minimum: 30, maximum: 60)
        displayLink?.add(to: .current, forMode: .common)
    }
    
    // periphery:ignore:parameters displayLink - required for objc selector
    @objc private func publishUpdate(displayLink: CADisplayLink) {
        if let currentTime = audioRecorder?.currentTime {
            duration = currentTime
        }
        if let averagePower = audioRecorder?.averagePower() {
            waveformSamples.append(1.0 - averagePower)
        }
    }
    
    private func stopPublishUpdates() {
        displayLink?.invalidate()
        displayLink = nil
    }
}

extension AudioRecorderState: Equatable {
    nonisolated static func == (lhs: AudioRecorderState, rhs: AudioRecorderState) -> Bool {
        lhs.id == rhs.id
    }
}
