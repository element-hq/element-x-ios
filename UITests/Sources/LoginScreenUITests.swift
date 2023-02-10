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
    func testMatrixDotOrg() {
        // Given the initial login screen which defaults to matrix.org.
        let app = Application.launch(.login)
        app.assertScreenshot(.login)
        
        // When typing in a username and password.
        app.textFields["login-email_username"].clearAndTypeText("@test:matrix.org")
        app.secureTextFields["login-password"].clearAndTypeText("12345678")
        
        // Then the form should be ready to submit.
        app.assertScreenshot(.login, step: 0)
    }
    
    func testOIDC() {
        // Given the initial login screen.
        let app = Application.launch(.login)
        
        // When entering a username on a homeserver that only supports OIDC.
        app.textFields["login-email_username"].clearAndTypeText("@test:company.com\n")
        
        // Then the screen should be configured for OIDC.
        app.assertScreenshot(.login, step: 1)
    }
    
    func testUnsupported() {
        // Given the initial login screen.
        let app = Application.launch(.login)
        
        // When entering a username on a homeserver with an unsupported flow.
        app.textFields["login-email_username"].clearAndTypeText("@test:server.net\n")
        
        // Then the screen should not allow login to continue.
        app.assertScreenshot(.login, step: 2)
    }
}
