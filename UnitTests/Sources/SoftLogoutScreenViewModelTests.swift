//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

@MainActor
class SoftLogoutScreenViewModelTests: XCTestCase {
    let credentials = SoftLogoutScreenCredentials(userID: "mock_user_id",
                                                  homeserverName: "https://example.com",
                                                  userDisplayName: "mock_username",
                                                  deviceID: "ABCDEFGH")
    
    func testInitialStateForBasicServer() {
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
    
    func testInitialStateForBasicServerPasswordEntered() {
        let viewModel = SoftLogoutScreenViewModel(credentials: credentials,
                                                  homeserver: .mockBasicServer,
                                                  keyBackupNeeded: true,
                                                  password: "12345678")
        let context = viewModel.context

        // Given a view model where the user hasn't yet sent the verification email.
        XCTAssertTrue(context.viewState.canSubmit, "The view model should start with a valid password.")
        XCTAssertEqual(context.viewState.loginMode, .password, "The view model should show login form for the given homeserver.")
        XCTAssert(context.viewState.showRecoverEncryptionKeysMessage, "The view model should show recover encryption keys message.")
    }

    func testInitialStateForOIDC() {
        let viewModel = SoftLogoutScreenViewModel(credentials: credentials,
                                                  homeserver: .mockMatrixDotOrg,
                                                  keyBackupNeeded: false)
        let context = viewModel.context
        
        // Given a view model where the user hasn't yet sent the verification email.
        XCTAssert(context.password.isEmpty, "The view model should start with an empty password.")
        XCTAssertFalse(context.viewState.canSubmit, "The view model should start with an invalid password.")
        XCTAssertTrue(context.viewState.loginMode.supportsOIDCFlow, "The view model should show OIDC button for the given homeserver.")
        XCTAssertFalse(context.viewState.showRecoverEncryptionKeysMessage, "The view model should not show recover encryption keys message.")
    }
    
    func testInitialStateForUnsupported() {
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
