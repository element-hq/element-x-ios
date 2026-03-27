//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@MainActor
class ServerLoginTests: XCTestCase {
    private var app: XCUIApplication!
    
    override func setUp() async throws {
        app = Application.launch()
    }
    
    func testLogin() throws {
        XCTAssertNotNil(app.homeserver, "INTEGRATION_TESTS_HOST environment variable must be set for this test to run.")

        try app.login(currentTestCase: self)

        app.logout()
    }
}
