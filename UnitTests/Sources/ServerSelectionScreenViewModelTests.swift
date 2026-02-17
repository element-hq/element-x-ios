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
    @MainActor
    private struct TestSetup {
        var clientFactory: AuthenticationClientFactoryMock
        var service: AuthenticationServiceProtocol
        var viewModel: ServerSelectionScreenViewModelProtocol
        
        var context: ServerSelectionScreenViewModelType.Context {
            viewModel.context
        }
        
        init(authenticationFlow: AuthenticationFlow) {
            clientFactory = AuthenticationClientFactoryMock(configuration: .init())
            service = AuthenticationService(userSessionStore: UserSessionStoreMock(configuration: .init()),
                                            encryptionKeyProvider: EncryptionKeyProvider(),
                                            clientFactory: clientFactory,
                                            appSettings: ServiceLocator.shared.settings,
                                            appHooks: AppHooks())
            
            viewModel = ServerSelectionScreenViewModel(authenticationService: service,
                                                       authenticationFlow: authenticationFlow,
                                                       appSettings: ServiceLocator.shared.settings,
                                                       userIndicatorController: UserIndicatorControllerMock())
        }
    }
    
    @Test
    func selectForLogin() async throws {
        // Given a view model for login.
        var testSetup = TestSetup(authenticationFlow: .login)
        #expect(testSetup.service.homeserver.value.loginMode == .unknown)
        #expect(testSetup.clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
        
        // When selecting matrix.org.
        testSetup.context.homeserverAddress = "matrix.org"
        let deferred = deferFulfillment(testSetup.viewModel.actions) { $0 == .updated }
        testSetup.context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then selection should succeed.
        #expect(testSetup.clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(testSetup.service.homeserver.value == .mockMatrixDotOrg)
    }
    
    @Test
    func loginNotSupportedAlert() async throws {
        // Given a view model for login.
        var testSetup = TestSetup(authenticationFlow: .login)
        #expect(testSetup.service.homeserver.value.loginMode == .unknown)
        #expect(testSetup.clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
        #expect(testSetup.context.alertInfo == nil)
        
        // When selecting a server that doesn't support login.
        testSetup.context.homeserverAddress = "server.net"
        let deferred = deferFulfillment(testSetup.context.observe(\.alertInfo)) { $0 != nil }
        testSetup.context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then selection should fail with an alert about not supporting registration.
        #expect(testSetup.clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(testSetup.context.alertInfo?.id == .loginAlert)
    }
    
    @Test
    func selectForRegistration() async throws {
        // Given a view model for registration.
        var testSetup = TestSetup(authenticationFlow: .register)
        #expect(testSetup.service.homeserver.value.loginMode == .unknown)
        #expect(testSetup.clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
        
        // When selecting matrix.org.
        testSetup.context.homeserverAddress = "matrix.org"
        let deferred = deferFulfillment(testSetup.viewModel.actions) { $0 == .updated }
        testSetup.context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then selection should succeed.
        #expect(testSetup.clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(testSetup.service.homeserver.value == .mockMatrixDotOrg)
    }
    
    @Test
    func registrationNotSupportedAlert() async throws {
        // Given a view model for registration.
        var testSetup = TestSetup(authenticationFlow: .register)
        #expect(testSetup.service.homeserver.value.loginMode == .unknown)
        #expect(testSetup.clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
        #expect(testSetup.context.alertInfo == nil)
        
        // When selecting a server that doesn't support registration.
        testSetup.context.homeserverAddress = "example.com"
        let deferred = deferFulfillment(testSetup.context.observe(\.alertInfo)) { $0 != nil }
        testSetup.context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then selection should fail with an alert about not supporting registration.
        #expect(testSetup.clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(testSetup.context.alertInfo?.id == .registrationAlert)
    }
    
    @Test
    func elementProRequiredAlert() async throws {
        // Given a view model for login.
        var testSetup = TestSetup(authenticationFlow: .login)
        #expect(testSetup.service.homeserver.value.loginMode == .unknown)
        #expect(testSetup.clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
        #expect(testSetup.context.alertInfo == nil)
        
        // When selecting a server that requires Element Pro
        testSetup.context.homeserverAddress = "secure.gov"
        let deferred = deferFulfillment(testSetup.context.observe(\.alertInfo)) { $0 != nil }
        testSetup.context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then selection should fail with an alert telling the user to download Element Pro.
        #expect(testSetup.clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(testSetup.context.alertInfo?.id == .elementProAlert)
    }
    
    @Test
    func invalidServer() async throws {
        // Given a new instance of the view model.
        var testSetup = TestSetup(authenticationFlow: .login)
        #expect(!testSetup.context.viewState.isShowingFooterError, "There should not be an error message for a new view model.")
        #expect(testSetup.context.viewState.footerErrorMessage == nil, "There should not be an error message for a new view model.")
        #expect(String(testSetup.context.viewState.footerMessage) == L10n.screenChangeServerFormNotice,
                "The standard footer message should be shown.")
        
        // When attempting to discover an invalid server
        var deferred = deferFulfillment(testSetup.context.observe(\.viewState.isShowingFooterError)) { $0 }
        testSetup.context.homeserverAddress = "idontexist"
        testSetup.context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the footer should now be showing an error.
        #expect(testSetup.context.viewState.isShowingFooterError, "The error message should be stored.")
        #expect(testSetup.context.viewState.footerErrorMessage != nil, "The error message should be stored.")
        #expect(String(testSetup.context.viewState.footerMessage) != L10n.screenChangeServerFormNotice,
                "The error message should be shown.")
        
        // And when clearing the error.
        deferred = deferFulfillment(testSetup.context.observe(\.viewState.isShowingFooterError)) { !$0 }
        testSetup.context.homeserverAddress = ""
        testSetup.context.send(viewAction: .clearFooterError)
        try await deferred.fulfill()
        
        // Then the error message should now be removed.
        #expect(testSetup.context.viewState.footerErrorMessage == nil, "The error message should have been cleared.")
        #expect(String(testSetup.context.viewState.footerMessage) == L10n.screenChangeServerFormNotice,
                "The standard footer message should be shown again.")
    }
}
