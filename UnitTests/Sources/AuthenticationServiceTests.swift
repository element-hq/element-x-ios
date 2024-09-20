//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

class AuthenticationServiceTests: XCTestCase {
    var client: ClientSDKMock!
    var userSessionStore: UserSessionStoreMock!
    var encryptionKeyProvider: MockEncryptionKeyProvider!
    
    var service: AuthenticationService!
    
    func testLogin() async {
        setupMocks()
        
        switch await service.configure(for: "matrix.org", flow: .login) {
        case .success:
            break
        case .failure(let error):
            XCTFail("Unexpected failure: \(error)")
        }
        
        XCTAssertEqual(service.flow, .login)
        XCTAssertEqual(service.homeserver.value, .mockMatrixDotOrg)
        
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
    
    func testConfigureRegister() async {
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
        let configuration: AuthenticationClientBuilderMock.Configuration = .init()
        let clientBuilderFactory = AuthenticationClientBuilderFactoryMock(configuration: .init(builderConfiguration: configuration))
        
        client = configuration.homeserverClients[serverAddress]
        userSessionStore = UserSessionStoreMock(configuration: .init())
        encryptionKeyProvider = MockEncryptionKeyProvider()
        
        service = AuthenticationService(userSessionStore: userSessionStore,
                                        encryptionKeyProvider: encryptionKeyProvider,
                                        clientBuilderFactory: clientBuilderFactory,
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
