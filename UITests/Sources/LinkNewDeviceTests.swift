//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@MainActor
class LinkNewDeviceTests: XCTestCase {
    enum Step {
        static let selectDevice = 1
        static let dismissed = 99
    }
    
    func testFlow() async throws {
        let app = Application.launch(.linkNewDevice)
        try await app.assertScreenshot(step: Step.selectDevice)
        
        let cancelButton = app.buttons[A11yIdentifiers.linkNewDeviceScreen.cancel]
        cancelButton.tap()
        
        try await app.assertScreenshot(step: Step.dismissed)
    }
}
