//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@MainActor
class SettingsScreenTests: XCTestCase {
    func testLaunchesBeforeLogin() {
        let app = Application.launch(.settingsScreen)

        XCTAssertTrue(app.buttons[A11yIdentifiers.settingsScreen.done].waitForExistence(timeout: 5.0))
        XCTAssertTrue(app.descendants(matching: .any)[A11yIdentifiers.settingsScreen.notifications].waitForExistence(timeout: 5.0))
    }
}
