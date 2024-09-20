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
        
        switch await service.login(username: "alice", password: "p4ssw0rd", initialDeviceName: nil, deviceID: nil) {
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
        setupMocks(clientConfiguration: .init(elementWellKnown: ""))
        
        switch await service.configure(for: "matrix.org", flow: .register) {
        case .success:
            XCTFail("Configuration should have failed")
        case .failure(let error):
            XCTAssertEqual(error, .registrationNotSupported)
        }
        
        XCTAssertEqual(service.flow, .login)
        XCTAssertEqual(service.homeserver.value, .init(address: "matrix.org", loginMode: .unknown))
    }
    
    // MARK: - Helpers
    
    private func setupMocks(clientConfiguration: ClientSDKMock.Configuration = .init()) {
        client = ClientSDKMock(configuration: clientConfiguration)
        userSessionStore = UserSessionStoreMock(configuration: .init())
        encryptionKeyProvider = MockEncryptionKeyProvider()
        
        service = AuthenticationService(userSessionStore: userSessionStore,
                                        encryptionKeyProvider: encryptionKeyProvider,
                                        clientBuilderFactory: AuthenticationClientBuilderFactoryMock(configuration: .init(builtClient: client)),
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
