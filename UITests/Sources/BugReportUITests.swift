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
        app.goToScreenWithIdentifier("Bug report screen")

        XCTAssert(app.navigationBars["Bug report"].exists)
        XCTAssert(app.staticTexts["Report Bug"].exists)
        XCTAssert(app.textViews["Report"].exists)
        XCTAssert(app.images["Disable Sending Logs"].exists)
        XCTAssert(app.staticTexts["Send Logs"].exists)
        XCTAssert(app.buttons["Send"].exists)
        XCTAssertFalse(app.buttons["Send"].isEnabled)
        XCTAssert(app.buttons["Cancel"].exists)
        XCTAssert(app.buttons["Cancel"].isEnabled)
        XCTAssertFalse(app.images["Screenshot"].exists)
        XCTAssertFalse(app.buttons["Remove Screenshot"].exists)
    }

    func testToggleSendingLogs() {
        let app = Application.launch()
        app.goToScreenWithIdentifier("Bug report screen")

        app.images["Disable Sending Logs"].tap()

        XCTAssert(app.images["Enable Sending Logs"].exists)
    }

    func testReportText() {
        let app = Application.launch()
        app.goToScreenWithIdentifier("Bug report screen")

        //  type 4 chars
        app.textViews["Report"].tap()
        app.textViews["Report"].typeText("Test")
        XCTAssertFalse(app.buttons["Send"].isEnabled)

        //  type one more char and see the button enabled
        app.textViews["Report"].tap()
        app.textViews["Report"].typeText("-")
        XCTAssert(app.buttons["Send"].isEnabled)
    }

    func testInitialStateComponentsWithScreenshot() {
        let app = Application.launch()
        app.goToScreenWithIdentifier("Bug report screen with screenshot")

        XCTAssert(app.navigationBars["Bug report"].exists)
        XCTAssert(app.staticTexts["Report Bug"].exists)
        XCTAssert(app.textViews["Report"].exists)
        XCTAssert(app.images["Disable Sending Logs"].exists)
        XCTAssert(app.staticTexts["Send Logs"].exists)
        XCTAssert(app.buttons["Send"].exists)
        XCTAssertFalse(app.buttons["Send"].isEnabled)
        XCTAssert(app.buttons["Cancel"].exists)
        XCTAssert(app.buttons["Cancel"].isEnabled)
        XCTAssert(app.images["Screenshot"].exists)
        XCTAssert(app.buttons["Remove Screenshot"].exists)
    }

}
