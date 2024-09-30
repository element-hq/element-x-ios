//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
@testable import ElementX
import Foundation
import XCTest

@MainActor
class AudioRecorderStateTests: XCTestCase {
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
    
    override func setUp() async throws {
        audioRecorderActionsSubject = .init()
        audioRecorderState = AudioRecorderState()
        audioRecorderMock = buildAudioRecorderMock()
    }
    
    func testAttach() async throws {
        audioRecorderState.attachAudioRecorder(audioRecorderMock)
        XCTAssertEqual(audioRecorderState.recordingState, .stopped)
    }
    
    func testDetach() async throws {
        audioRecorderState.attachAudioRecorder(audioRecorderMock)
        audioRecorderMock.isRecording = true
        await audioRecorderState.detachAudioRecorder()
        XCTAssert(audioRecorderMock.stopRecordingCalled)
        XCTAssertEqual(audioRecorderState.recordingState, .stopped)
    }
    
    func testReportError() async throws {
        XCTAssertEqual(audioRecorderState.recordingState, .stopped)
        audioRecorderState.reportError()
        XCTAssertEqual(audioRecorderState.recordingState, .error)
    }
    
    func testHandlingAudioRecorderActionDidStartRecording() async throws {
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
        XCTAssertEqual(audioRecorderState.recordingState, .recording)
    }

    func testHandlingAudioPlayerActionDidStopRecording() async throws {
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
        XCTAssertEqual(audioRecorderState.recordingState, .stopped)
    }
}
