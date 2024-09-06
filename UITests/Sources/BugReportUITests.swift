//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@MainActor
class BugReportUITests: XCTestCase {
    func testInitialStateComponents() async throws {
        let app = Application.launch(.bugReport)
        
        // Initial state without a screenshot attached.
        try await app.assertScreenshot(.bugReport, step: 0)
    }
    
    func testReportText() async throws {
        let app = Application.launch(.bugReport)
        
        // Type 4 characters and the send button should be disabled.
        app.textViews[A11yIdentifiers.bugReportScreen.report].clearAndTypeText("Text")
        XCTAssert(app.switches[A11yIdentifiers.bugReportScreen.sendLogs].isOn)
        XCTAssert(!app.switches[A11yIdentifiers.bugReportScreen.canContact].isOn)
        try await app.assertScreenshot(.bugReport, step: 2)
        
        // Type more than 4 characters and send the button should become enabled.
        app.textViews[A11yIdentifiers.bugReportScreen.report].clearAndTypeText("Longer text")
        XCTAssert(app.switches[A11yIdentifiers.bugReportScreen.sendLogs].isOn)
        XCTAssert(!app.switches[A11yIdentifiers.bugReportScreen.canContact].isOn)
        try await app.assertScreenshot(.bugReport, step: 3)
    }
}

private extension XCUIElement {
    var isOn: Bool {
        (value as? String) == "1"
    }
}
