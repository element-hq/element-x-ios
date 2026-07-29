//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import MatrixRustSDKMocks
import SwiftUI
import Testing

@MainActor
struct ServerSelectionScreenViewModelTests {
    let pickerProviders = ["matrix.org", "beta.matrix.org"]
    
    var appSettings: AppSettings!
    var client: ClientSDKMock!
    var clientFactory: AuthenticationClientFactoryMock!
    var service: AuthenticationServiceProtocol!
    var viewModel: ServerSelectionScreenViewModelProtocol!
    
    var context: ServerSelectionScreenViewModelType.Context {
        viewModel.context
    }
    
    @Test
    mutating func selectForLogin() async throws {
        // Given a view model for login.
        try setup(authenticationFlow: .login)
        #expect(service.homeserver.value.loginMode == .unknown)
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
        
        // When selecting matrix.org.
        context.homeserverAddress = "matrix.org"
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithOAuth }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then selection should succeed.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(service.homeserver.value == .mockMatrixDotOrg)
    }
    
    @Test
    mutating func loginNotSupportedAlert() async throws {
        // Given a view model for login.
        try setup(authenticationFlow: .login)
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
        try setup(authenticationFlow: .register)
        #expect(service.homeserver.value.loginMode == .unknown)
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
        
        // When selecting matrix.org.
        context.homeserverAddress = "matrix.org"
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithOAuth }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then selection should succeed.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(service.homeserver.value == .mockMatrixDotOrg)
    }
    
    @Test
    mutating func registrationNotSupportedAlert() async throws {
        // Given a view model for registration.
        try setup(authenticationFlow: .register)
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
        try setup(authenticationFlow: .login)
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
        try setup(authenticationFlow: .login)
        #expect(!context.viewState.isShowingFooterError, "There should not be an error message for a new view model.")
        #expect(context.viewState.footerErrorMessage == nil, "There should not be an error message for a new view model.")
        #expect(String(context.viewState.footerMessage) == UntranslatedL10n.screenSelectServerTextfieldFooterLogin,
                "The standard footer message should be shown.")
        
        // When attempting to discover an invalid server
        var deferred = deferFulfillment(context.observe(\.viewState.isShowingFooterError)) { $0 }
        context.homeserverAddress = "idontexist"
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the footer should now be showing an error.
        #expect(context.viewState.isShowingFooterError, "The error message should be stored.")
        #expect(context.viewState.footerErrorMessage != nil, "The error message should be stored.")
        #expect(String(context.viewState.footerMessage) != UntranslatedL10n.screenSelectServerTextfieldFooterLogin,
                "The error message should be shown.")
        
        // And when clearing the error.
        deferred = deferFulfillment(context.observe(\.viewState.isShowingFooterError)) { !$0 }
        context.homeserverAddress = ""
        context.send(viewAction: .clearFooterError)
        try await deferred.fulfill()
        
        // Then the error message should now be removed.
        #expect(context.viewState.footerErrorMessage == nil, "The error message should have been cleared.")
        #expect(String(context.viewState.footerMessage) == UntranslatedL10n.screenSelectServerTextfieldFooterLogin,
                "The standard footer message should be shown again.")
    }
    
    // MARK: - userInput mode
    
    @Test
    mutating func userInputLoginWithoutConfiguration() async throws {
        // Given a view model for login using a service that hasn't been configured.
        try setup(authenticationFlow: .login)
        #expect(service.homeserver.value.loginMode == .unknown)
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        
        // When confirming from the server selection screen.
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithOAuth }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the service should be configured and the OAuth URL fetched.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 1)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesReceivedArguments?.prompt == .consent)
        #expect(service.homeserver.value.loginMode == .oAuth(supportsCreatePrompt: true))
    }
    
    @Test
    mutating func userInputLoginAfterConfiguration() async throws {
        // Given a view model for login using a service that has already been configured.
        try setup(authenticationFlow: .login)
        guard case .success = await service.configure(for: context.homeserverAddress, flow: .login) else {
            Issue.record("The configuration should succeed.")
            return
        }
        #expect(service.homeserver.value.loginMode == .oAuth(supportsCreatePrompt: true))
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        
        // When confirming from the server selection screen.
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithOAuth }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the service should be re-configured (no skip-if-already-configured optimisation here) and the OAuth URL fetched.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 2)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 1)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesReceivedArguments?.prompt == .consent)
    }
    
    @Test
    mutating func userInputRegisterWithoutConfiguration() async throws {
        // Given a view model for registration using a service that hasn't been configured.
        try setup(authenticationFlow: .register)
        #expect(service.homeserver.value.loginMode == .unknown)
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        
        // When confirming from the server selection screen.
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithOAuth }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the service should be configured and the OAuth URL fetched.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 1)
        #expect(service.homeserver.value.loginMode == .oAuth(supportsCreatePrompt: true))
    }
    
    @Test
    mutating func userInputRegisterAfterConfiguration() async throws {
        // Given a view model for registration using a service that has already been configured.
        try setup(authenticationFlow: .register)
        guard case .success = await service.configure(for: context.homeserverAddress, flow: .register) else {
            Issue.record("The configuration should succeed.")
            return
        }
        #expect(service.homeserver.value.loginMode == .oAuth(supportsCreatePrompt: true))
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        
        // When confirming from the server selection screen.
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithOAuth }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the service should be re-configured and the OAuth URL fetched.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 2)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 1)
    }
    
    @Test
    mutating func userInputPasswordLoginWithoutConfiguration() async throws {
        // Given a view model for login using a service that hasn't been configured against a server that doesn't support OAuth.
        try setup(authenticationFlow: .login, supportsOAuth: false)
        #expect(service.homeserver.value.loginMode == .unknown)
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        
        // When confirming from the server selection screen.
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithPassword }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the service should be configured but no OAuth URL fetched.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        #expect(service.homeserver.value.loginMode == .password)
    }
    
    @Test
    mutating func userInputPasswordLoginAfterConfiguration() async throws {
        // Given a view model for login using a service that has already been configured against a server that doesn't support OAuth.
        try setup(authenticationFlow: .login, supportsOAuth: false)
        guard case .success = await service.configure(for: context.homeserverAddress, flow: .login) else {
            Issue.record("The configuration should succeed.")
            return
        }
        #expect(service.homeserver.value.loginMode == .password)
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        
        // When confirming from the server selection screen.
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithPassword }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the service should be re-configured but no OAuth URL fetched.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 2)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
    }
    
    // MARK: - Picker mode
    
    @Test
    mutating func pickerWithoutConfiguration() async throws {
        // Given a view model for login using a service that hasn't been configured.
        try setup(authenticationFlow: .login, mode: .picker(pickerProviders))
        #expect(service.homeserver.value.loginMode == .unknown)
        #expect(context.viewState.mode == .picker(pickerProviders))
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        
        // When confirming from the picker.
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithOAuth }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the service should be configured and the OAuth URL fetched.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 1)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesReceivedArguments?.prompt == .consent)
        #expect(service.homeserver.value.loginMode == .oAuth(supportsCreatePrompt: true))
    }
    
    @Test
    mutating func pickerAfterConfiguration() async throws {
        // Given a view model for login using a service that has already been configured.
        try setup(authenticationFlow: .login, mode: .picker(pickerProviders))
        guard case .success = await service.configure(for: context.homeserverAddress, flow: .login) else {
            Issue.record("The configuration should succeed.")
            return
        }
        #expect(service.homeserver.value.loginMode == .oAuth(supportsCreatePrompt: true))
        #expect(context.viewState.mode == .picker(pickerProviders))
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        
        // When confirming from the picker.
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithOAuth }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the already-configured homeserver should be used without re-configuring.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 1)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesReceivedArguments?.prompt == .consent)
    }
    
    @Test
    mutating func pickerForPasswordLoginWithoutConfiguration() async throws {
        // Given a view model for login using a service that hasn't been configured against a server that doesn't support OAuth.
        try setup(authenticationFlow: .login, mode: .picker(pickerProviders), supportsOAuth: false)
        #expect(service.homeserver.value.loginMode == .unknown)
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        
        // When confirming from the picker.
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithPassword }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the service should be configured but no OAuth URL fetched.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        #expect(service.homeserver.value.loginMode == .password)
    }
    
    @Test
    mutating func pickerForPasswordLoginAfterConfiguration() async throws {
        // Given a view model for login using a service that has already been configured against a server that doesn't support OAuth.
        try setup(authenticationFlow: .login, mode: .picker(pickerProviders), supportsOAuth: false)
        guard case .success = await service.configure(for: context.homeserverAddress, flow: .login) else {
            Issue.record("The configuration should succeed.")
            return
        }
        #expect(service.homeserver.value.loginMode == .password)
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
        
        // When confirming from the picker.
        let deferred = deferFulfillment(viewModel.actions) { $0.isContinueWithPassword }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the already-configured homeserver should be used without re-configuring.
        #expect(clientFactory.makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 1)
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 0)
    }
    
    // MARK: - Autocomplete
    
    @Test
    mutating func autocompleteMatchesPreviousServers() async throws {
        // Given a view model with a previous server in history.
        try setup(authenticationFlow: .login)
        appSettings.previousServers = ["myserver.com"]
        context.homeserverAddress = ""
        let textField = UITextField()
        context.send(viewAction: .updateTextField(textField))
        
        // When the user types a prefix that matches the previous server.
        let typedSoFar = "my"
        let nextChar = "s"
        let typed = typedSoFar + nextChar
        let expectedAddress = "myserver.com"
        textField.text = typedSoFar
        let deferred = deferFulfillment(context.observe(\.homeserverAddress)) { $0 == expectedAddress }
        _ = textField.delegate?.textField?(textField, shouldChangeCharactersIn: NSRange(location: typedSoFar.count, length: 0), replacementString: nextChar)
        try await deferred.fulfill()
        
        // Then the address should be completed and the appended portion selected.
        let selectionStart = expectedAddress.index(expectedAddress.startIndex, offsetBy: typed.count)
        #expect(context.homeserverAddress == expectedAddress)
        #expect(context.homeserverSelection == TextSelection(range: selectionStart..<expectedAddress.endIndex))
    }
    
    @Test
    mutating func autocompleteFromAccountProviders() async throws {
        // Given a view model with no previous server history, falling back to the default account providers.
        try setup(authenticationFlow: .login)
        #expect(appSettings.previousServers.isEmpty)
        context.homeserverAddress = ""
        let textField = UITextField()
        context.send(viewAction: .updateTextField(textField))
        
        // When the user types a prefix that matches an account provider.
        let typedSoFar = "ma"
        let nextChar = "t"
        let typed = typedSoFar + nextChar
        let expectedAddress = "matrix.org"
        textField.text = typedSoFar
        let deferred = deferFulfillment(context.observe(\.homeserverAddress)) { $0 == expectedAddress }
        _ = textField.delegate?.textField?(textField, shouldChangeCharactersIn: NSRange(location: typedSoFar.count, length: 0), replacementString: nextChar)
        try await deferred.fulfill()
        
        // Then the address should be completed and the appended portion selected.
        let selectionStart = expectedAddress.index(expectedAddress.startIndex, offsetBy: typed.count)
        #expect(context.homeserverAddress == expectedAddress)
        #expect(context.homeserverSelection == TextSelection(range: selectionStart..<expectedAddress.endIndex))
    }
    
    @Test
    mutating func autocompleteNoMatch() async throws {
        // Given a view model with a known set of servers.
        try setup(authenticationFlow: .login)
        appSettings.previousServers = ["myserver.com"]
        context.homeserverAddress = ""
        let textField = UITextField()
        context.send(viewAction: .updateTextField(textField))
        
        // When the user types a string that doesn't match any known server prefix.
        textField.text = "xy"
        _ = textField.delegate?.textField?(textField, shouldChangeCharactersIn: NSRange(location: 2, length: 0), replacementString: "z")
        try await Task.sleep(for: .milliseconds(50))
        
        // Then the address should remain unchanged.
        #expect(context.homeserverAddress == "")
    }
    
    @Test
    mutating func autocompleteLRUOrder() async throws {
        // Given a view model with an ordered server history.
        try setup(authenticationFlow: .login)
        appSettings.previousServers = ["abc.foo", "matrix.org", "mantis.asdf"]
        context.homeserverAddress = ""
        let textField = UITextField()
        context.send(viewAction: .updateTextField(textField))
        
        // Step 1: type "m" — first "m" match in history is "matrix.org".
        textField.text = ""
        var deferred = deferFulfillment(context.observe(\.homeserverAddress)) { $0 == "matrix.org" }
        _ = textField.delegate?.textField?(textField, shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: "m")
        try await deferred.fulfill()
        #expect(context.homeserverAddress == "matrix.org")
        
        // Step 2: type "a" replacing the highlighted suffix — still matches "matrix.org".
        // textField.text = "matrix.org", "atrix.org" highlighted (loc: 1, len: 9).
        deferred = deferFulfillment(context.observe(\.homeserverAddress)) { $0 == "matrix.org" }
        _ = textField.delegate?.textField?(textField, shouldChangeCharactersIn: NSRange(location: 1, length: 9), replacementString: "a")
        try await deferred.fulfill()
        #expect(context.homeserverAddress == "matrix.org")
        
        // Step 3: type "n" replacing the highlighted suffix — "man" now matches "mantis.asdf".
        // textField.text = "matrix.org", "trix.org" highlighted (loc: 2, len: 8).
        deferred = deferFulfillment(context.observe(\.homeserverAddress)) { $0 == "mantis.asdf" }
        _ = textField.delegate?.textField?(textField, shouldChangeCharactersIn: NSRange(location: 2, length: 8), replacementString: "n")
        try await deferred.fulfill()
        #expect(context.homeserverAddress == "mantis.asdf")
    }
    
    // MARK: - Helpers
    
    private mutating func setup(authenticationFlow: AuthenticationFlow,
                                mode: ServerSelectionScreenMode = .userInput(defaultValue: ""),
                                supportsOAuth: Bool = true,
                                supportsOAuthCreatePrompt: Bool = true,
                                supportsPasswordLogin: Bool = true) throws {
        appSettings = AppSettings.volatile()
        
        client = ClientSDKMock(.init(oAuthLoginURL: supportsOAuth ? "https://account.matrix.org/authorize" : nil,
                                     supportsOAuthCreatePrompt: supportsOAuthCreatePrompt,
                                     supportsPasswordLogin: supportsPasswordLogin))
        var factoryConfig = AuthenticationClientFactoryMock.Configuration()
        factoryConfig.homeserverClients["matrix.org"] = client
        factoryConfig.homeserverClients["https://matrix-client.matrix.org"] = client
        clientFactory = AuthenticationClientFactoryMock(factoryConfig)
        
        service = AuthenticationService(userSessionStore: UserSessionStoreMock(.init()),
                                        encryptionKeyProvider: EncryptionKeyProvider(),
                                        classicAppManager: nil,
                                        clientFactory: clientFactory,
                                        appSettings: appSettings,
                                        appHooks: AppHooks())
        
        viewModel = ServerSelectionScreenViewModel(authenticationService: service,
                                                   mode: mode,
                                                   authenticationFlow: authenticationFlow,
                                                   appSettings: appSettings,
                                                   userIndicatorController: UserIndicatorControllerMock())
        
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        viewModel.context.send(viewAction: .updateWindow(UIWindow(windowScene: scene)))
    }
}

private extension ServerSelectionScreenViewModelAction {
    var isContinueWithOAuth: Bool {
        switch self {
        case .continueWithOAuth: true
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
