//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@MainActor
class StartChatScreenUITests: XCTestCase {
    func testLanding() async throws {
        let app = Application.launch(.startChat)
        try await app.assertScreenshot(.startChat)
    }
    
    func testSearchWithNoResults() async throws {
        let app = Application.launch(.startChat)
        let searchField = app.searchFields.firstMatch
        searchField.clearAndTypeText("None\n", app: app)
        XCTAssert(app.staticTexts[A11yIdentifiers.startChatScreen.searchNoResults].waitForExistence(timeout: 1.0))
        try await app.assertScreenshot(.startChat, step: 1, delay: .seconds(0.5))
    }
    
    func testSearchWithResults() async throws {
        let app = Application.launch(.startChatWithSearchResults)
        let searchField = app.searchFields.firstMatch
        searchField.clearAndTypeText("Bob\n", app: app)
        XCTAssertFalse(app.staticTexts[A11yIdentifiers.startChatScreen.searchNoResults].waitForExistence(timeout: 1.0))
        XCTAssertEqual(app.collectionViews.firstMatch.cells.count, 2)
        try await app.assertScreenshot(.startChat, step: 2, delay: .seconds(0.5))
    }
}
