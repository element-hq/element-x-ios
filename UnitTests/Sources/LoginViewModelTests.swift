//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class LoginViewModelTests: XCTestCase {
    let defaultHomeserver = LoginHomeserver.mockMatrixDotOrg
    var viewModel: LoginScreenViewModelProtocol!
    var context: LoginScreenViewModelType.Context!
    
    @MainActor override func setUp() async throws {
        viewModel = LoginScreenViewModel(homeserver: defaultHomeserver, slidingSyncLearnMoreURL: ServiceLocator.shared.settings.slidingSyncLearnMoreURL)
        context = viewModel.context
    }
    
    func testMatrixDotOrg() {
        // Given the initial view model configured for matrix.org.
        let homeserver = defaultHomeserver
        
        // Then the view state should contain a homeserver that matches matrix.org and show the login form.
        XCTAssertEqual(context.viewState.homeserver, homeserver, "The homeserver data should match the original.")
        XCTAssertEqual(context.viewState.loginMode, .password, "The login form should be shown.")
    }
    
    func testBasicServer() {
        // Given a basic server example.com that only supports password registration.
        let homeserver = LoginHomeserver.mockBasicServer
        
        // When updating the view model with the server.
        viewModel.update(homeserver: homeserver)
        
        // Then the view state should be updated with the homeserver and show the login form.
        XCTAssertEqual(context.viewState.homeserver, homeserver, "The homeserver data should should match the new homeserver.")
        XCTAssertEqual(context.viewState.loginMode, .password, "The login form should be shown.")
    }
    
    func testUsernameWithEmptyPassword() {
        // Given a form with an empty username and password.
        XCTAssertTrue(context.password.isEmpty, "The initial value for the password should be empty.")
        XCTAssertTrue(context.username.isEmpty, "The initial value for the username should be empty.")
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
        XCTAssertFalse(context.viewState.canSubmit, "The form should be blocked for submission.")
        
        // When entering a username without a password.
        context.username = "bob"
        context.password = ""
        
        // Then the credentials should be considered invalid.
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
        XCTAssertFalse(context.viewState.canSubmit, "The form should be blocked for submission.")
    }
    
    func testEmptyUsernameWithPassword() {
        // Given a form with an empty username and password.
        XCTAssertTrue(context.password.isEmpty, "The initial value for the password should be empty.")
        XCTAssertTrue(context.username.isEmpty, "The initial value for the username should be empty.")
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
        XCTAssertFalse(context.viewState.canSubmit, "The form should be blocked for submission.")
        
        // When entering a password without a username.
        context.username = ""
        context.password = "12345678"
        
        // Then the credentials should be considered invalid.
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
        XCTAssertFalse(context.viewState.canSubmit, "The form should be blocked for submission.")
    }
    
    func testValidCredentials() {
        // Given a form with an empty username and password.
        XCTAssertTrue(context.password.isEmpty, "The initial value for the password should be empty.")
        XCTAssertTrue(context.username.isEmpty, "The initial value for the username should be empty.")
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
        XCTAssertFalse(context.viewState.canSubmit, "The form should be blocked for submission.")
        
        // When entering a username and an 8-character password.
        context.username = "bob"
        context.password = "12345678"
        
        // Then the credentials should be considered valid.
        XCTAssertTrue(context.viewState.hasValidCredentials, "The credentials should be valid when the username and password are valid.")
        XCTAssertTrue(context.viewState.canSubmit, "The form should be ready to submit.")
    }
    
    func testLoadingServer() {
        // Given a form with valid credentials.
        context.username = "bob"
        context.password = "12345678"
        XCTAssertTrue(context.viewState.hasValidCredentials, "The credentials should be valid.")
        XCTAssertFalse(context.viewState.isLoading, "The view shouldn't start in a loading state.")
        XCTAssertTrue(context.viewState.canSubmit, "The form should be ready to submit.")
        
        // When updating the view model whilst loading a homeserver.
        viewModel.update(isLoading: true)
        
        // Then the view state should reflect that the homeserver is loading.
        XCTAssertTrue(context.viewState.isLoading, "The view should now be in a loading state.")
        XCTAssertFalse(context.viewState.canSubmit, "The form should be blocked for submission.")
        
        // When updating the view model after loading a homeserver.
        viewModel.update(isLoading: false)
        
        // Then the view state should reflect that the homeserver is now loaded.
        XCTAssertFalse(context.viewState.isLoading, "The view should be back in a loaded state.")
        XCTAssertTrue(context.viewState.canSubmit, "The form should be ready to submit.")
    }

    func testOIDCServer() {
        // Given a basic server example.com that supports OIDC registration.
        let homeserver = LoginHomeserver.mockOIDC

        // When updating the view model with the server.
        viewModel.update(homeserver: homeserver)

        // Then the view state should be updated with the homeserver and show the OIDC button.
        XCTAssertTrue(context.viewState.loginMode.supportsOIDCFlow, "The OIDC button should be shown.")
    }
    
    func testLogsForPassword() {
        // Given the coordinator and view model results that contain passwords.
        let password = "supersecretpassword"
        let viewModelAction: LoginScreenViewModelAction = .login(username: "Alice", password: password)
        
        // When creating a string representation of those results (e.g. for logging).
        let viewModelActionString = "\(viewModelAction)"
        
        // Then the password should not be included in that string.
        XCTAssertFalse("\(viewModelActionString)".contains(password), "The password must not be included in any strings.")
    }
}
