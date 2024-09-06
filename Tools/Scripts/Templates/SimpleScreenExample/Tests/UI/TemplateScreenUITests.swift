//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@MainActor
class TemplateScreenUITests: XCTestCase {
    func testScreen() async throws {
        let app = Application.launch(.templateScreen)
        
        let title = app.staticTexts["Template title"]
        XCTAssert(title.exists)

        try await app.assertScreenshot(.templateScreen)
    }
}
