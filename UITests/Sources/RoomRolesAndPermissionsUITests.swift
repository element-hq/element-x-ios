//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@MainActor
class RoomRolesAndPermissionsUITests: XCTestCase {
    var app: XCUIApplication!
    
    @MainActor enum Step {
        static let rolesAndPermissions = 0
        static let administratorsRole = 1
        static let moderatorsRole = 2
        static let roomDetailsPermissions = 3
        static let messagesAndContentPermissions = 4
        static let memberModerationPermissions = 5
    }
    
    func testFlow() async throws {
        app = Application.launch(.roomRolesAndPermissionsFlow)
        
        try await app.assertScreenshot(.roomRolesAndPermissionsFlow, step: Step.rolesAndPermissions)
        
        app.buttons[A11yIdentifiers.roomRolesAndPermissionsScreen.administrators].tap()
        try await app.assertScreenshot(.roomRolesAndPermissionsFlow, step: Step.administratorsRole)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        
        app.buttons[A11yIdentifiers.roomRolesAndPermissionsScreen.moderators].tap()
        try await app.assertScreenshot(.roomRolesAndPermissionsFlow, step: Step.moderatorsRole)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        
        app.buttons[A11yIdentifiers.roomRolesAndPermissionsScreen.roomDetails].tap()
        try await app.assertScreenshot(.roomRolesAndPermissionsFlow, step: Step.roomDetailsPermissions)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        
        app.buttons[A11yIdentifiers.roomRolesAndPermissionsScreen.messagesAndContent].tap()
        try await app.assertScreenshot(.roomRolesAndPermissionsFlow, step: Step.messagesAndContentPermissions)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        
        app.buttons[A11yIdentifiers.roomRolesAndPermissionsScreen.memberModeration].tap()
        try await app.assertScreenshot(.roomRolesAndPermissionsFlow, step: Step.memberModerationPermissions)
    }
}
