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

class StartChatScreenUITests: XCTestCase {
    func testLanding() {
        let app = Application.launch(.startChat)
        app.assertScreenshot(.startChat)
    }
    
    func testSearchWithNoResults() {
        let app = Application.launch(.startChat)
        let searchField = app.searchFields.firstMatch
        searchField.clearAndTypeText("Someone")
        XCTAssert(app.staticTexts[A11yIdentifiers.startChatScreen.searchNoResults].waitForExistence(timeout: 1.0))
        app.assertScreenshot(.startChat, step: 1)
    }
    
    func testSearchWithResults() {
        let app = Application.launch(.startChatWithSearchResults)
        let searchField = app.searchFields.firstMatch
        searchField.clearAndTypeText("Someone")
        XCTAssertFalse(app.staticTexts[A11yIdentifiers.startChatScreen.searchNoResults].waitForExistence(timeout: 1.0))
        XCTAssertEqual(app.collectionViews.firstMatch.cells.count, 1)
        app.assertScreenshot(.startChat, step: 2)
    }
}
