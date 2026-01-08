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
        static let linkMobileDevice = 2
        static let linkDesktopComputer = 3
        static let dismissed = 99
    }
    
    func testFlow() async throws {
        // Root screen
        let app = Application.launch(.linkNewDevice)
        try await app.assertScreenshot(step: Step.selectDevice)
        
        // Link showing a QR code
        let mobileDeviceButton = app.buttons[A11yIdentifiers.linkNewDeviceScreen.mobileDevice]
        mobileDeviceButton.tap()
        try await app.assertScreenshot(step: Step.linkMobileDevice)
        
        // Pop back to the root screen
        let backButton = app.buttons["Link new device"]
        backButton.tap()
        try await app.assertScreenshot(step: Step.selectDevice)
        
        // Link scanning a QR code
        let desktopComputerButton = app.buttons[A11yIdentifiers.linkNewDeviceScreen.desktopComputer]
        desktopComputerButton.tap()
        try await app.assertScreenshot(step: Step.linkDesktopComputer)
        
        // Pop back to the root screen
        backButton.tap()
        try await app.assertScreenshot(step: Step.selectDevice)
        
        // Dismiss the flow
        let cancelButton = app.buttons[A11yIdentifiers.linkNewDeviceScreen.cancel]
        cancelButton.tap()
        try await app.assertScreenshot(step: Step.dismissed)
    }
}
