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

import XCTest
import ElementX

class BugReportUITests: XCTestCase {

    func testInitialStateComponents() {
        let app = Application.launch()
        app.goToScreenWithIdentifier(.bugReport)

        XCTAssert(app.navigationBars["Bug report"].exists)
        XCTAssert(app.staticTexts["reportBugDescription"].exists)
        XCTAssert(app.staticTexts["sendLogsDescription"].exists)
        XCTAssert(app.textViews["reportTextView"].exists)
        let sendingLogsToggle = app.switches["sendLogsToggle"]
        XCTAssert(sendingLogsToggle.exists)
        XCTAssert(sendingLogsToggle.isOn)
        XCTAssert(app.staticTexts["sendLogsText"].exists)
        let sendButton = app.buttons["sendButton"]
        XCTAssert(sendButton.exists)
        XCTAssertFalse(sendButton.isEnabled)
        XCTAssertFalse(app.images["screenshotImage"].exists)
        XCTAssertFalse(app.buttons["removeScreenshotButton"].exists)
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

        XCTAssert(app.navigationBars["Bug report"].exists)
        XCTAssert(app.staticTexts["reportBugDescription"].exists)
        XCTAssert(app.staticTexts["sendLogsDescription"].exists)

        XCTAssert(app.textViews["reportTextView"].exists)
        let sendingLogsToggle = app.switches["sendLogsToggle"]
        XCTAssert(sendingLogsToggle.exists)
        XCTAssert(sendingLogsToggle.isOn)
        XCTAssert(app.staticTexts["sendLogsText"].exists)
        let sendButton = app.buttons["sendButton"]
        XCTAssert(sendButton.exists)
        XCTAssertFalse(sendButton.isEnabled)
        XCTAssert(app.images["screenshotImage"].exists)
        XCTAssert(app.buttons["removeScreenshotButton"].exists)
    }

}

extension XCUIElement {
    var isOn: Bool {
        (value as? String) == "1"
    }
}
