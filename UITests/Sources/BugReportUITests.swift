//
// Copyright 2021 New Vector Ltd
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
        let app = Application.launch()
        app.goToScreenWithIdentifier(.bugReport)

        verifyInitialStateComponents(in: app)

        XCTAssertFalse(app.images["screenshotImage"].exists)
        XCTAssertFalse(app.buttons["removeScreenshotButton"].exists)

        app.assertScreenshot(.bugReport)
    }

    func testToggleSendingLogs() {
        let app = Application.launch()
        app.goToScreenWithIdentifier(.bugReport)

        app.switches["sendLogsToggle"].tap()

        let sendingLogsToggle = app.switches["sendLogsToggle"]
        XCTAssert(sendingLogsToggle.exists)
        XCTAssertFalse(sendingLogsToggle.isOn)
    }

    func testReportText() {
        let app = Application.launch()
        app.goToScreenWithIdentifier(.bugReport)

        //  type 4 chars
        app.textViews["reportTextView"].tap()
        app.textViews["reportTextView"].typeText("Test")
        XCTAssertFalse(app.buttons["sendButton"].isEnabled)

        //  type one more char and see the button enabled
        app.textViews["reportTextView"].tap()
        app.textViews["reportTextView"].typeText("-")
        XCTAssert(app.buttons["sendButton"].isEnabled)
    }

    func testInitialStateComponentsWithScreenshot() {
        let app = Application.launch()
        app.goToScreenWithIdentifier(.bugReportWithScreenshot)

        verifyInitialStateComponents(in: app)
        
        XCTAssert(app.images["screenshotImage"].exists)
        XCTAssert(app.buttons["removeScreenshotButton"].exists)

        app.assertScreenshot(.bugReportWithScreenshot)
    }

    func verifyInitialStateComponents(in app: XCUIApplication) {
        XCTAssert(app.navigationBars[ElementL10n.titleActivityBugReport].exists)
        let descLabel = app.staticTexts["reportBugDescription"]
        XCTAssert(descLabel.exists)
        XCTAssertEqual(descLabel.label, ElementL10n.sendBugReportDescription)
        let sendLogsDescLabel = app.staticTexts["sendLogsDescription"]
        XCTAssert(sendLogsDescLabel.exists)
        XCTAssertEqual(sendLogsDescLabel.label, ElementL10n.sendBugReportLogsDescription)
        XCTAssert(app.textViews["reportTextView"].exists)
        let sendLogsToggle = app.switches["sendLogsToggle"]
        XCTAssert(sendLogsToggle.exists)
        XCTAssert(sendLogsToggle.isOn)
        let sendLogsLabel = app.staticTexts["sendLogsText"]
        XCTAssert(sendLogsLabel.exists)
        XCTAssertEqual(sendLogsLabel.label, ElementL10n.sendBugReportIncludeLogs)
        let sendButton = app.buttons["sendButton"]
        XCTAssert(sendButton.exists)
        XCTAssertEqual(sendButton.label, ElementL10n.actionSend)
        XCTAssertFalse(sendButton.isEnabled)
    }
}

extension XCUIElement {
    var isOn: Bool {
        (value as? String) == "1"
    }
}
