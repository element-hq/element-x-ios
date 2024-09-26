//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class ServerConfirmationScreenViewModelTests: XCTestCase {
    var clientBuilderFactory: AuthenticationClientBuilderFactoryMock!
    var service: AuthenticationServiceProtocol!
    
    var viewModel: ServerConfirmationScreenViewModel!
    var context: ServerConfirmationScreenViewModel.Context { viewModel.context }
    
    func testConfirmLoginWithoutConfiguration() async throws {
        // Given a view model for login using a service that hasn't been configured.
        setupViewModel(authenticationFlow: .login)
        XCTAssertEqual(service.homeserver.value.loginMode, .unknown)
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 0)
        
        // When continuing from the confirmation screen.
        let deferred = deferFulfillment(viewModel.actions) { $0 == .confirm }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then a call to configure service should be made.
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        XCTAssertNotEqual(service.homeserver.value.loginMode, .unknown)
    }
    
    func testConfirmLoginAfterConfiguration() async throws {
        // Given a view model for login using a service that has already been configured (via the server selection screen).
        setupViewModel(authenticationFlow: .login)
        guard case .success = await service.configure(for: viewModel.state.homeserverAddress, flow: .login) else {
            XCTFail("The configuration should succeed.")
            return
        }
        XCTAssertNotEqual(service.homeserver.value.loginMode, .unknown)
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        
        // When continuing from the confirmation screen.
        let deferred = deferFulfillment(viewModel.actions) { $0 == .confirm }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the configured homeserver should be used and no additional call should be made to the service.
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
    }
    
    func testConfirmRegisterWithoutConfiguration() async throws {
        // Given a view model for registration using a service that hasn't been configured.
        setupViewModel(authenticationFlow: .register)
        XCTAssertEqual(service.homeserver.value.loginMode, .unknown)
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 0)
        
        // When continuing from the confirmation screen.
        let deferred = deferFulfillment(viewModel.actions) { $0 == .confirm }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then a call to configure service should be made.
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        XCTAssertNotEqual(service.homeserver.value.loginMode, .unknown)
    }
    
    func testConfirmRegisterAfterConfiguration() async throws {
        // Given a view model for registration using a service that has already been configured (via the server selection screen).
        setupViewModel(authenticationFlow: .register)
        guard case .success = await service.configure(for: viewModel.state.homeserverAddress, flow: .register) else {
            XCTFail("The configuration should succeed.")
            return
        }
        XCTAssertNotEqual(service.homeserver.value.loginMode, .unknown)
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        
        // When continuing from the confirmation screen.
        let deferred = deferFulfillment(viewModel.actions) { $0 == .confirm }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the configured homeserver should be used and no additional call should be made to the service.
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
    }
    
    func testRegistrationNotSupportedAlert() async throws {
        // Given a view model for registration using a service that hasn't been configured and the default server doesn't support registration.
        setupViewModel(authenticationFlow: .register, elementWellKnown: false)
        XCTAssertEqual(service.homeserver.value.loginMode, .unknown)
        XCTAssertFalse(service.homeserver.value.supportsRegistration)
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 0)
        XCTAssertNil(context.alertInfo)
        
        // When continuing from the confirmation screen.
        let deferred = deferFulfillment(context.$viewState) { $0.bindings.alertInfo != nil }
        context.send(viewAction: .confirm)
        try await deferred.fulfill()
        
        // Then the configured homeserver should be used and no additional call should be made to the service.
        XCTAssertEqual(clientBuilderFactory.makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount, 1)
        XCTAssertEqual(context.alertInfo?.id, .registration)
    }
    
    // MARK: - Helpers
    
    private func setupViewModel(authenticationFlow: AuthenticationFlow, elementWellKnown: Bool = true) {
        let client = ClientSDKMock(configuration: elementWellKnown ? .init() : .init(elementWellKnown: ""))
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
                                                      slidingSyncLearnMoreURL: ServiceLocator.shared.settings.slidingSyncLearnMoreURL,
                                                      userIndicatorController: UserIndicatorControllerMock())
    }
}
