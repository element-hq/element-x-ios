//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation

enum AudioRecorderError: Error, Equatable {
    case unsupportedAudioFormat
    case audioSessionFailure
    case audioEngineFailure
    case audioFileCreationFailure
    case interrupted
    case recordingCancelled
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
