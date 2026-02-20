//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Foundation
import Testing

@Suite
@MainActor
struct AudioRecorderStateTests {
    private var audioRecorderState: AudioRecorderState!
    private var audioRecorderMock: AudioRecorderMock!
    
    private var audioRecorderActionsSubject: PassthroughSubject<AudioRecorderAction, Never>!
    private var audioRecorderActions: AnyPublisher<AudioRecorderAction, Never> {
        audioRecorderActionsSubject.eraseToAnyPublisher()
    }
    
    private func buildAudioRecorderMock() -> AudioRecorderMock {
        let audioRecorderMock = AudioRecorderMock()
        audioRecorderMock.isRecording = false
        audioRecorderMock.underlyingActions = audioRecorderActions
        audioRecorderMock.currentTime = 0.0
        audioRecorderMock.averagePowerReturnValue = 0
        return audioRecorderMock
    }
    
    init() async {
        audioRecorderActionsSubject = .init()
        audioRecorderState = AudioRecorderState()
        audioRecorderMock = buildAudioRecorderMock()
    }
    
    @Test
    func attach() {
        audioRecorderState.attachAudioRecorder(audioRecorderMock)
        #expect(audioRecorderState.recordingState == .stopped)
    }
    
    @Test
    mutating func detach() async {
        audioRecorderState.attachAudioRecorder(audioRecorderMock)
        audioRecorderMock.isRecording = true
        await audioRecorderState.detachAudioRecorder()
        #expect(audioRecorderMock.stopRecordingCalled)
        #expect(audioRecorderState.recordingState == .stopped)
    }
    
    @Test
    mutating func reportError() {
        #expect(audioRecorderState.recordingState == .stopped)
        audioRecorderState.reportError()
        #expect(audioRecorderState.recordingState == .error)
    }
    
    @Test
    func handlingAudioRecorderActionDidStartRecording() async throws {
        audioRecorderState.attachAudioRecorder(audioRecorderMock)
        
        let deferred = deferFulfillment(audioRecorderState.$recordingState) { action in
            switch action {
            case .recording:
                return true
            default:
                return false
            }
        }
        
        audioRecorderActionsSubject.send(.didStartRecording)
        try await deferred.fulfill()
        #expect(audioRecorderState.recordingState == .recording)
    }
    
    @Test
    func handlingAudioPlayerActionDidStopRecording() async throws {
        audioRecorderState.attachAudioRecorder(audioRecorderMock)
        
        let deferred = deferFulfillment(audioRecorderState.$recordingState) { action in
            switch action {
            case .stopped:
                return true
            default:
                return false
            }
        }
        
        audioRecorderActionsSubject.send(.didStopRecording)
        try await deferred.fulfill()
        
        // The state is expected to be .readyToPlay
        #expect(audioRecorderState.recordingState == .stopped)
    }
}
