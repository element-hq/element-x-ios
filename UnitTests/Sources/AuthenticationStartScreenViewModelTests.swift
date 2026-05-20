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
import UIKit

@MainActor
final class AuthenticationStartScreenViewModelTests {
    var clientFactory: AuthenticationClientFactoryMock!
    var client: ClientSDKMock!
    var classicAppManager: ClassicAppManagerMock?
    var notificationCenter: NotificationCenter!
    var appSettings: AppSettings!
    var authenticationService: AuthenticationServiceProtocol!
    
    var viewModel: AuthenticationStartScreenViewModel!
    var context: AuthenticationStartScreenViewModel.Context {
        viewModel.context
    }
    
    init() {
        appSettings = AppSettings(store: VolatileUserDefaults())
    }
    
    @Test
    func initialState() async throws {
        // Given a view model that has no provisioning parameters.
        await setupViewModel()
        #expect(authenticationService.homeserver.value.loginMode == .unknown)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        
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
            #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
            #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
            #expect(authenticationService.homeserver.value.loginMode == .unknown)
        }
    }
    
    @Test
    func provisionedOAuthState() async throws {
        // Given a view model that has been provisioned with a server that supports OAuth.
        await setupViewModel(provisioningParameters: .init(accountProvider: "company.com", loginHint: "user@company.com"))
        #expect(authenticationService.homeserver.value.loginMode == .unknown)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        
        // When tapping the login button the authentication service should be used and the screen
        // should request to continue the flow without any server selection needed.
        let deferred = deferFulfillment(viewModel.actions) { $0.isLoginDirectlyWithOAuth }
        context.send(viewAction: .login)
        try await deferred.fulfill()
        
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 1)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesReceivedArguments?.prompt == .consent)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesReceivedArguments?.loginHint == "user@company.com")
        #expect(authenticationService.homeserver.value.loginMode == .oAuth(supportsCreatePrompt: false))
    }
    
    @Test
    func provisionedPasswordState() async throws {
        // Given a view model that has been provisioned with a server that does not support OAuth.
        await setupViewModel(provisioningParameters: .init(accountProvider: "company.com", loginHint: "user@company.com"), supportsOAuth: false)
        #expect(authenticationService.homeserver.value.loginMode == .unknown)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        
        // When tapping the login button the authentication service should be used and the screen
        // should request to continue the flow without any server selection needed.
        let deferred = deferFulfillment(viewModel.actions) { $0.isLoginDirectlyWithPassword }
        context.send(viewAction: .login)
        try await deferred.fulfill()
        
        // Then a call to configure service should be made.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(authenticationService.homeserver.value.loginMode == .password)
    }
    
    @Test
    func singleProviderOAuthState() async throws {
        // Given a view model that for an app that only allows the use of a single provider that supports OAuth.
        setAllowedAccountProviders(["company.com"])
        await setupViewModel()
        #expect(authenticationService.homeserver.value.loginMode == .unknown)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        
        // When tapping the login button the authentication service should be used and the screen
        // should request to continue the flow without any server selection needed.
        let deferred = deferFulfillment(viewModel.actions) { $0.isLoginDirectlyWithOAuth }
        context.send(viewAction: .login)
        try await deferred.fulfill()
        
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 1)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesReceivedArguments?.prompt == .consent)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesReceivedArguments?.loginHint == nil)
        #expect(authenticationService.homeserver.value.loginMode == .oAuth(supportsCreatePrompt: false))
    }
    
    @Test
    func singleProviderPasswordState() async throws {
        // Given a view model that for an app that only allows the use of a single provider that does not support OAuth.
        setAllowedAccountProviders(["company.com"])
        await setupViewModel(supportsOAuth: false)
        #expect(authenticationService.homeserver.value.loginMode == .unknown)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        
        // When tapping the login button the authentication service should be used and the screen
        // should request to continue the flow without any server selection needed.
        let deferred = deferFulfillment(viewModel.actions) { $0.isLoginDirectlyWithPassword }
        context.send(viewAction: .login)
        try await deferred.fulfill()
        
        // Then a call to configure service should be made.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(authenticationService.homeserver.value.loginMode == .password)
    }
    
    // MARK: - Classic App Account
    
    @Test
    func classicAppAccount() async throws {
        // Given a view model with a Classic app account whose server name resolves successfully.
        let classicAppAccount = makeClassicAppAccount()
        await setupViewModel(classicAppAccount: classicAppAccount)
        guard case .welcomeBack(let account) = context.viewState.classicAppMode else {
            Issue.record("Expected classicAppMode to be .welcomeBack")
            return
        }
        #expect(account == classicAppAccount)
        
        // When continuing with the Classic app account the authentication service should be used and the screen
        // should request to continue the flow without any server selection needed.
        let deferred = deferFulfillment(viewModel.actions) { $0.isLoginDirectlyWithOAuth }
        context.send(viewAction: .continueWithClassic(classicAppAccount))
        try await deferred.fulfill()
        
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksReceivedArguments?.homeserverAddress == "company.com")
        #expect(authenticationService.homeserver.value.loginMode == .oAuth(supportsCreatePrompt: false))
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesReceivedArguments?.loginHint == "mxid:\(classicAppAccount.userID)")
    }
    
    @Test
    func classicAppAccountWithoutWellKnown() async throws {
        // Given a view model where the Classic app account's server name has no well-known file.
        let classicAppAccount = makeClassicAppAccount(serverName: "unknown-server.org",
                                                      homeserverURL: "https://matrix.company.com")
        await setupViewModel(classicAppAccount: classicAppAccount)
        guard case .welcomeBack(let account) = context.viewState.classicAppMode else {
            Issue.record("Expected classicAppMode to be .welcomeBack")
            return
        }
        #expect(account == classicAppAccount)
        
        // When continuing with the Classic app account the authentication service should be used with the direct homeserver URL
        // and the screen should request to continue the flow without any server selection needed.
        let deferred = deferFulfillment(viewModel.actions) { $0.isLoginDirectlyWithOAuth }
        context.send(viewAction: .continueWithClassic(classicAppAccount))
        try await deferred.fulfill()
        
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 2)
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksReceivedArguments?.homeserverAddress == "https://matrix.company.com")
        #expect(authenticationService.homeserver.value.loginMode == .oAuth(supportsCreatePrompt: false))
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesReceivedArguments?.loginHint == "mxid:\(classicAppAccount.userID)")
    }
    
    @Test
    func classicAppAccountOnUnsupportedServer() async {
        // Given a view model with a Classic app account whose server supports neither OAuth nor password login.
        let classicAppAccount = makeClassicAppAccount()
        await setupViewModel(classicAppAccount: classicAppAccount, supportsOAuth: false, supportsPasswordLogin: false)
        guard case .welcomeBack(let account) = context.viewState.classicAppMode else {
            Issue.record("Expected classicAppMode to be .welcomeBack")
            return
        }
        #expect(account == classicAppAccount)
        
        // Then the Classic app account should indicate that it isn't supported (so the view falls back to the standard content).
        #expect(account.state.isServerSupported == false)
    }
    
    @Test
    func classicAppAccountWithProvisioningLink() async {
        // Given a view model that has been provisioned with a provisioning link (and a classic account exists).
        let classicAppAccount = makeClassicAppAccount()
        await setupViewModel(classicAppAccount: classicAppAccount,
                             provisioningParameters: .init(accountProvider: "company.com", loginHint: nil))
        
        // Then the Classic app account should not be shown — provisioning takes precedence.
        #expect(context.viewState.classicAppMode == nil)
    }
    
    @Test
    func singleProviderWithMatchingClassicAppAccount() async {
        // Given a view model for an app that only allows a single provider that matches the Classic account's server.
        let classicAppAccount = makeClassicAppAccount(serverName: "company.com",
                                                      homeserverURL: "https://matrix.company.com")
        setAllowedAccountProviders(["company.com"])
        await setupViewModel(classicAppAccount: classicAppAccount)
        
        // Then the Classic app account should be shown as a welcome-back option.
        guard case .welcomeBack(let account) = context.viewState.classicAppMode else {
            Issue.record("Expected classicAppMode to be .welcomeBack")
            return
        }
        #expect(account == classicAppAccount)
    }
    
    @Test
    func singleProviderWithDisallowedClassicAppAccount() async {
        // Given a view model for an app that only allows a single provider that does NOT match the Classic account's server.
        let classicAppAccount = makeClassicAppAccount(serverName: "other-server.org",
                                                      homeserverURL: "https://matrix.other-server.org")
        setAllowedAccountProviders(["company.com"])
        await setupViewModel(classicAppAccount: classicAppAccount)
        
        // Then the Classic app account should not be shown since the server is not in the allowed providers.
        #expect(context.viewState.classicAppMode == nil)
    }
    
    @Test
    func classicAppAccountRequiresBackup() async throws {
        // Given a view model with a Classic app account that requires backup before signing in.
        let classicAppAccount = makeClassicAppAccount()
        await setupViewModel(classicAppAccount: classicAppAccount, availableSecrets: .requiresBackup)
        guard case .welcomeBack(let account) = context.viewState.classicAppMode else {
            Issue.record("Expected classicAppMode to be .welcomeBack")
            return
        }
        #expect(account.state.availableSecrets == .requiresBackup)
        
        // When continuing with the Classic account while backup is required.
        var deferred = deferFulfillment(context.observe(\.viewState.bindings.showClassicAppBackupInstructions)) { $0 }
        context.send(viewAction: .continueWithClassic(classicAppAccount))
        
        // Then the backup instructions should be shown.
        try await deferred.fulfill()
        
        // When the user completes the backup in the Classic app and the app returns to the foreground.
        classicAppManager?.availableSecretsForReturnValue = .complete
        deferred = deferFulfillment(context.observe(\.viewState.bindings.showClassicAppBackupInstructions)) { !$0 }
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        
        // Then the backup instructions sheet should be dismissed.
        try await deferred.fulfill()
        
        // When the user continues with the Classic account again.
        let deferredAction = deferFulfillment(viewModel.actions) { $0.isLoginDirectlyWithOAuth }
        context.send(viewAction: .continueWithClassic(classicAppAccount))
        
        // Then the flow should continue the login process.
        try await deferredAction.fulfill()
    }
    
    // MARK: - Helpers
    
    private func setupViewModel(classicAppAccount: ClassicAppAccount? = nil,
                                provisioningParameters: AccountProvisioningParameters? = nil,
                                supportsOAuth: Bool = true,
                                supportsPasswordLogin: Bool = true,
                                availableSecrets: ClassicAppAccount.AvailableSecrets = .complete) async {
        // Manually create a configuration as the default homeserver address setting is immutable.
        client = ClientSDKMock(configuration: .init(oAuthLoginURL: supportsOAuth ? "https://account.company.com/authorize" : nil,
                                                    supportsOAuthCreatePrompt: false,
                                                    supportsPasswordLogin: supportsPasswordLogin))
        // Map both the server name and the homeserver URL so fallback lookups work.
        let homeserverClients: [String: ClientSDKMock] = ["company.com": client,
                                                          "https://matrix.company.com": client]
        let configuration = AuthenticationClientFactoryMock.Configuration(homeserverClients: homeserverClients)
        
        if let classicAppAccount {
            classicAppManager = ClassicAppManagerMock(.init(accounts: [classicAppAccount], availableSecrets: availableSecrets))
        } else {
            classicAppManager = nil
        }
        
        notificationCenter = NotificationCenter()
        
        clientFactory = AuthenticationClientFactoryMock(configuration: configuration)
        authenticationService = AuthenticationService(userSessionStore: UserSessionStoreMock(configuration: .init()),
                                                      encryptionKeyProvider: EncryptionKeyProvider(),
                                                      classicAppManager: classicAppManager,
                                                      clientFactory: clientFactory,
                                                      appSettings: appSettings,
                                                      appHooks: AppHooks())
        
        await authenticationService.setupClassicAppAccountState()
        
        viewModel = AuthenticationStartScreenViewModel(authenticationService: authenticationService,
                                                       provisioningParameters: provisioningParameters,
                                                       isBugReportServiceEnabled: true,
                                                       appMediator: AppMediatorMock(),
                                                       appSettings: appSettings,
                                                       mediaProvider: MediaProviderMock(configuration: .init()),
                                                       notificationCenter: notificationCenter,
                                                       userIndicatorController: UserIndicatorControllerMock())
        
        // Add a fake window in order for the OAuth flow to continue
        viewModel.context.send(viewAction: .updateWindow(UIWindow()))
    }
    
    private func makeClassicAppAccount(serverName: String = "company.com",
                                       homeserverURL: URL = "https://matrix.company.com") -> ClassicAppAccount {
        ClassicAppAccount(userID: "@user:\(serverName)",
                          displayName: "Classic User",
                          avatarURL: nil,
                          serverName: serverName,
                          homeserverURL: homeserverURL,
                          cryptoStoreURL: "file:///tmp/crypto-store",
                          cryptoStorePassphrase: "passphrase",
                          accessToken: "accessToken")
    }
    
    private func setAllowedAccountProviders(_ providers: [String]) {
        appSettings.override(accountProviders: providers,
                             allowOtherAccountProviders: false,
                             hideBrandChrome: false,
                             pushGatewayBaseURL: appSettings.pushGatewayBaseURL,
                             oAuthRedirectURL: appSettings.oAuthRedirectURL,
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
    var isLoginDirectlyWithOAuth: Bool {
        switch self {
        case .loginDirectlyWithOAuth: true
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
