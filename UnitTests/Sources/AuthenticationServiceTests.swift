//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import ElementX
import MatrixRustSDKMocks

class AuthenticationServiceTests: XCTestCase {
    var client: ClientSDKMock!
    var userSessionStore: UserSessionStoreMock!
    var encryptionKeyProvider: MockEncryptionKeyProvider!
    
    var service: AuthenticationService!
    
    func testPasswordLogin() async {
        setupMocks(serverAddress: "example.com")
        
        switch await service.configure(for: "example.com", flow: .login) {
        case .success:
            break
        case .failure(let error):
            XCTFail("Unexpected failure: \(error)")
        }
        
        XCTAssertEqual(service.flow, .login)
        XCTAssertEqual(service.homeserver.value, .mockBasicServer)
        
        switch await service.login(username: "alice", password: "12345678", initialDeviceName: nil, deviceID: nil) {
        case .success:
            XCTAssertEqual(client.loginUsernamePasswordInitialDeviceNameDeviceIdCallsCount, 1)
            XCTAssertEqual(userSessionStore.userSessionForSessionDirectoriesPassphraseCallsCount, 1)
            XCTAssertEqual(userSessionStore.userSessionForSessionDirectoriesPassphraseReceivedArguments?.passphrase,
                           encryptionKeyProvider.generateKey().base64EncodedString())
        case .failure(let error):
            XCTFail("Unexpected failure: \(error)")
        }
    }
    
    func testConfigureLoginWithOIDC() async {
        setupMocks()
        
        switch await service.configure(for: "matrix.org", flow: .login) {
        case .success:
            break
        case .failure(let error):
            XCTFail("Unexpected failure: \(error)")
        }
        
        XCTAssertEqual(service.flow, .login)
        XCTAssertEqual(service.homeserver.value, .mockMatrixDotOrg)
    }
    
    func testConfigureRegisterWithOIDC() async {
        setupMocks()
        
        switch await service.configure(for: "matrix.org", flow: .register) {
        case .success:
            break
        case .failure(let error):
            XCTFail("Unexpected failure: \(error)")
        }
        
        XCTAssertEqual(service.flow, .register)
        XCTAssertEqual(service.homeserver.value, .mockMatrixDotOrg)
    }
    
    func testConfigureRegisterNoSupport() async {
        let homeserverAddress = "example.com"
        setupMocks(serverAddress: homeserverAddress)
        
        switch await service.configure(for: homeserverAddress, flow: .register) {
        case .success:
            XCTFail("Configuration should have failed")
        case .failure(let error):
            XCTAssertEqual(error, .registrationNotSupported)
        }
        
        XCTAssertEqual(service.flow, .login)
        XCTAssertEqual(service.homeserver.value, .init(address: "matrix.org", loginMode: .unknown))
    }
    
    // MARK: - Helpers
    
    private func setupMocks(serverAddress: String = "matrix.org") {
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

struct MockEncryptionKeyProvider: EncryptionKeyProviderProtocol {
    private let key = "12345678"
    
    func generateKey() -> Data {
        Data(key.utf8)
    }
}
