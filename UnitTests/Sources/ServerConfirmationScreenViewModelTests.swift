//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class ServerConfirmationScreenViewModelTests: XCTestCase {
    var clientBuilderFactory: AuthenticationClientBuilderFactoryMock!
    var client: ClientSDKMock!
    var service: AuthenticationServiceProtocol!
    
    var viewModel: ServerConfirmationScreenViewModel!
    var context: ServerConfirmationScreenViewModel.Context { viewModel.context }
    
    func testConfirmLoginWithoutConfiguration() async throws {
        // Given a view model for login using a service that hasn't been configured.
        setupViewModel(authenticationFlow: .login)
        XCTAssertEqual(service.homeserver.value.loginMode, .unknown)
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 0)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptCallsCount, 0)
        
        // When continuing from the confirmation screen.
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithOIDC }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then a call to configure service should be made.
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptCallsCount, 1)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptReceivedArguments?.prompt, .consent)
        XCTAssertEqual(service.homeserver.value.loginMode, .oidc(supportsCreatePrompt: true))
    }
    
    func testConfirmLoginAfterConfiguration() async throws {
        // Given a view model for login using a service that has already been configured (via the server selection screen).
        setupViewModel(authenticationFlow: .login)
        guard case .success = await service.configure(for: viewModel.state.homeserverAddress, flow: .login) else {
            XCTFail("The configuration should succeed.")
            return
        }
        XCTAssertEqual(service.homeserver.value.loginMode, .oidc(supportsCreatePrompt: true))
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptCallsCount, 0)
        
        // When continuing from the confirmation screen.
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithOIDC }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the configured homeserver should be used and no additional client should be built.
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptCallsCount, 1)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptReceivedArguments?.prompt, .consent)
    }
    
    func testConfirmRegisterWithoutConfiguration() async throws {
        // Given a view model for registration using a service that hasn't been configured.
        setupViewModel(authenticationFlow: .register)
        XCTAssertEqual(service.homeserver.value.loginMode, .unknown)
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 0)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptCallsCount, 0)
        
        // When continuing from the confirmation screen.
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithOIDC }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then a call to configure service should be made.
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptCallsCount, 1)
        // The create prompt is broken: https://github.com/element-hq/matrix-authentication-service/issues/3429
        // XCTAssertEqual(client.urlForOidcOidcConfigurationPromptReceivedArguments?.prompt, .create)
        XCTAssertEqual(service.homeserver.value.loginMode, .oidc(supportsCreatePrompt: true))
    }
    
    func testConfirmRegisterAfterConfiguration() async throws {
        // Given a view model for registration using a service that has already been configured (via the server selection screen).
        setupViewModel(authenticationFlow: .register)
        guard case .success = await service.configure(for: viewModel.state.homeserverAddress, flow: .register) else {
            XCTFail("The configuration should succeed.")
            return
        }
        XCTAssertEqual(service.homeserver.value.loginMode, .oidc(supportsCreatePrompt: true))
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptCallsCount, 0)
        
        // When continuing from the confirmation screen.
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithOIDC }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the configured homeserver should be used and no additional client should be built.
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        // The create prompt is broken: https://github.com/element-hq/matrix-authentication-service/issues/3429
        // XCTAssertEqual(client.urlForOidcOidcConfigurationPromptReceivedArguments?.prompt, .create)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptCallsCount, 1)
    }
    
    func testConfirmPasswordLoginWithoutConfiguration() async throws {
        // Given a view model for login using a service that hasn't been configured (against a server that doesn't support OIDC).
        setupViewModel(authenticationFlow: .login, supportsOIDC: false)
        XCTAssertEqual(service.homeserver.value.loginMode, .unknown)
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 0)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptCallsCount, 0)
        
        // When continuing from the confirmation screen.
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithPassword }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then a call to configure service should be made, but not for the OIDC URL.
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptCallsCount, 0)
        XCTAssertEqual(service.homeserver.value.loginMode, .password)
    }
    
    func testConfirmPasswordLoginAfterConfiguration() async throws {
        // Given a view model for login using a service that has already been configured (via the server selection screen).
        setupViewModel(authenticationFlow: .login, supportsOIDC: false)
        guard case .success = await service.configure(for: viewModel.state.homeserverAddress, flow: .login) else {
            XCTFail("The configuration should succeed.")
            return
        }
        XCTAssertEqual(service.homeserver.value.loginMode, .password)
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptCallsCount, 0)
        
        // When continuing from the confirmation screen.
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithPassword }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the configured homeserver should be used and no additional client should be built, nor a call to get the OIDC URL.
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptCallsCount, 0)
    }
    
    func testRegistrationNotSupportedAlert() async throws {
        // Given a view model for registration using a service that hasn't been configured and the default server doesn't support registration.
        // Note: We don't currently take the create prompt into account when determining registration support.
        setupViewModel(authenticationFlow: .register, supportsOIDC: false, supportsOIDCCreatePrompt: false)
        XCTAssertEqual(service.homeserver.value.loginMode, .unknown)
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 0)
        XCTAssertNil(context.alertInfo)
        
        // When continuing from the confirmation screen.
        let deferred = deferFulfillment(context.$viewState) { $0.bindings.alertInfo != nil }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the configuration should fail with an alert about not supporting registration.
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        XCTAssertEqual(context.alertInfo?.id, .registration)
    }
    
    func testLoginNotSupportedAlert() async throws {
        // Given a view model for login using a service that hasn't been configured and the default server doesn't support login.
        setupViewModel(authenticationFlow: .login, supportsOIDC: false, supportsOIDCCreatePrompt: false, supportsPasswordLogin: false)
        XCTAssertEqual(service.homeserver.value.loginMode, .unknown)
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 0)
        XCTAssertNil(context.alertInfo)
        
        // When continuing from the confirmation screen.
        let deferred = deferFulfillment(context.$viewState) { $0.bindings.alertInfo != nil }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the configuration should fail with an alert about not supporting login.
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        XCTAssertEqual(context.alertInfo?.id, .login)
    }
    
    // MARK: - Helpers
    
    private func setupViewModel(authenticationFlow: AuthenticationFlow, supportsOIDC: Bool = true, supportsOIDCCreatePrompt: Bool = true, supportsPasswordLogin: Bool = true) {
        // Manually create a configuration as the default homeserver address setting is immutable.
        client = ClientSDKMock(configuration: .init(oidcLoginURL: supportsOIDC ? "https://account.matrix.org/authorize" : nil,
                                                    supportsOIDCCreatePrompt: supportsOIDCCreatePrompt,
                                                    supportsPasswordLogin: supportsPasswordLogin))
        let configuration = AuthenticationClientBuilderMock.Configuration(homeserverClients: ["matrix.org": client],
                                                                          qrCodeClient: client)
        
        clientBuilderFactory = AuthenticationClientBuilderFactoryMock(configuration: .init(builderConfiguration: configuration))
        service = AuthenticationService(userSessionStore: UserSessionStoreMock(configuration: .init()),
                                        encryptionKeyProvider: EncryptionKeyProvider(),
                                        clientBuilderFactory: clientBuilderFactory,
                                        appSettings: ServiceLocator.shared.settings,
                                        appHooks: AppHooks())
        
        viewModel = ServerConfirmationScreenViewModel(authenticationService: service,
                                                      authenticationFlow: authenticationFlow,
                                                      userIndicatorController: UserIndicatorControllerMock())
        
        // Add a fake window in order for the OIDC flow to continue
        viewModel.context.send(viewAction: .updateWindow(UIWindow()))
    }
}

private extension ServerConfirmationScreenViewModelAction {
    var isContinueWithOIDC: Bool {
        switch self {
        case .continueWithOIDC: true
        default: false
        }
    }
    
    var isContinueWithPassword: Bool {
        switch self {
        case .continueWithPassword: true
        default: false
        }
    }
}
