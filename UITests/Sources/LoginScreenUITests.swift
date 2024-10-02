//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@MainActor
class LoginScreenUITests: XCTestCase {
    func testMatrixDotOrg() async throws {
        // Given the initial login screen which defaults to matrix.org.
        let app = Application.launch(.login)
        try await app.assertScreenshot(.login)
        
        // When typing in a username and password.
        app.textFields[A11yIdentifiers.loginScreen.emailUsername].clearAndTypeText("@test:matrix.org")
        app.secureTextFields[A11yIdentifiers.loginScreen.password].clearAndTypeText("12345678")
        
        // Then the form should be ready to submit.
        try await app.assertScreenshot(.login, step: 0)
    }
    
    func testUnsupported() async throws {
        // Given the initial login screen.
        let app = Application.launch(.login)
        
        // When entering a username on a homeserver with an unsupported flow.
        app.textFields[A11yIdentifiers.loginScreen.emailUsername].clearAndTypeText("@test:server.net\n")
        
        // Then the screen should not allow login to continue.
        try await app.assertScreenshot(.login, step: 1)
    }
}
