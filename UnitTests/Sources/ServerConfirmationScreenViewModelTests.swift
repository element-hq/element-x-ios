//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import MatrixRustSDKMocks
import Testing

@MainActor
@Suite final class ServerConfirmationScreenViewModelTests {
    var clientFactory: AuthenticationClientFactoryMock!
    var client: ClientSDKMock!
    var service: AuthenticationServiceProtocol!
    var appSettings: AppSettings!
    
    var viewModel: ServerConfirmationScreenViewModel!
    var context: ServerConfirmationScreenViewModel.Context {
        viewModel.context
    }
    
    init() {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
        // These app settings are kept local to the tests on purpose as if they are registered in the
        // ServiceLocator, the providers override that we apply will break other tests in the suite.
    }
    
    deinit {
        AppSettings.resetAllSettings()
    }
    
    // MARK: - Confirmation mode
    
    @Test
    func confirmLoginWithoutConfiguration() async throws {
        // Given a view model for login using a service that hasn't been configured.
        setupViewModel(authenticationFlow: .login)
        #expect(service.homeserver.value.loginMode == .unknown)
        #expect(context.viewState.mode == .confirmation(service.homeserver.value.address))
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
        #expect(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        
        // When continuing from the confirmation screen.
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithOIDC }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then a call to configure service should be made.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 1)
        #expect(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesReceivedArguments?.prompt == .consent)
        #expect(service.homeserver.value.loginMode == .oidc(supportsCreatePrompt: true))
    }
    
    @Test
    func confirmLoginAfterConfiguration() async throws {
        // Given a view model for login using a service that has already been configured (via the server selection screen).
        setupViewModel(authenticationFlow: .login)
        guard case .success = await service.configure(for: viewModel.state.homeserverAddress, flow: .login) else {
            Issue.record("The configuration should succeed.")
            return
        }
        #expect(service.homeserver.value.loginMode == .oidc(supportsCreatePrompt: true))
        #expect(context.viewState.mode == .confirmation(service.homeserver.value.address))
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        
        // When continuing from the confirmation screen.
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithOIDC }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the configured homeserver should be used and no additional client should be built.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 1)
        #expect(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesReceivedArguments?.prompt == .consent)
    }
    
    @Test
    func confirmRegisterWithoutConfiguration() async throws {
        // Given a view model for registration using a service that hasn't been configured.
        setupViewModel(authenticationFlow: .register)
        #expect(service.homeserver.value.loginMode == .unknown)
        #expect(context.viewState.mode == .confirmation(service.homeserver.value.address))
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
        #expect(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        
        // When continuing from the confirmation screen.
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithOIDC }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then a call to configure service should be made.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 1)
        // The create prompt is broken: https://github.com/element-hq/matrix-authentication-service/issues/3429
        // #expect(client.urlForOidcOidcConfigurationPromptReceivedArguments?.prompt == .create)
        #expect(service.homeserver.value.loginMode == .oidc(supportsCreatePrompt: true))
    }
    
    @Test
    func confirmRegisterAfterConfiguration() async throws {
        // Given a view model for registration using a service that has already been configured (via the server selection screen).
        setupViewModel(authenticationFlow: .register)
        guard case .success = await service.configure(for: viewModel.state.homeserverAddress, flow: .register) else {
            Issue.record("The configuration should succeed.")
            return
        }
        #expect(service.homeserver.value.loginMode == .oidc(supportsCreatePrompt: true))
        #expect(context.viewState.mode == .confirmation(service.homeserver.value.address))
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        
        // When continuing from the confirmation screen.
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithOIDC }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the configured homeserver should be used and no additional client should be built.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        // The create prompt is broken: https://github.com/element-hq/matrix-authentication-service/issues/3429
        // #expect(client.urlForOidcOidcConfigurationPromptReceivedArguments?.prompt == .create)
        #expect(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 1)
    }
    
    @Test
    func confirmPasswordLoginWithoutConfiguration() async throws {
        // Given a view model for login using a service that hasn't been configured (against a server that doesn't support OIDC).
        setupViewModel(authenticationFlow: .login, supportsOIDC: false)
        #expect(service.homeserver.value.loginMode == .unknown)
        #expect(context.viewState.mode == .confirmation(service.homeserver.value.address))
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
        #expect(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        
        // When continuing from the confirmation screen.
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithPassword }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then a call to configure service should be made, but not for the OIDC URL.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        #expect(service.homeserver.value.loginMode == .password)
    }
    
    @Test
    func confirmPasswordLoginAfterConfiguration() async throws {
        // Given a view model for login using a service that has already been configured (via the server selection screen).
        setupViewModel(authenticationFlow: .login, supportsOIDC: false)
        guard case .success = await service.configure(for: viewModel.state.homeserverAddress, flow: .login) else {
            Issue.record("The configuration should succeed.")
            return
        }
        #expect(service.homeserver.value.loginMode == .password)
        #expect(context.viewState.mode == .confirmation(service.homeserver.value.address))
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        
        // When continuing from the confirmation screen.
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithPassword }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the configured homeserver should be used and no additional client should be built, nor a call to get the OIDC URL.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
    }
    
    @Test
    func registrationNotSupportedAlert() async throws {
        // Given a view model for registration using a service that hasn't been configured and the default server doesn't support registration.
        // Note: We don't currently take the create prompt into account when determining registration support.
        setupViewModel(authenticationFlow: .register, supportsOIDC: false, supportsOIDCCreatePrompt: false)
        #expect(service.homeserver.value.loginMode == .unknown)
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
        #expect(context.alertInfo == nil)
        
        // When continuing from the confirmation screen.
        let deferred = deferFulfillment(context.observe(\.alertInfo)) { $0 != nil }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the configuration should fail with an alert about not supporting registration.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(context.alertInfo?.id == .registration)
    }
    
    @Test
    func loginNotSupportedAlert() async throws {
        // Given a view model for login using a service that hasn't been configured and the default server doesn't support login.
        setupViewModel(authenticationFlow: .login, supportsOIDC: false, supportsOIDCCreatePrompt: false, supportsPasswordLogin: false)
        #expect(service.homeserver.value.loginMode == .unknown)
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
        #expect(context.alertInfo == nil)
        
        // When continuing from the confirmation screen.
        let deferred = deferFulfillment(context.observe(\.alertInfo)) { $0 != nil }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the configuration should fail with an alert about not supporting login.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(context.alertInfo?.id == .login)
    }
    
    @Test
    func elementProRequired() async throws {
        // Given a view model for login using a service that hasn't been configured and the default server requires Element Pro.
        setupViewModel(authenticationFlow: .login, supportsOIDC: false, supportsOIDCCreatePrompt: false, supportsPasswordLogin: false, requiresElementPro: true)
        #expect(service.homeserver.value.loginMode == .unknown)
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
        #expect(context.alertInfo == nil)
        
        // When continuing from the confirmation screen.
        let deferred = deferFulfillment(context.observe(\.alertInfo)) { $0 != nil }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the configuration should fail with an alert telling the user to download Element Pro.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(context.alertInfo?.id == .elementProRequired(serverName: "matrix.org"))
    }
    
    // MARK: - Picker mode
    
    @Test
    func pickerWithoutConfiguration() async throws {
        // Given a view model for login using a service that hasn't been configured.
        setupViewModel(authenticationFlow: .login, restrictedFlow: true)
        #expect(service.homeserver.value.loginMode == .unknown)
        #expect(context.viewState.mode == .picker(appSettings.accountProviders))
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
        #expect(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        
        // When continuing from the confirmation screen.
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithOIDC }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then a call to configure service should be made.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 1)
        #expect(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesReceivedArguments?.prompt == .consent)
        #expect(service.homeserver.value.loginMode == .oidc(supportsCreatePrompt: true))
    }
    
    @Test
    func pickerAfterConfiguration() async throws {
        // Given a view model for login using a service that has already been configured (via the server selection screen).
        setupViewModel(authenticationFlow: .login, restrictedFlow: true)
        guard case .success = await service.configure(for: appSettings.accountProviders[0], flow: .login) else {
            Issue.record("The configuration should succeed.")
            return
        }
        #expect(service.homeserver.value.loginMode == .oidc(supportsCreatePrompt: true))
        #expect(context.viewState.mode == .picker(appSettings.accountProviders))
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        
        // When continuing from the confirmation screen.
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithOIDC }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the configured homeserver should be used and no additional client should be built.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 1)
        #expect(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesReceivedArguments?.prompt == .consent)
    }
    
    @Test
    func pickerForPasswordLoginWithoutConfiguration() async throws {
        // Given a view model for login using a service that hasn't been configured (against a server that doesn't support OIDC).
        setupViewModel(authenticationFlow: .login, supportsOIDC: false, restrictedFlow: true)
        #expect(service.homeserver.value.loginMode == .unknown)
        #expect(context.viewState.mode == .picker(appSettings.accountProviders))
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
        #expect(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        
        // When continuing from the confirmation screen.
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithPassword }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then a call to configure service should be made, but not for the OIDC URL.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        #expect(service.homeserver.value.loginMode == .password)
    }
    
    @Test
    func pickerForPasswordLoginAfterConfiguration() async throws {
        // Given a view model for login using a service that has already been configured (via the server selection screen).
        setupViewModel(authenticationFlow: .login, supportsOIDC: false, restrictedFlow: true)
        guard case .success = await service.configure(for: appSettings.accountProviders[0], flow: .login) else {
            Issue.record("The configuration should succeed.")
            return
        }
        #expect(service.homeserver.value.loginMode == .password)
        #expect(context.viewState.mode == .picker(appSettings.accountProviders))
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        
        // When continuing from the confirmation screen.
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithPassword }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the configured homeserver should be used and no additional client should be built, nor a call to get the OIDC URL.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOidcOidcConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
    }
    
    // MARK: - Helpers
    
    private func setupViewModel(authenticationFlow: AuthenticationFlow,
                                supportsOIDC: Bool = true,
                                supportsOIDCCreatePrompt: Bool = true,
                                supportsPasswordLogin: Bool = true,
                                restrictedFlow: Bool = false,
                                requiresElementPro: Bool = false) {
        var mode = ServerConfirmationScreenMode.confirmation("matrix.org")
        if restrictedFlow {
            appSettings.override(accountProviders: ["matrix.org", "beta.matrix.org"],
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
            mode = .picker(appSettings.accountProviders)
        }
        
        // Manually create a configuration as the default homeserver address setting is immutable.
        client = ClientSDKMock(configuration: .init(oidcLoginURL: supportsOIDC ? "https://account.matrix.org/authorize" : nil,
                                                    supportsOIDCCreatePrompt: supportsOIDCCreatePrompt,
                                                    supportsPasswordLogin: supportsPasswordLogin,
                                                    elementWellKnown: requiresElementPro ? "{\"version\":1,\"enforce_element_pro\":true}" : nil))
        let configuration = AuthenticationClientFactoryMock.Configuration(homeserverClients: ["matrix.org": client])
        
        clientFactory = AuthenticationClientFactoryMock(configuration: configuration)
        service = AuthenticationService(userSessionStore: UserSessionStoreMock(configuration: .init()),
                                        encryptionKeyProvider: EncryptionKeyProvider(),
                                        clientFactory: clientFactory,
                                        appSettings: appSettings,
                                        appHooks: AppHooks())
        
        viewModel = ServerConfirmationScreenViewModel(authenticationService: service,
                                                      mode: mode,
                                                      authenticationFlow: authenticationFlow,
                                                      appSettings: ServiceLocator.shared.settings,
                                                      userIndicatorController: UserIndicatorControllerMock())
        
        // Add a fake window in order for the OIDC flow to continue
        viewModel.context.send(viewAction: .updateWindow(UIWindow()))
    }
}

private extension ServerConfirmationScreenViewState {
    var homeserverAddress: String {
        switch mode {
        case .confirmation(let accountProvider):
            accountProvider
        case .picker:
            fatalError()
        }
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
