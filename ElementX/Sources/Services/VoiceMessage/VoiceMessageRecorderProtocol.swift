//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation

enum VoiceMessageRecorderError: Error {
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
    var previewAudioPlayerState: AudioPlayerState? { get }
    var isRecording: Bool { get }
    var recordingURL: URL? { get }

    var actions: AnyPublisher<VoiceMessageRecorderAction, Never> { get }

    func startRecording() async
    func stopRecording() async
    func cancelRecording() async
    func startPlayback() async -> Result<Void, VoiceMessageRecorderError>
    func pausePlayback()
    func stopPlayback() async
    func seekPlayback(to progress: Double) async
    func deleteRecording() async
    
    func sendVoiceMessage(inRoom roomProxy: JoinedRoomProxyProtocol, audioConverter: AudioConverterProtocol) async -> Result<Void, VoiceMessageRecorderError>
}

// sourcery: AutoMockable
extension VoiceMessageRecorderProtocol { }
