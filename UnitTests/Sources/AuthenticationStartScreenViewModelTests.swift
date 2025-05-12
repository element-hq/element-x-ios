//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class AuthenticationStartScreenViewModelTests: XCTestCase {
    var clientBuilderFactory: AuthenticationClientBuilderFactoryMock!
    var client: ClientSDKMock!
    var authenticationService: AuthenticationServiceProtocol!
    
    var viewModel: AuthenticationStartScreenViewModel!
    var context: AuthenticationStartScreenViewModel.Context { viewModel.context }
    
    func testInitialState() async throws {
        // Given a view model that has no provisioning parameters.
        setupViewModel()
        XCTAssertEqual(authenticationService.homeserver.value.loginMode, .unknown)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptLoginHintCallsCount, 0)
        
        // When tapping any of the buttons on the screen
        let actions: [(AuthenticationStartScreenViewAction, AuthenticationStartScreenViewModelAction)] = [
            (.loginWithQR, .loginWithQR),
            (.login, .login),
            (.register, .register),
            (.reportProblem, .reportProblem)
        ]
        
        for action in actions {
            let deferred = deferFulfillment(viewModel.actions) { $0 == action.1 }
            context.send(viewAction: action.0)
            try await deferred.fulfill()
            
            // Then the authentication service should not be used yet.
            XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 0)
            XCTAssertEqual(client.urlForOidcOidcConfigurationPromptLoginHintCallsCount, 0)
            XCTAssertEqual(authenticationService.homeserver.value.loginMode, .unknown)
        }
    }
    
    func testProvisionedOIDCState() async throws {
        // Given a view model that has been provisioned with a server that supports OIDC.
        setupViewModel(provisioningParameters: .init(serverName: "company.com", loginHint: "user@company.com"))
        XCTAssertEqual(authenticationService.homeserver.value.loginMode, .unknown)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptLoginHintCallsCount, 0)
        
        // When tapping the login button the authentication service should be used and the screen
        // should request to continue the flow without any server selection needed.
        let deferred = deferFulfillment(viewModel.actions) { $0.isLoginDirectlyWithOIDC }
        context.send(viewAction: .login)
        try await deferred.fulfill()
        
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptLoginHintCallsCount, 1)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptLoginHintReceivedArguments?.prompt, .consent)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptLoginHintReceivedArguments?.loginHint, "user@company.com")
        XCTAssertEqual(authenticationService.homeserver.value.loginMode, .oidc(supportsCreatePrompt: false))
    }
    
    func testProvisionedPasswordState() async throws {
        // Given a view model that has been provisioned with a server that does not support OIDC.
        setupViewModel(provisioningParameters: .init(serverName: "company.com", loginHint: "user@company.com"), supportsOIDC: false)
        XCTAssertEqual(authenticationService.homeserver.value.loginMode, .unknown)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptLoginHintCallsCount, 0)
        
        // When tapping the login button the authentication service should be used and the screen
        // should request to continue the flow without any server selection needed.
        let deferred = deferFulfillment(viewModel.actions) { $0.isLoginDirectlyWithPassword }
        context.send(viewAction: .login)
        try await deferred.fulfill()
        
        // Then a call to configure service should be made.
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        XCTAssertEqual(authenticationService.homeserver.value.loginMode, .password)
    }
    
    // MARK: - Helpers
    
    private func setupViewModel(provisioningParameters: AccountProvisioningParameters? = nil, supportsOIDC: Bool = true) {
        // Manually create a configuration as the default homeserver address setting is immutable.
        client = ClientSDKMock(configuration: .init(oidcLoginURL: supportsOIDC ? "https://account.company.com/authorize" : nil,
                                                    supportsOIDCCreatePrompt: false,
                                                    supportsPasswordLogin: true))
        let configuration = AuthenticationClientBuilderMock.Configuration(homeserverClients: ["company.com": client],
                                                                          qrCodeClient: client)
        
        clientBuilderFactory = AuthenticationClientBuilderFactoryMock(configuration: .init(builderConfiguration: configuration))
        authenticationService = AuthenticationService(userSessionStore: UserSessionStoreMock(configuration: .init()),
                                                      encryptionKeyProvider: EncryptionKeyProvider(),
                                                      clientBuilderFactory: clientBuilderFactory,
                                                      appSettings: ServiceLocator.shared.settings,
                                                      appHooks: AppHooks())
        
        viewModel = AuthenticationStartScreenViewModel(authenticationService: authenticationService,
                                                       provisioningParameters: provisioningParameters,
                                                       isBugReportServiceEnabled: true,
                                                       appSettings: ServiceLocator.shared.settings,
                                                       userIndicatorController: UserIndicatorControllerMock())
        
        // Add a fake window in order for the OIDC flow to continue
        viewModel.context.send(viewAction: .updateWindow(UIWindow()))
    }
}

extension AuthenticationStartScreenViewModelAction {
    var isLoginDirectlyWithOIDC: Bool {
        switch self {
        case .loginDirectlyWithOIDC: true
        default: false
        }
    }
    
    var isLoginDirectlyWithPassword: Bool {
        switch self {
        case .loginDirectlyWithPassword: true
        default: false
        }
    }
}
