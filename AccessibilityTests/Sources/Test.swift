//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@MainActor
class Test: XCTestCase {
    var app: XCUIApplication!
    
    func test() async throws {
        let client = try UITestsSignalling.Client(mode: .tests)
        app = Application.launch(viewID: "SecureBackupLogoutConfirmationScreen_Previews")
        await client.waitForApp()
        defer { try? client.stop() }
        
        try client.send(.nextPreview)
        forLoop: for await signal in client.signals.values {
            switch signal {
            case .nextPreviewReady(let name):
                try? app.performAccessibilityAudit { issue in
                    XCTFail("\(name): \(issue)")
                    return true
                }
                try? client.send(.nextPreview)
            case .noMorePreviews:
                break forLoop
            default:
                fatalError("Unhandled signal")
            }
        }
        
        app.terminate()
    }
}
