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
