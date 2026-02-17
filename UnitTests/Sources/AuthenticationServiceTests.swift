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

@Suite
struct AuthenticationServiceTests {
    @MainActor
    private struct TestSetup {
        var client: ClientSDKMock!
        var userSessionStore: UserSessionStoreMock!
        var encryptionKeyProvider: MockEncryptionKeyProvider!
        var service: AuthenticationService!
        
        init(serverAddress: String = "matrix.org") {
            let configuration: AuthenticationClientFactoryMock.Configuration = .init()
            let clientFactory = AuthenticationClientFactoryMock(configuration: configuration)
            
            client = configuration.homeserverClients[serverAddress]
            userSessionStore = UserSessionStoreMock(configuration: .init())
            encryptionKeyProvider = MockEncryptionKeyProvider()
            
            service = AuthenticationService(userSessionStore: userSessionStore,
                                            encryptionKeyProvider: encryptionKeyProvider,
                                            clientFactory: clientFactory,
                                            appSettings: ServiceLocator.shared.settings,
                                            appHooks: AppHooks())
        }
    }
    
    @Test
    @MainActor
    func passwordLogin() async {
        var testSetup = TestSetup(serverAddress: "example.com")
        
        switch await testSetup.service.configure(for: "example.com", flow: .login) {
        case .success:
            break
        case .failure(let error):
            Issue.record("Unexpected failure: \(error)")
        }
        
        #expect(testSetup.service.flow == .login)
        #expect(testSetup.service.homeserver.value == .mockBasicServer)
        
        switch await testSetup.service.login(username: "alice", password: "12345678", initialDeviceName: nil, deviceID: nil) {
        case .success:
            #expect(testSetup.client.loginUsernamePasswordInitialDeviceNameDeviceIdCallsCount == 1)
            #expect(testSetup.userSessionStore.userSessionForSessionDirectoriesPassphraseCallsCount == 1)
            #expect(testSetup.userSessionStore.userSessionForSessionDirectoriesPassphraseReceivedArguments?.passphrase ==
                testSetup.encryptionKeyProvider.generateKey().base64EncodedString())
        case .failure(let error):
            Issue.record("Unexpected failure: \(error)")
        }
    }
    
    @Test
    @MainActor
    func configureLoginWithOIDC() async {
        var testSetup = TestSetup()
        
        switch await testSetup.service.configure(for: "matrix.org", flow: .login) {
        case .success:
            break
        case .failure(let error):
            Issue.record("Unexpected failure: \(error)")
        }
        
        #expect(testSetup.service.flow == .login)
        #expect(testSetup.service.homeserver.value == .mockMatrixDotOrg)
    }
    
    @Test
    @MainActor
    func configureRegisterWithOIDC() async {
        var testSetup = TestSetup()
        
        switch await testSetup.service.configure(for: "matrix.org", flow: .register) {
        case .success:
            break
        case .failure(let error):
            Issue.record("Unexpected failure: \(error)")
        }
        
        #expect(testSetup.service.flow == .register)
        #expect(testSetup.service.homeserver.value == .mockMatrixDotOrg)
    }
    
    @Test
    @MainActor
    func configureRegisterNoSupport() async {
        let homeserverAddress = "example.com"
        var testSetup = TestSetup(serverAddress: homeserverAddress)
        
        switch await testSetup.service.configure(for: homeserverAddress, flow: .register) {
        case .success:
            Issue.record("Configuration should have failed")
        case .failure(let error):
            #expect(error == .registrationNotSupported)
        }
        
        #expect(testSetup.service.flow == .login)
        #expect(testSetup.service.homeserver.value == .init(address: "matrix.org", loginMode: .unknown))
    }
}

struct MockEncryptionKeyProvider: EncryptionKeyProviderProtocol {
    private let key = "12345678"
    
    func generateKey() -> Data {
        Data(key.utf8)
    }
}
