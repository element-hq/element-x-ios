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

class ReportContentScreenUITests: XCTestCase {
    func testInitialStateComponents() {
        let app = Application.launch(.reportContent)
        app.assertScreenshot(.reportContent, step: 0)
    }
    
    func testToggleIgnoreUser() {
        let app = Application.launch(.reportContent)
        
        // Don't know why, but there's an issue on CI where the toggle is tapped but doesn't respond. Waiting for
        // it fixes this (even it it already exists). Reproducible by running the test after quitting the simulator.
        let sendingLogsToggle = app.switches[A11yIdentifiers.reportContent.ignoreUser]
        XCTAssertTrue(sendingLogsToggle.waitForExistence(timeout: 1))
        XCTAssertFalse(sendingLogsToggle.isOn)
        
        sendingLogsToggle.tap()
        
        XCTAssertTrue(sendingLogsToggle.isOn)
        app.assertScreenshot(.reportContent, step: 1)
    }
}
