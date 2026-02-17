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
struct ServerSelectionScreenViewModelTests {
    var clientFactory: AuthenticationClientFactoryMock!
    var service: AuthenticationServiceProtocol!
    var viewModel: ServerSelectionScreenViewModelProtocol!
    
    var context: ServerSelectionScreenViewModelType.Context {
        viewModel.context
    }
    
    @Test
    mutating func selectForLogin() async throws {
        // Given a view model for login.
        setup(authenticationFlow: .login)
        #expect(service.homeserver.value.loginMode == .unknown)
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
        
        // When selecting matrix.org.
        context.homeserverAddress = "matrix.org"
        let deferred = deferFulfillment(viewModel.actions) { $0 == .updated }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then selection should succeed.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(service.homeserver.value == .mockMatrixDotOrg)
    }
    
    @Test
    mutating func loginNotSupportedAlert() async throws {
        // Given a view model for login.
        setup(authenticationFlow: .login)
        #expect(service.homeserver.value.loginMode == .unknown)
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
        #expect(context.alertInfo == nil)
        
        // When selecting a server that doesn't support login.
        context.homeserverAddress = "server.net"
        let deferred = deferFulfillment(context.observe(\.alertInfo)) { $0 != nil }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then selection should fail with an alert about not supporting registration.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(context.alertInfo?.id == .loginAlert)
    }
    
    @Test
    mutating func selectForRegistration() async throws {
        // Given a view model for registration.
        setup(authenticationFlow: .register)
        #expect(service.homeserver.value.loginMode == .unknown)
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
        
        // When selecting matrix.org.
        context.homeserverAddress = "matrix.org"
        let deferred = deferFulfillment(viewModel.actions) { $0 == .updated }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then selection should succeed.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(service.homeserver.value == .mockMatrixDotOrg)
    }
    
    @Test
    mutating func registrationNotSupportedAlert() async throws {
        // Given a view model for registration.
        setup(authenticationFlow: .register)
        #expect(service.homeserver.value.loginMode == .unknown)
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
        #expect(context.alertInfo == nil)
        
        // When selecting a server that doesn't support registration.
        context.homeserverAddress = "example.com"
        let deferred = deferFulfillment(context.observe(\.alertInfo)) { $0 != nil }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then selection should fail with an alert about not supporting registration.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(context.alertInfo?.id == .registrationAlert)
    }
    
    @Test
    mutating func elementProRequiredAlert() async throws {
        // Given a view model for login.
        setup(authenticationFlow: .login)
        #expect(service.homeserver.value.loginMode == .unknown)
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
        #expect(context.alertInfo == nil)
        
        // When selecting a server that requires Element Pro
        context.homeserverAddress = "secure.gov"
        let deferred = deferFulfillment(context.observe(\.alertInfo)) { $0 != nil }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then selection should fail with an alert telling the user to download Element Pro.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(context.alertInfo?.id == .elementProAlert)
    }
    
    @Test
    mutating func invalidServer() async throws {
        // Given a new instance of the view model.
        setup(authenticationFlow: .login)
        #expect(!context.viewState.isShowingFooterError, "There should not be an error message for a new view model.")
        #expect(context.viewState.footerErrorMessage == nil, "There should not be an error message for a new view model.")
        #expect(String(context.viewState.footerMessage) == L10n.screenChangeServerFormNotice,
                "The standard footer message should be shown.")
        
        // When attempting to discover an invalid server
        var deferred = deferFulfillment(context.observe(\.viewState.isShowingFooterError)) { $0 }
        context.homeserverAddress = "idontexist"
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the footer should now be showing an error.
        #expect(context.viewState.isShowingFooterError, "The error message should be stored.")
        #expect(context.viewState.footerErrorMessage != nil, "The error message should be stored.")
        #expect(String(context.viewState.footerMessage) != L10n.screenChangeServerFormNotice,
                "The error message should be shown.")
        
        // And when clearing the error.
        deferred = deferFulfillment(context.observe(\.viewState.isShowingFooterError)) { !$0 }
        context.homeserverAddress = ""
        context.send(viewAction: .clearFooterError)
        try await deferred.fulfill()
        
        // Then the error message should now be removed.
        #expect(context.viewState.footerErrorMessage == nil, "The error message should have been cleared.")
        #expect(String(context.viewState.footerMessage) == L10n.screenChangeServerFormNotice,
                "The standard footer message should be shown again.")
    }
    
    // MARK: - Helpers
    
    private mutating func setup(authenticationFlow: AuthenticationFlow) {
        clientFactory = AuthenticationClientFactoryMock(configuration: .init())
        service = AuthenticationService(userSessionStore: UserSessionStoreMock(configuration: .init()),
                                        encryptionKeyProvider: EncryptionKeyProvider(),
                                        appMigrationManager: nil,
                                        clientFactory: clientFactory,
                                        appSettings: ServiceLocator.shared.settings,
                                        appHooks: AppHooks())
        
        viewModel = ServerSelectionScreenViewModel(authenticationService: service,
                                                   authenticationFlow: authenticationFlow,
                                                   appSettings: ServiceLocator.shared.settings,
                                                   userIndicatorController: UserIndicatorControllerMock())
    }
}
