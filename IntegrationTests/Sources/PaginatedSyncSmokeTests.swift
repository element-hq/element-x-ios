//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

/// Paginated Sync experiment smoke test: logs into a plain synapse (password
/// login, no MAS) whose experimental `org.matrix.paginated_sync` endpoint
/// drives the room list (the app setting defaults to on for this branch), and
/// checks the room list populates.
///
/// Expects INTEGRATION_TESTS_HOST / _USERNAME / _PASSWORD in the environment,
/// e.g. host `http://127.0.0.1:8008` with the `localtest` seeded server.
@MainActor
final class PaginatedSyncSmokeTests: XCTestCase {
    private var doesNotExistPredicate: NSPredicate {
        NSPredicate(format: "exists == 0")
    }

    func testRoomListLoadsViaPaginatedSync() throws {
        let app = Application.launch()

        let getStartedButton = app.buttons[A11yIdentifiers.authenticationStartScreen.signIn]
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 10.0))
        getStartedButton.tap(.center)

        // Point at the local server.
        let changeHomeserverButton = app.buttons[A11yIdentifiers.serverConfirmationScreen.changeServer]
        XCTAssertTrue(changeHomeserverButton.waitForExistence(timeout: 10.0))
        changeHomeserverButton.tap(.center)

        let homeserverTextField = app.textFields[A11yIdentifiers.changeServerScreen.server]
        XCTAssertTrue(homeserverTextField.waitForExistence(timeout: 10.0))
        homeserverTextField.clearAndTypeText(app.homeserver ?? "http://127.0.0.1:8008", app: app)

        let confirmButton = app.buttons[A11yIdentifiers.changeServerScreen.continue]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 10.0))
        confirmButton.tap(.center)

        expectation(for: doesNotExistPredicate, evaluatedWith: confirmButton)
        waitForExpectations(timeout: 60.0)

        let continueButton = app.buttons[A11yIdentifiers.serverConfirmationScreen.continue]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 10.0))
        continueButton.tap(.center)

        // Plain synapse: the native password login screen.
        let usernameTextField = app.textFields[A11yIdentifiers.loginScreen.emailUsername]
        XCTAssertTrue(usernameTextField.waitForExistence(timeout: 30.0), "Native login screen never appeared")
        usernameTextField.clearAndTypeText(app.username, app: app)

        let passwordTextField = app.secureTextFields[A11yIdentifiers.loginScreen.password]
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 10.0))
        passwordTextField.clearAndTypeText(app.password, app: app)

        let loginButton = app.buttons[A11yIdentifiers.loginScreen.continue]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 10.0))
        loginButton.tap(.center)

        // Home screen appears once logged in.
        let profileButton = app.buttons[A11yIdentifiers.homeScreen.userAvatar]
        XCTAssertTrue(profileButton.waitForExistence(timeout: 120.0), "Never reached the home screen")

        // Dismiss the system password-saving dialog; it may belong to the app
        // or to springboard depending on the OS version, and can lag the home
        // screen by a few seconds.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for _ in 0..<5 {
            let dismissed = [app, springboard].contains { candidate in
                let notNowButton = candidate.buttons["Not Now"].firstMatch
                guard notNowButton.waitForExistence(timeout: 2.0) else { return false }
                sleep(1) // Let the sheet settle before tapping.
                notNowButton.tap(.center)
                return true
            }
            if dismissed {
                break
            }
        }

        // The seeded account has 120 rooms named "Room NNN"; the most recently
        // active ones surface at the top of the list as it loads via paginated
        // sync.
        let seededRoom = app.staticTexts
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Room ")).firstMatch
        XCTAssertTrue(seededRoom.waitForExistence(timeout: 60.0), "No seeded room appeared in the room list")

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.lifetime = .keepAlways
        add(attachment)

        // Let the backlog drain, then confirm steady state didn't wedge:
        // send nothing, just assert the list is still there and the app alive.
        Thread.sleep(forTimeInterval: 10.0)
        XCTAssertTrue(seededRoom.exists, "Room list vanished after the drain")
    }
}
