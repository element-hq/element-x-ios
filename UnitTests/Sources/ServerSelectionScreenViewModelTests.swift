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
class ServerSelectionScreenViewModelTests: XCTestCase {
    var clientFactory: AuthenticationClientFactoryMock!
    var service: AuthenticationServiceProtocol!
    
    var viewModel: ServerSelectionScreenViewModelProtocol!
    var context: ServerSelectionScreenViewModelType.Context {
        viewModel.context
    }
    
    func testSelectForLogin() async throws {
        // Given a view model for login.
        setupViewModel(authenticationFlow: .login)
        XCTAssertEqual(service.homeserver.value.loginMode, .unknown)
        XCTAssertEqual(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 0)
        
        // When selecting matrix.org.
        context.homeserverAddress = "matrix.org"
        let deferred = deferFulfillment(viewModel.actions) { $0 == .updated }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then selection should succeed.
        XCTAssertEqual(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        XCTAssertEqual(service.homeserver.value, .mockMatrixDotOrg)
    }
    
    func testLoginNotSupportedAlert() async throws {
        // Given a view model for login.
        setupViewModel(authenticationFlow: .login)
        XCTAssertEqual(service.homeserver.value.loginMode, .unknown)
        XCTAssertEqual(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 0)
        XCTAssertNil(context.alertInfo)
        
        // When selecting a server that doesn't support login.
        context.homeserverAddress = "server.net"
        let deferred = deferFulfillment(context.observe(\.alertInfo)) { $0 != nil }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then selection should fail with an alert about not supporting registration.
        XCTAssertEqual(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        XCTAssertEqual(context.alertInfo?.id, .loginAlert)
    }
    
    func testSelectForRegistration() async throws {
        // Given a view model for registration.
        setupViewModel(authenticationFlow: .register)
        XCTAssertEqual(service.homeserver.value.loginMode, .unknown)
        XCTAssertEqual(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 0)
        
        // When selecting matrix.org.
        context.homeserverAddress = "matrix.org"
        let deferred = deferFulfillment(viewModel.actions) { $0 == .updated }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then selection should succeed.
        XCTAssertEqual(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        XCTAssertEqual(service.homeserver.value, .mockMatrixDotOrg)
    }
    
    func testRegistrationNotSupportedAlert() async throws {
        // Given a view model for registration.
        setupViewModel(authenticationFlow: .register)
        XCTAssertEqual(service.homeserver.value.loginMode, .unknown)
        XCTAssertEqual(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 0)
        XCTAssertNil(context.alertInfo)
        
        // When selecting a server that doesn't support registration.
        context.homeserverAddress = "example.com"
        let deferred = deferFulfillment(context.observe(\.alertInfo)) { $0 != nil }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then selection should fail with an alert about not supporting registration.
        XCTAssertEqual(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        XCTAssertEqual(context.alertInfo?.id, .registrationAlert)
    }
    
    func testElementProRequiredAlert() async throws {
        // Given a view model for login.
        setupViewModel(authenticationFlow: .login)
        XCTAssertEqual(service.homeserver.value.loginMode, .unknown)
        XCTAssertEqual(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 0)
        XCTAssertNil(context.alertInfo)
        
        // When selecting a server that requires Element Pro
        context.homeserverAddress = "secure.gov"
        let deferred = deferFulfillment(context.observe(\.alertInfo)) { $0 != nil }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then selection should fail with an alert telling the user to download Element Pro.
        XCTAssertEqual(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        XCTAssertEqual(context.alertInfo?.id, .elementProAlert)
    }
    
    func testInvalidServer() async throws {
        // Given a new instance of the view model.
        setupViewModel(authenticationFlow: .login)
        XCTAssertFalse(context.viewState.isShowingFooterError, "There should not be an error message for a new view model.")
        XCTAssertNil(context.viewState.footerErrorMessage, "There should not be an error message for a new view model.")
        XCTAssertEqual(String(context.viewState.footerMessage), L10n.screenChangeServerFormNotice,
                       "The standard footer message should be shown.")
        
        // When attempting to discover an invalid server
        var deferred = deferFulfillment(context.observe(\.viewState.isShowingFooterError)) { $0 }
        context.homeserverAddress = "idontexist"
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the footer should now be showing an error.
        XCTAssertTrue(context.viewState.isShowingFooterError, "The error message should be stored.")
        XCTAssertNotNil(context.viewState.footerErrorMessage, "The error message should be stored.")
        XCTAssertNotEqual(String(context.viewState.footerMessage), L10n.screenChangeServerFormNotice,
                          "The error message should be shown.")
        
        // And when clearing the error.
        deferred = deferFulfillment(context.observe(\.viewState.isShowingFooterError)) { !$0 }
        context.homeserverAddress = ""
        context.send(viewAction: .clearFooterError)
        try await deferred.fulfill()
        
        // Then the error message should now be removed.
        XCTAssertNil(context.viewState.footerErrorMessage, "The error message should have been cleared.")
        XCTAssertEqual(String(context.viewState.footerMessage), L10n.screenChangeServerFormNotice,
                       "The standard footer message should be shown again.")
    }
    
    // MARK: - Helpers
    
    private func setupViewModel(authenticationFlow: AuthenticationFlow) {
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
