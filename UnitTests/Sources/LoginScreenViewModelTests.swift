//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class LoginScreenViewModelTests: XCTestCase {
    var viewModel: LoginScreenViewModelProtocol!
    var context: LoginScreenViewModelType.Context { viewModel.context }
    
    var clientBuilderFactory: AuthenticationClientBuilderFactoryMock!
    var service: AuthenticationServiceProtocol!
    
    private func setupViewModel(homeserverAddress: String = "matrix.org") async {
        clientBuilderFactory = AuthenticationClientBuilderFactoryMock(configuration: .init())
        service = AuthenticationService(userSessionStore: UserSessionStoreMock(configuration: .init()),
                                        encryptionKeyProvider: EncryptionKeyProvider(),
                                        clientBuilderFactory: clientBuilderFactory,
                                        appSettings: ServiceLocator.shared.settings,
                                        appHooks: AppHooks())
        
        guard case .success = await service.configure(for: homeserverAddress, flow: .login) else {
            XCTFail("A valid server should be configured for the test.")
            return
        }
        
        viewModel = LoginScreenViewModel(authenticationService: service,
                                         slidingSyncLearnMoreURL: ServiceLocator.shared.settings.slidingSyncLearnMoreURL,
                                         userIndicatorController: UserIndicatorControllerMock(),
                                         analytics: ServiceLocator.shared.analytics)
    }
    
    func testMatrixDotOrg() async {
        // Given the initial view model configured for matrix.org.
        await setupViewModel()
        
        // Then the view state should contain a homeserver that matches matrix.org and show the login form.
        XCTAssertEqual(context.viewState.homeserver, .mockMatrixDotOrg, "The homeserver data should match the default homeserver.")
        XCTAssertEqual(context.viewState.loginMode, .password, "The login form should be shown.")
    }
    
    func testBasicServer() async {
        // Given the view model configured for a basic server example.com that only supports password authentication.
        await setupViewModel(homeserverAddress: "example.com")
        
        // Then the view state should be updated with the homeserver and show the login form.
        XCTAssertEqual(context.viewState.homeserver, .mockBasicServer, "The homeserver data should should match the new homeserver.")
        XCTAssertEqual(context.viewState.loginMode, .password, "The login form should be shown.")
    }
    
    func testUsernameWithEmptyPassword() async {
        // Given a form with an empty username and password.
        await setupViewModel()
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
    
    func testEmptyUsernameWithPassword() async {
        // Given a form with an empty username and password.
        await setupViewModel()
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
    
    func testValidCredentials() async {
        // Given a form with an empty username and password.
        await setupViewModel()
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
    
    func testLoadingServerWithoutPassword() async throws {
        // Given a form with valid credentials.
        await setupViewModel()
        context.username = "@bob:example.com"
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be not be valid without a password.")
        XCTAssertFalse(context.viewState.isLoading, "The view shouldn't start in a loading state.")
        XCTAssertFalse(context.viewState.canSubmit, "The form should not be submittable.")
        
        // When updating the view model whilst loading a homeserver.
        let deferred = deferFulfillment(context.$viewState, keyPath: \.isLoading, transitionValues: [true, false])
        context.send(viewAction: .parseUsername)
        
        // Then the view state should represent the loading but never allow submitting to occur.
        try await deferred.fulfill()
        XCTAssertFalse(context.viewState.isLoading, "The view should be back in a loaded state.")
        XCTAssertFalse(context.viewState.canSubmit, "The form should still not be submittable.")
    }
    
    func testLoadingServerWithPasswordEntered() async throws {
        // Given a form with valid credentials.
        await setupViewModel()
        context.username = "@bob:example.com"
        context.password = "12345678"
        XCTAssertTrue(context.viewState.hasValidCredentials, "The credentials should be valid.")
        XCTAssertFalse(context.viewState.isLoading, "The view shouldn't start in a loading state.")
        XCTAssertTrue(context.viewState.canSubmit, "The form should be ready to submit.")
        
        // When updating the view model whilst loading a homeserver.
        let deferred = deferFulfillment(context.$viewState, keyPath: \.canSubmit, transitionValues: [false, true])
        context.send(viewAction: .parseUsername)
        
        // Then the view should be blocked from submitting while loading and then become unblocked again.
        try await deferred.fulfill()
        XCTAssertFalse(context.viewState.isLoading, "The view should be back in a loaded state.")
        XCTAssertTrue(context.viewState.canSubmit, "The form should be ready to submit.")
    }

    func testOIDCServer() async throws {
        // Given the screen configured for matrix.org
        await setupViewModel()
        
        // When entering a username for a user on a homeserver with OIDC.
        let deferred = deferFulfillment(viewModel.actions) { $0.isConfiguredForOIDC }
        context.username = "@bob:company.com"
        context.send(viewAction: .parseUsername)
        try await deferred.fulfill()

        // Then the view state should be updated with the homeserver and show the OIDC button.
        XCTAssertTrue(context.viewState.loginMode.supportsOIDCFlow, "The OIDC button should be shown.")
    }
    
    func testUnsupportedServer() async throws {
        // Given the screen configured for matrix.org
        await setupViewModel()
        XCTAssertNil(context.alertInfo, "There shouldn't be an alert when the screen loads.")
        
        // When entering a username for an unsupported homeserver.
        let deferred = deferFulfillment(context.$viewState) { $0.bindings.alertInfo != nil }
        context.username = "@bob:server.net"
        context.send(viewAction: .parseUsername)
        try await deferred.fulfill()

        // Then the view state should be updated to show an alert.
        XCTAssertEqual(context.alertInfo?.id, .unknown, "An alert should be shown to the user.")
    }
}
