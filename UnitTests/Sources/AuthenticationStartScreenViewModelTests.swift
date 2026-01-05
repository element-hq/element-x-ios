//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import ElementX
import MatrixRustSDKMocks

@MainActor
class AuthenticationStartScreenViewModelTests: XCTestCase {
    var clientFactory: AuthenticationClientFactoryMock!
    var client: ClientSDKMock!
    var appSettings: AppSettings!
    var authenticationService: AuthenticationServiceProtocol!
    
    var viewModel: AuthenticationStartScreenViewModel!
    var context: AuthenticationStartScreenViewModel.Context { viewModel.context }
    
    override func setUp() {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
        // These app settings are kept local to the tests on purpose as if they are registered in the
        // ServiceLocator, the providers override that we apply will break other tests in the suite.
    }
    
    override func tearDown() {
        AppSettings.resetAllSettings()
    }
    
    func testInitialState() async throws {
        // Given a view model that has no provisioning parameters.
        setupViewModel()
        XCTAssertEqual(authenticationService.homeserver.value.loginMode, .unknown)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount, 0)
        
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
            XCTAssertEqual(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 0)
            XCTAssertEqual(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount, 0)
            XCTAssertEqual(authenticationService.homeserver.value.loginMode, .unknown)
        }
    }
    
    func testProvisionedOIDCState() async throws {
        // Given a view model that has been provisioned with a server that supports OIDC.
        setupViewModel(provisioningParameters: .init(accountProvider: "company.com", loginHint: "user@company.com"))
        XCTAssertEqual(authenticationService.homeserver.value.loginMode, .unknown)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount, 0)
        
        // When tapping the login button the authentication service should be used and the screen
        // should request to continue the flow without any server selection needed.
        let deferred = deferFulfillment(viewModel.actions) { $0.isLoginDirectlyWithOIDC }
        context.send(viewAction: .login)
        try await deferred.fulfill()
        
        XCTAssertEqual(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount, 1)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesReceivedArguments?.prompt, .consent)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesReceivedArguments?.loginHint, "user@company.com")
        XCTAssertEqual(authenticationService.homeserver.value.loginMode, .oidc(supportsCreatePrompt: false))
    }
    
    func testProvisionedPasswordState() async throws {
        // Given a view model that has been provisioned with a server that does not support OIDC.
        setupViewModel(provisioningParameters: .init(accountProvider: "company.com", loginHint: "user@company.com"), supportsOIDC: false)
        XCTAssertEqual(authenticationService.homeserver.value.loginMode, .unknown)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount, 0)
        
        // When tapping the login button the authentication service should be used and the screen
        // should request to continue the flow without any server selection needed.
        let deferred = deferFulfillment(viewModel.actions) { $0.isLoginDirectlyWithPassword }
        context.send(viewAction: .login)
        try await deferred.fulfill()
        
        // Then a call to configure service should be made.
        XCTAssertEqual(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        XCTAssertEqual(authenticationService.homeserver.value.loginMode, .password)
    }
    
    func testSingleProviderOIDCState() async throws {
        // Given a view model that for an app that only allows the use of a single provider that supports OIDC.
        setAllowedAccountProviders(["company.com"])
        setupViewModel()
        XCTAssertEqual(authenticationService.homeserver.value.loginMode, .unknown)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount, 0)
        
        // When tapping the login button the authentication service should be used and the screen
        // should request to continue the flow without any server selection needed.
        let deferred = deferFulfillment(viewModel.actions) { $0.isLoginDirectlyWithOIDC }
        context.send(viewAction: .login)
        try await deferred.fulfill()
        
        XCTAssertEqual(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount, 1)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesReceivedArguments?.prompt, .consent)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesReceivedArguments?.loginHint, nil)
        XCTAssertEqual(authenticationService.homeserver.value.loginMode, .oidc(supportsCreatePrompt: false))
    }
    
    func testSingleProviderPasswordState() async throws {
        // Given a view model that for an app that only allows the use of a single provider that does not support OIDC.
        setAllowedAccountProviders(["company.com"])
        setupViewModel(supportsOIDC: false)
        XCTAssertEqual(authenticationService.homeserver.value.loginMode, .unknown)
        XCTAssertEqual(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount, 0)
        
        // When tapping the login button the authentication service should be used and the screen
        // should request to continue the flow without any server selection needed.
        let deferred = deferFulfillment(viewModel.actions) { $0.isLoginDirectlyWithPassword }
        context.send(viewAction: .login)
        try await deferred.fulfill()
        
        // Then a call to configure service should be made.
        XCTAssertEqual(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        XCTAssertEqual(authenticationService.homeserver.value.loginMode, .password)
    }
    
    // MARK: - Helpers
    
    private func setupViewModel(provisioningParameters: AccountProvisioningParameters? = nil, supportsOIDC: Bool = true) {
        // Manually create a configuration as the default homeserver address setting is immutable.
        client = ClientSDKMock(configuration: .init(oidcLoginURL: supportsOIDC ? "https://account.company.com/authorize" : nil,
                                                    supportsOIDCCreatePrompt: false,
                                                    supportsPasswordLogin: true))
        let configuration = AuthenticationClientFactoryMock.Configuration(homeserverClients: ["company.com": client])
        
        clientFactory = AuthenticationClientFactoryMock(configuration: configuration)
        authenticationService = AuthenticationService(userSessionStore: UserSessionStoreMock(configuration: .init()),
                                                      encryptionKeyProvider: EncryptionKeyProvider(),
                                                      clientFactory: clientFactory,
                                                      appSettings: appSettings,
                                                      appHooks: AppHooks())
        
        viewModel = AuthenticationStartScreenViewModel(authenticationService: authenticationService,
                                                       provisioningParameters: provisioningParameters,
                                                       isBugReportServiceEnabled: true,
                                                       appSettings: appSettings,
                                                       userIndicatorController: UserIndicatorControllerMock())
        
        // Add a fake window in order for the OIDC flow to continue
        viewModel.context.send(viewAction: .updateWindow(UIWindow()))
    }
    
    private func setAllowedAccountProviders(_ providers: [String]) {
        appSettings.override(accountProviders: providers,
                             allowOtherAccountProviders: false,
                             hideBrandChrome: false,
                             pushGatewayBaseURL: appSettings.pushGatewayBaseURL,
                             oidcRedirectURL: appSettings.oidcRedirectURL,
                             websiteURL: appSettings.websiteURL,
                             logoURL: appSettings.logoURL,
                             copyrightURL: appSettings.copyrightURL,
                             acceptableUseURL: appSettings.acceptableUseURL,
                             privacyURL: appSettings.privacyURL,
                             encryptionURL: appSettings.encryptionURL,
                             deviceVerificationURL: appSettings.deviceVerificationURL,
                             chatBackupDetailsURL: appSettings.chatBackupDetailsURL,
                             identityPinningViolationDetailsURL: appSettings.identityPinningViolationDetailsURL,
                             historySharingDetailsURL: appSettings.historySharingDetailsURL,
                             elementWebHosts: appSettings.elementWebHosts,
                             accountProvisioningHost: appSettings.accountProvisioningHost,
                             bugReportApplicationID: appSettings.bugReportApplicationID,
                             analyticsTermsURL: appSettings.analyticsTermsURL,
                             mapTilerConfiguration: appSettings.mapTilerConfiguration)
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
