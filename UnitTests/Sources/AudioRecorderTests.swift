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
class AudioRecorderTests: XCTestCase {
    private var audioRecorder: AudioRecorder!
    private var audioSessionMock: AudioSessionMock!
    
    override func setUp() async throws {
        audioSessionMock = AudioSessionMock()
        audioSessionMock.requestRecordPermissionClosure = { completion in
            completion(true)
        }
        audioRecorder = AudioRecorder(audioSession: audioSessionMock)
    }
    
    override func tearDown() async throws {
        await audioRecorder?.cancelRecording()
    }
    
    func testRecordWithoutPermission() async throws {
        audioSessionMock.requestRecordPermissionClosure = { completion in
            completion(false)
        }
        
        let deferred = deferFulfillment(audioRecorder.actions) { action in
            switch action {
            case .didFailWithError(.recordPermissionNotGranted):
                return true
            default:
                return false
            }
        }
        let url = URL.temporaryDirectory.appendingPathComponent("test-voice-message").appendingPathExtension("m4a")
        await audioRecorder.record(audioFileURL: url)
        try await deferred.fulfill()
        XCTAssertFalse(audioRecorder.isRecording)
    }
}
