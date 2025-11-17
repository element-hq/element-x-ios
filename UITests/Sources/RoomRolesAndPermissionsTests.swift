//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@MainActor
class RoomRolesAndPermissionsUITests: XCTestCase {
    var app: XCUIApplication!
    
    @MainActor enum Step {
        static let rolesAndPermissions = 0
        static let administratorsRole = 1
        static let moderatorsRole = 2
        static let permissions = 3
    }
    
    func testFlow() async throws {
        app = Application.launch(.roomRolesAndPermissionsFlow)
        
        try await app.assertScreenshot(step: Step.rolesAndPermissions)
        
        app.buttons[A11yIdentifiers.roomRolesAndPermissionsScreen.administrators].tap()
        try await app.assertScreenshot(step: Step.administratorsRole)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        
        app.buttons[A11yIdentifiers.roomRolesAndPermissionsScreen.moderators].tap()
        try await app.assertScreenshot(step: Step.moderatorsRole)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        
        app.buttons[A11yIdentifiers.roomRolesAndPermissionsScreen.permissions].tap()
        try await app.assertScreenshot(step: Step.permissions)
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }
}
