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

import XCTest

@testable import ElementX

class SoftLogoutViewModelTests: XCTestCase {
    let credentials = SoftLogoutScreenCredentials(userID: "mock_user_id",
                                                  homeserverName: "https://matrix.org",
                                                  userDisplayName: "mock_username",
                                                  deviceID: "ABCDEFGH")
    
    @MainActor func testInitialStateForMatrixOrg() {
        let viewModel = SoftLogoutScreenViewModel(credentials: credentials,
                                                  homeserver: .mockMatrixDotOrg,
                                                  keyBackupNeeded: true)
        let context = viewModel.context
        
        // Given a view model where the user hasn't yet sent the verification email.
        XCTAssert(context.password.isEmpty, "The view model should start with an empty password.")
        XCTAssertFalse(context.viewState.canSubmit, "The view model should start with an invalid password.")
        XCTAssertEqual(context.viewState.loginMode, .password, "The view model should show login form for the given homeserver.")
        XCTAssert(context.viewState.showRecoverEncryptionKeysMessage, "The view model should show recover encryption keys message.")
    }

    @MainActor func testInitialStateForMatrixOrgPasswordEntered() {
        let viewModel = SoftLogoutScreenViewModel(credentials: credentials,
                                                  homeserver: .mockMatrixDotOrg,
                                                  keyBackupNeeded: true,
                                                  password: "12345678")
        let context = viewModel.context

        // Given a view model where the user hasn't yet sent the verification email.
        XCTAssertTrue(context.viewState.canSubmit, "The view model should start with a valid password.")
        XCTAssertEqual(context.viewState.loginMode, .password, "The view model should show login form for the given homeserver.")
        XCTAssert(context.viewState.showRecoverEncryptionKeysMessage, "The view model should show recover encryption keys message.")
    }
    
    @MainActor func testInitialStateForBasicServer() {
        let viewModel = SoftLogoutScreenViewModel(credentials: credentials,
                                                  homeserver: .mockBasicServer,
                                                  keyBackupNeeded: false)
        let context = viewModel.context
        
        // Given a view model where the user hasn't yet sent the verification email.
        XCTAssert(context.password.isEmpty, "The view model should start with an empty password.")
        XCTAssertFalse(context.viewState.canSubmit, "The view model should start with an invalid password.")
        XCTAssertEqual(context.viewState.loginMode, .password, "The view model should show login form for the given homeserver.")
        XCTAssertFalse(context.viewState.showRecoverEncryptionKeysMessage, "The view model should not show recover encryption keys message.")
    }

    @MainActor func testInitialStateForOIDC() {
        let viewModel = SoftLogoutScreenViewModel(credentials: credentials,
                                                  homeserver: .mockOIDC,
                                                  keyBackupNeeded: false)
        let context = viewModel.context
        
        // Given a view model where the user hasn't yet sent the verification email.
        XCTAssert(context.password.isEmpty, "The view model should start with an empty password.")
        XCTAssertFalse(context.viewState.canSubmit, "The view model should start with an invalid password.")
        XCTAssertTrue(context.viewState.loginMode.supportsOIDCFlow, "The view model should show OIDC button for the given homeserver.")
        XCTAssertFalse(context.viewState.showRecoverEncryptionKeysMessage, "The view model should not show recover encryption keys message.")
    }
    
    @MainActor func testInitialStateForUnsupported() {
        let viewModel = SoftLogoutScreenViewModel(credentials: credentials,
                                                  homeserver: .mockUnsupported,
                                                  keyBackupNeeded: false)
        let context = viewModel.context

        // Given a view model where the user hasn't yet sent the verification email.
        XCTAssert(context.password.isEmpty, "The view model should start with an empty password.")
        XCTAssertFalse(context.viewState.canSubmit, "The view model should start with an invalid password.")
        XCTAssertEqual(context.viewState.loginMode, .unsupported, "The view model should show unsupported text for the given homeserver.")
        XCTAssertFalse(context.viewState.showRecoverEncryptionKeysMessage, "The view model should not show recover encryption keys message.")
    }
}
