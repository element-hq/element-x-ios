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
        audioRecorderMock.underlyingActions = audioRecorderActions
        audioRecorderMock.currentTime = 0.0
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
        
        audioRecorderState.detachAudioRecorder()
        XCTAssert(audioRecorderMock.stopRecordingCalled)
        XCTAssertEqual(audioRecorderState.recordingState, .stopped)
    }
    
    func testReportError() async throws {
        XCTAssertEqual(audioRecorderState.recordingState, .stopped)
        audioRecorderState.reportError(AudioRecorderError.genericError)
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
