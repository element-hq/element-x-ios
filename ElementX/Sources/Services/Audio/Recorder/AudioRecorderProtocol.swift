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

enum AudioRecorderError: Error, Equatable {
    case audioEngineFailure
    case audioFileCreationFailure
    case interrupted
    case recordingCancelled
    case recordingFailed
    case recordPermissionNotGranted
}

enum AudioRecorderAction {
    case didStartRecording
    case didStopRecording
    case didFailWithError(error: AudioRecorderError)
}

protocol AudioRecorderProtocol: AnyObject {
    var actions: AnyPublisher<AudioRecorderAction, Never> { get }
    var currentTime: TimeInterval { get }
    var isRecording: Bool { get }
    var audioFileURL: URL? { get }
    
    func record(audioFileURL: URL) async
    func stopRecording() async
    func deleteRecording() async
    func averagePower() -> Float
}

// sourcery: AutoMockable
extension AudioRecorderProtocol { }
