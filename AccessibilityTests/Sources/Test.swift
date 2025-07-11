//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@MainActor
class AppLockUITests: XCTestCase {
    var app: XCUIApplication!
    
    func testFlowEnabled() async throws {
        app = Application.launch()
    }
}
