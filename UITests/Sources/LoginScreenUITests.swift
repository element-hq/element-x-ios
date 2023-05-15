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
    
    func testOIDC() async throws {
        // Given the initial login screen.
        let app = Application.launch(.login)
        
        // When entering a username on a homeserver that only supports OIDC.
        app.textFields[A11yIdentifiers.loginScreen.emailUsername].clearAndTypeText("@test:company.com\n")
        
        // Then the screen should be configured for OIDC.
        try await app.assertScreenshot(.login, step: 1)
    }
    
    func testUnsupported() async throws {
        // Given the initial login screen.
        let app = Application.launch(.login)
        
        // When entering a username on a homeserver with an unsupported flow.
        app.textFields[A11yIdentifiers.loginScreen.emailUsername].clearAndTypeText("@test:server.net\n")
        
        // Then the screen should not allow login to continue.
        try await app.assertScreenshot(.login, step: 2)
    }
}
