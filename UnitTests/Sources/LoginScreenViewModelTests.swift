//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
@Suite
struct LoginScreenViewModelTests {
    var viewModel: LoginScreenViewModelProtocol!
    var context: LoginScreenViewModelType.Context {
        viewModel.context
    }
    
    var clientFactory: AuthenticationClientFactoryMock!
    var service: AuthenticationServiceProtocol!
    
    @Test
    mutating func basicServer() async {
        // Given the view model configured for a basic server example.com that only supports password authentication.
        await setupViewModel()
        
        // Then the view state should be updated with the homeserver and show the login form.
        #expect(context.viewState.homeserver == .mockBasicServer,
                "The homeserver data should should match the new homeserver.")
        #expect(context.viewState.loginMode == .password,
                "The login form should be shown.")
    }
    
    @Test
    mutating func usernameWithEmptyPassword() async {
        // Given a form with an empty username and password.
        await setupViewModel()
        #expect(context.password.isEmpty,
                "The initial value for the password should be empty.")
        #expect(context.username.isEmpty,
                "The initial value for the username should be empty.")
        #expect(!context.viewState.hasValidCredentials,
                "The credentials should be invalid.")
        #expect(!context.viewState.canSubmit,
                "The form should be blocked for submission.")
        
        // When entering a username without a password.
        context.username = "bob"
        context.password = ""
        
        // Then the credentials should be considered invalid.
        #expect(!context.viewState.hasValidCredentials,
                "The credentials should be invalid.")
        #expect(!context.viewState.canSubmit,
                "The form should be blocked for submission.")
    }
    
    @Test
    mutating func emptyUsernameWithPassword() async {
        // Given a form with an empty username and password.
        await setupViewModel()
        #expect(context.password.isEmpty,
                "The initial value for the password should be empty.")
        #expect(context.username.isEmpty,
                "The initial value for the username should be empty.")
        #expect(!context.viewState.hasValidCredentials,
                "The credentials should be invalid.")
        #expect(!context.viewState.canSubmit,
                "The form should be blocked for submission.")
        
        // When entering a password without a username.
        context.username = ""
        context.password = "12345678"
        
        // Then the credentials should be considered invalid.
        #expect(!context.viewState.hasValidCredentials,
                "The credentials should be invalid.")
        #expect(!context.viewState.canSubmit,
                "The form should be blocked for submission.")
    }
    
    @Test
    mutating func validCredentials() async {
        // Given a form with an empty username and password.
        await setupViewModel()
        #expect(context.password.isEmpty,
                "The initial value for the password should be empty.")
        #expect(context.username.isEmpty,
                "The initial value for the username should be empty.")
        #expect(!context.viewState.hasValidCredentials,
                "The credentials should be invalid.")
        #expect(!context.viewState.canSubmit,
                "The form should be blocked for submission.")
        
        // When entering a username and an 8-character password.
        context.username = "bob"
        context.password = "12345678"
        
        // Then the credentials should be considered valid.
        #expect(context.viewState.hasValidCredentials,
                "The credentials should be valid when the username and password are valid.")
        #expect(context.viewState.canSubmit,
                "The form should be ready to submit.")
    }
    
    @Test
    mutating func loadingServerWithoutPassword() async throws {
        // Given a form with valid credentials.
        await setupViewModel()
        context.username = "@bob:example.com"
        #expect(!context.viewState.hasValidCredentials,
                "The credentials should be not be valid without a password.")
        #expect(!context.viewState.isLoading,
                "The view shouldn't start in a loading state.")
        #expect(!context.viewState.canSubmit,
                "The form should not be submittable.")
        
        // When updating the view model whilst loading a homeserver.
        let deferred = deferFulfillment(context.observe(\.viewState.isLoading),
                                        transitionValues: [true, false])
        context.send(viewAction: .parseUsername)
        
        // Then the view state should represent the loading but never allow submitting to occur.
        try await deferred.fulfill()
        #expect(!context.viewState.isLoading,
                "The view should be back in a loaded state.")
        #expect(!context.viewState.canSubmit,
                "The form should still not be submittable.")
    }
    
    @Test
    mutating func loadingServerWithPasswordEntered() async throws {
        // Given a form with valid credentials.
        await setupViewModel()
        context.username = "@bob:example.com"
        context.password = "12345678"
        #expect(context.viewState.hasValidCredentials,
                "The credentials should be valid.")
        #expect(!context.viewState.isLoading,
                "The view shouldn't start in a loading state.")
        #expect(context.viewState.canSubmit,
                "The form should be ready to submit.")
        
        // When updating the view model whilst loading a homeserver.
        let deferred = deferFulfillment(context.observe(\.viewState.canSubmit),
                                        transitionValues: [false, true])
        context.send(viewAction: .parseUsername)
        
        // Then the view should be blocked from submitting while loading and then become unblocked again.
        try await deferred.fulfill()
        #expect(!context.viewState.isLoading,
                "The view should be back in a loaded state.")
        #expect(context.viewState.canSubmit,
                "The form should be ready to submit.")
    }

    @Test
    mutating func oidcServer() async throws {
        // Given the screen configured for matrix.org
        await setupViewModel()
        
        // When entering a username for a user on a homeserver with OIDC.
        let deferred = deferFulfillment(viewModel.actions) {
            $0.isConfiguredForOIDC
        }
        context.username = "@bob:company.com"
        context.send(viewAction: .parseUsername)
        try await deferred.fulfill()

        // Then the view state should be updated with the homeserver and show the OIDC button.
        #expect(context.viewState.loginMode.supportsOIDCFlow,
                "The OIDC button should be shown.")
    }
    
    @Test
    mutating func unsupportedServer() async throws {
        // Given the screen configured for matrix.org
        await setupViewModel()
        #expect(context.alertInfo == nil,
                "There shouldn't be an alert when the screen loads.")
        
        // When entering a username for an unsupported homeserver.
        let deferred = deferFulfillment(context.observe(\.viewState.bindings.alertInfo)) {
            $0 != nil
        }
        context.username = "@bob:server.net"
        context.send(viewAction: .parseUsername)
        try await deferred.fulfill()

        // Then the view state should be updated to show an alert.
        #expect(context.alertInfo?.id == .unknown,
                "An alert should be shown to the user.")
    }
    
    @Test
    mutating func elementProRequired() async throws {
        // Given the screen configured for matrix.org
        await setupViewModel()
        #expect(context.alertInfo == nil,
                "There shouldn't be an alert when the screen loads.")
        
        // When entering a username for an unsupported homeserver.
        let deferred = deferFulfillment(context.observe(\.viewState.bindings.alertInfo)) {
            $0 != nil
        }
        context.username = "@bob:secure.gov"
        context.send(viewAction: .parseUsername)
        try await deferred.fulfill()

        // Then the view state should be updated to show an alert.
        #expect(context.alertInfo?.id == .elementProAlert,
                "An alert should be shown to the user.")
    }
    
    @Test
    mutating func loginHint() async {
        await setupViewModel(loginHint: "")
        #expect(context.username == "")
        
        await setupViewModel(loginHint: "alice")
        #expect(context.username == "alice")
        
        await setupViewModel(loginHint: "mxid:@alice:example.com")
        #expect(context.username == "@alice:example.com")
    }
    
    // MARK: - Helpers
    
    private mutating func setupViewModel(homeserverAddress: String = "example.com", loginHint: String? = nil) async {
        clientFactory = AuthenticationClientFactoryMock(configuration: .init())
        service = AuthenticationService(userSessionStore: UserSessionStoreMock(configuration: .init()),
                                        encryptionKeyProvider: EncryptionKeyProvider(),
                                        appMigrationManager: nil,
                                        clientFactory: clientFactory,
                                        appSettings: ServiceLocator.shared.settings,
                                        appHooks: AppHooks())
        
        guard case .success = await service
            .configure(for: homeserverAddress, flow: .login) else {
            Issue.record("A valid server should be configured for the test.")
            return
        }
        
        viewModel = LoginScreenViewModel(authenticationService: service,
                                         loginHint: loginHint,
                                         userIndicatorController: UserIndicatorControllerMock(),
                                         appSettings: ServiceLocator.shared.settings,
                                         analytics: ServiceLocator.shared.analytics)
    }
}
