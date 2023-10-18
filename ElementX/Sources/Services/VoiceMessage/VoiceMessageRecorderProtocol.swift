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

import Foundation

enum VoiceMessageRecorderError: Error {
    case genericError
    case previewNotAvailable
}

protocol VoiceMessageRecorderProtocol {
    var previewPlayerState: AudioPlayerState? { get }
    var recordingURL: URL? { get }
    var recordingDuration: TimeInterval { get }
    var recordingWaveform: Waveform? { get }
    
    @MainActor func startRecording() -> AudioRecorderProtocol
    func stopRecording() async throws
    func cancelRecording() async throws
    func startPlayback() async throws
    func pausePlayback()
    func stopPlayback() async
    func seekPlayback(to progress: Double) async
    func deleteRecording()
    
    func stop() async throws
}

// sourcery: AutoMockable
extension VoiceMessageRecorderProtocol { }
