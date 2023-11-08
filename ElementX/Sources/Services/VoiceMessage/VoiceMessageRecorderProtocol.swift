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

enum VoiceMessageRecorderError: Error {
    case genericError
    case missingRecordingFile
    case previewNotAvailable
    case audioRecorderError(AudioRecorderError)
    case waveformAnalysisError
    case failedSendingVoiceMessage
}

enum VoiceMessageRecorderAction {
    case didStartRecording(audioRecorder: AudioRecorderProtocol)
    case didStopRecording(previewState: AudioPlayerState, url: URL)
    case didFailWithError(error: VoiceMessageRecorderError)
}

protocol VoiceMessageRecorderProtocol {
    var audioRecorder: AudioRecorderProtocol { get }
    var previewAudioPlayerState: AudioPlayerState? { get }
    var recordingURL: URL? { get }
    var recordingDuration: TimeInterval { get }

    var actions: AnyPublisher<VoiceMessageRecorderAction, Never> { get }

    func startRecording() async
    func stopRecording() async
    func cancelRecording() async
    func startPlayback() async -> Result<Void, VoiceMessageRecorderError>
    func pausePlayback()
    func stopPlayback() async
    func seekPlayback(to progress: Double) async
    func deleteRecording() async
    
    func buildRecordingWaveform() async -> Result<[UInt16], VoiceMessageRecorderError>
    func sendVoiceMessage(inRoom roomProxy: RoomProxyProtocol, audioConverter: AudioConverterProtocol) async -> Result<Void, VoiceMessageRecorderError>
}

// sourcery: AutoMockable
extension VoiceMessageRecorderProtocol { }
