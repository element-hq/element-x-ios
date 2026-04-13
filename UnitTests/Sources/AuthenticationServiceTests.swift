//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import MatrixRustSDKMocks
import Testing

@MainActor
struct AuthenticationServiceTests {
    var client: ClientSDKMock!
    var encryption: EncryptionSDKMock!
    var userSessionStore: UserSessionStoreMock!
    var encryptionKeyProvider: MockEncryptionKeyProvider!
    var service: AuthenticationService!
    
    @Test
    mutating func passwordLogin() async throws {
        try await setup(serverAddress: "example.com")
        
        switch await service.configure(for: "example.com", flow: .login) {
        case .success:
            break
        case .failure(let error):
            Issue.record("Unexpected failure: \(error)")
        }
        
        #expect(service.flow == .login)
        #expect(service.homeserver.value == .mockBasicServer)
        
        switch await service.login(username: "alice", password: "12345678", initialDeviceName: nil, deviceID: nil) {
        case .success:
            #expect(client.loginUsernamePasswordInitialDeviceNameDeviceIdCallsCount == 1)
            #expect(userSessionStore.userSessionForSessionDirectoriesPassphraseCallsCount == 1)
            #expect(userSessionStore.userSessionForSessionDirectoriesPassphraseReceivedArguments?.passphrase ==
                encryptionKeyProvider.generateKey().base64EncodedString())
        case .failure(let error):
            Issue.record("Unexpected failure: \(error)")
        }
    }
    
    @Test
    mutating func configureLoginWithOIDC() async throws {
        try await setup()
        
        try await service.configure(for: "matrix.org", flow: .login).get()
        
        #expect(service.flow == .login)
        #expect(service.homeserver.value == .mockMatrixDotOrg)
    }
    
    @Test
    mutating func configureRegisterWithOIDC() async throws {
        try await setup()
        
        try await service.configure(for: "matrix.org", flow: .register).get()
        
        #expect(service.flow == .register)
        #expect(service.homeserver.value == .mockMatrixDotOrg)
    }
    
    @Test
    @MainActor
    mutating func configureRegisterNoSupport() async throws {
        let homeserverAddress = "example.com"
        try await setup(serverAddress: homeserverAddress)
        
        try await #require(throws: AuthenticationServiceError.registrationNotSupported) {
            try await service.configure(for: homeserverAddress, flow: .register).get()
        }
        
        #expect(service.flow == .login)
        #expect(service.homeserver.value == .init(address: "matrix.org", loginMode: .unknown))
    }
    
    @Test
    @MainActor
    mutating func classicAppAccountSecretsBundleIsUsed() async throws {
        // Given an authentication service with an Element Classic account for Alice.
        try await setup(classicAppAccounts: [.mockAlice])
        try await service.configure(for: "matrix.org", flow: .login).get()
        #expect(service.flow == .login)
        #expect(service.classicAppAccount?.state.availableSecrets == .complete)
        
        // When logging in as Alice.
        _ = try await service.login(username: "alice", password: "12345678", initialDeviceName: nil, deviceID: nil).get()
        #expect(client.loginUsernamePasswordInitialDeviceNameDeviceIdCallsCount == 1)
        
        // Then Alice's secrets from Element Classic should be imported.
        #expect(encryption.importSecretsBundleSecretsBundleCalled)
    }
    
    @Test
    @MainActor
    mutating func classicAppAccountSecretsBundleIsIgnoredWhenUnavailable() async throws {
        // Given an authentication service with an Element Classic account for Alice
        // which isn't configured with any available secrets.
        try await setup(classicAppAccounts: [.mockAlice], availableSecrets: .unavailable)
        try await service.configure(for: "matrix.org", flow: .login).get()
        #expect(service.flow == .login)
        #expect(service.classicAppAccount?.state.availableSecrets == .unavailable)
        
        // When logging in as Alice.
        _ = try await service.login(username: "alice", password: "12345678", initialDeviceName: nil, deviceID: nil).get()
        #expect(client.loginUsernamePasswordInitialDeviceNameDeviceIdCallsCount == 1)
        
        // Then an attempt to import Alice's secrets from Element Classic must not be made.
        #expect(!encryption.importSecretsBundleSecretsBundleCalled)
    }
    
    @Test
    @MainActor
    mutating func classicAppAccountSecretsBundleIsIgnoredForDifferentUser() async throws {
        // Given an authentication service with an Element Classic account for Dan.
        try await setup(classicAppAccounts: [.mockDan])
        try await service.configure(for: "matrix.org", flow: .login).get()
        #expect(service.flow == .login)
        #expect(service.classicAppAccount?.state.availableSecrets == .complete)
        
        // When logging in as Alice
        _ = try await service.login(username: "alice", password: "12345678", initialDeviceName: nil, deviceID: nil).get()
        #expect(client.loginUsernamePasswordInitialDeviceNameDeviceIdCallsCount == 1)
        
        // Then Dan's secrets from Element Calssic should not be imported into Alice's client.
        #expect(!encryption.importSecretsBundleSecretsBundleCalled)
    }
    
    // MARK: - Helpers
    
    private mutating func setup(serverAddress: String = "matrix.org",
                                classicAppAccounts: [ClassicAppAccount] = [],
                                availableSecrets: ClassicAppAccount.AvailableSecrets = .complete) async throws {
        let configuration: AuthenticationClientFactoryMock.Configuration = .init()
        let clientFactory = AuthenticationClientFactoryMock(configuration: configuration)
        
        client = configuration.homeserverClients[serverAddress]
        encryption = EncryptionSDKMock()
        client.encryptionReturnValue = encryption
        
        userSessionStore = UserSessionStoreMock(configuration: .init())
        encryptionKeyProvider = MockEncryptionKeyProvider()
        
        let classicAppManager = ClassicAppManagerMock(.init(accounts: classicAppAccounts,
                                                            availableSecrets: availableSecrets,
                                                            secretsBundle: .init(noHandle: .init())))
        
        service = AuthenticationService(userSessionStore: userSessionStore,
                                        encryptionKeyProvider: encryptionKeyProvider,
                                        classicAppManager: classicAppManager,
                                        clientFactory: clientFactory,
                                        appSettings: ServiceLocator.shared.settings,
                                        appHooks: AppHooks())
        
        if let classicAppAccount = service.classicAppAccount {
            await service.setupClassicAppAccountState()
            try #require(classicAppAccount.state.isServerSupported == true)
            try #require(classicAppAccount.state.availableSecrets == availableSecrets)
        }
    }
}

struct MockEncryptionKeyProvider: EncryptionKeyProviderProtocol {
    private let key = "12345678"
    
    func generateKey() -> Data {
        Data(key.utf8)
    }
}
