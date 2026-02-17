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

@MainActor
@Suite
struct AudioRecorderTests {
    private var audioRecorder: AudioRecorder!
    private var audioSessionMock: AudioSessionMock!
    
    init() async {
        audioSessionMock = AudioSessionMock()
        audioSessionMock.requestRecordPermissionClosure = { completion in
            completion(true)
        }
        audioRecorder = AudioRecorder(audioSession: audioSessionMock)
    }
    
    @Test
    mutating func recordWithoutPermission() async throws {
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
        #expect(!audioRecorder.isRecording)
    }
}
