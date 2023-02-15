//
// Copyright 2022 New Vector Ltd
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

import ElementX
import XCTest

class BugReportUITests: XCTestCase {
    func testInitialStateComponents() {
        let app = Application.launch(.bugReport)
        
        // Initial state without a screenshot attached.
        XCTAssert(app.buttons[A11yIdentifiers.bugReportScreen.attachScreenshot].exists)
        app.assertScreenshot(.bugReport, step: 0)
    }

    func testToggleSendingLogs() {
        let app = Application.launch(.bugReport)

        app.switches[A11yIdentifiers.bugReportScreen.sendLogs].tap()

        let sendingLogsToggle = app.switches[A11yIdentifiers.bugReportScreen.sendLogs]
        XCTAssert(sendingLogsToggle.exists)
        XCTAssertFalse(sendingLogsToggle.isOn)

        XCTAssert(app.buttons[A11yIdentifiers.bugReportScreen.attachScreenshot].exists)
        app.assertScreenshot(.bugReport, step: 1)
    }

    func testReportText() {
        let app = Application.launch(.bugReport)

        // Type 4 characters and the send button should be disabled.
        app.textViews[A11yIdentifiers.bugReportScreen.report].clearAndTypeText("Text")
        XCTAssertFalse(app.buttons[A11yIdentifiers.bugReportScreen.send].isEnabled)
        app.assertScreenshot(.bugReport, step: 2)

        // Type more than 4 characters and send the button should become enabled.
        app.textViews[A11yIdentifiers.bugReportScreen.report].clearAndTypeText("Longer text")
        XCTAssert(app.buttons[A11yIdentifiers.bugReportScreen.send].isEnabled)
        app.assertScreenshot(.bugReport, step: 3)
    }

    func testInitialStateComponentsWithScreenshot() {
        let app = Application.launch(.bugReportWithScreenshot)
        
        // Initial state with a screenshot attached.
        XCTAssert(app.images[A11yIdentifiers.bugReportScreen.screenshot].exists)
        XCTAssert(app.buttons[A11yIdentifiers.bugReportScreen.removeScreenshot].exists)
        XCTAssertFalse(app.buttons[A11yIdentifiers.bugReportScreen.attachScreenshot].exists)
        app.assertScreenshot(.bugReportWithScreenshot)
    }
}

extension XCUIElement {
    var isOn: Bool {
        (value as? String) == "1"
    }
}
