//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

@testable import ElementX
import XCTest

class KeychainControllerTests: XCTestCase {
    var keychain: KeychainController!
    
    override func setUp() {
        keychain = KeychainController(service: .tests,
                                      accessGroup: InfoPlistReader.main.keychainAccessGroupIdentifier)
        keychain.removeAllRestorationTokens()
        keychain.resetSecrets()
    }
    
    func testAddRestorationToken() {
        // Given an empty keychain.
        XCTAssertTrue(keychain.restorationTokens().isEmpty, "The keychain should be empty to begin with.")
        
        // When adding an restoration token.
        let username = "@test:example.com"
        let restorationToken = RestorationToken(session: .init(accessToken: "accessToken",
                                                               refreshToken: "refreshToken",
                                                               userId: "userId",
                                                               deviceId: "deviceId",
                                                               homeserverUrl: "homeserverUrl",
                                                               oidcData: "oidcData",
                                                               slidingSyncVersion: .proxy(url: "https://my.sync.proxy")),
                                                sessionDirectories: .init(),
                                                passphrase: "passphrase",
                                                pusherNotificationClientIdentifier: "pusherClientID")
        keychain.setRestorationToken(restorationToken, forUsername: username)
        
        // Then the restoration token should be stored in the keychain.
        XCTAssertEqual(keychain.restorationTokenForUsername(username), restorationToken, "The retrieved restoration token should match the value that was stored.")
    }
    
    func testRemovingRestorationToken() {
        // Given a keychain with a stored restoration token.
        let username = "@test:example.com"
        let restorationToken = RestorationToken(session: .init(accessToken: "accessToken",
                                                               refreshToken: "refreshToken",
                                                               userId: "userId",
                                                               deviceId: "deviceId",
                                                               homeserverUrl: "homeserverUrl",
                                                               oidcData: "oidcData",
                                                               slidingSyncVersion: .proxy(url: "https://my.sync.proxy")),
                                                sessionDirectories: .init(),
                                                passphrase: "passphrase",
                                                pusherNotificationClientIdentifier: "pusherClientID")
        keychain.setRestorationToken(restorationToken, forUsername: username)
        XCTAssertEqual(keychain.restorationTokens().count, 1, "The keychain should have 1 restoration token.")
        XCTAssertEqual(keychain.restorationTokenForUsername(username), restorationToken, "The initial restoration token should match the value that was stored.")
        
        // When deleting the restoration token.
        keychain.removeRestorationTokenForUsername(username)
        
        // Then the keychain should be empty.
        XCTAssertTrue(keychain.restorationTokens().isEmpty, "The keychain should be empty after deleting the token.")
        XCTAssertNil(keychain.restorationTokenForUsername(username), "There restoration token should not be returned after removal.")
    }
    
    func testRemovingAllRestorationTokens() {
        // Given a keychain with 5 stored restoration tokens.
        for index in 0..<5 {
            let restorationToken = RestorationToken(session: .init(accessToken: "accessToken",
                                                                   refreshToken: "refreshToken",
                                                                   userId: "userId",
                                                                   deviceId: "deviceId",
                                                                   homeserverUrl: "homeserverUrl",
                                                                   oidcData: "oidcData",
                                                                   slidingSyncVersion: .proxy(url: "https://my.sync.proxy")),
                                                    sessionDirectories: .init(),
                                                    passphrase: "passphrase",
                                                    pusherNotificationClientIdentifier: "pusherClientID")
            keychain.setRestorationToken(restorationToken, forUsername: "@test\(index):example.com")
        }
        XCTAssertEqual(keychain.restorationTokens().count, 5, "The keychain should have 5 restoration tokens.")
        
        // When deleting all of the restoration tokens.
        keychain.removeAllRestorationTokens()
        
        // Then the keychain should be empty.
        XCTAssertTrue(keychain.restorationTokens().isEmpty, "The keychain should be empty after deleting the token.")
    }
    
    func testRemovingSingleRestorationTokens() {
        // Given a keychain with 5 stored restoration tokens.
        for index in 0..<5 {
            let restorationToken = RestorationToken(session: .init(accessToken: "accessToken",
                                                                   refreshToken: "refreshToken",
                                                                   userId: "userId",
                                                                   deviceId: "deviceId",
                                                                   homeserverUrl: "homeserverUrl",
                                                                   oidcData: "oidcData",
                                                                   slidingSyncVersion: .proxy(url: "https://my.sync.proxy")),
                                                    sessionDirectories: .init(),
                                                    passphrase: "passphrase",
                                                    pusherNotificationClientIdentifier: "pusherClientID")
            keychain.setRestorationToken(restorationToken, forUsername: "@test\(index):example.com")
        }
        XCTAssertEqual(keychain.restorationTokens().count, 5, "The keychain should have 5 restoration tokens.")
        
        // When deleting one of the restoration tokens.
        keychain.removeRestorationTokenForUsername("@test2:example.com")
        
        // Then the other 4 items should remain untouched.
        XCTAssertEqual(keychain.restorationTokens().count, 4, "The keychain have 4 remaining restoration tokens.")
        XCTAssertNotNil(keychain.restorationTokenForUsername("@test0:example.com"), "The restoration token should not have been deleted.")
        XCTAssertNotNil(keychain.restorationTokenForUsername("@test1:example.com"), "The restoration token should not have been deleted.")
        XCTAssertNil(keychain.restorationTokenForUsername("@test2:example.com"), "The restoration token should have been deleted.")
        XCTAssertNotNil(keychain.restorationTokenForUsername("@test3:example.com"), "The restoration token should not have been deleted.")
        XCTAssertNotNil(keychain.restorationTokenForUsername("@test4:example.com"), "The restoration token should not have been deleted.")
    }
    
    func testSimplifiedSlidingSyncRestorationToken() {
        // Given an empty keychain.
        XCTAssertTrue(keychain.restorationTokens().isEmpty, "The keychain should be empty to begin with.")
        
        // When adding an restoration token that doesn't contain a sliding sync proxy (e.g. for SSS).
        let username = "@test:example.com"
        let restorationToken = RestorationToken(session: .init(accessToken: "accessToken",
                                                               refreshToken: "refreshToken",
                                                               userId: "userId",
                                                               deviceId: "deviceId",
                                                               homeserverUrl: "homeserverUrl",
                                                               oidcData: "oidcData",
                                                               slidingSyncVersion: .native),
                                                sessionDirectories: .init(),
                                                passphrase: "passphrase",
                                                pusherNotificationClientIdentifier: "pusherClientID")
        keychain.setRestorationToken(restorationToken, forUsername: username)
        
        // Then decoding the restoration token from the keychain should still work.
        XCTAssertEqual(keychain.restorationTokenForUsername(username), restorationToken, "The retrieved restoration token should match the value that was stored.")
    }
    
    func testAddPINCode() throws {
        // Given a keychain without a PIN code set.
        try XCTAssertFalse(keychain.containsPINCode(), "A new keychain shouldn't contain a PIN code.")
        XCTAssertNil(keychain.pinCode(), "A new keychain shouldn't return a PIN code.")
        
        // When setting a PIN code.
        try keychain.setPINCode("0000")
        
        // Then the PIN code should be stored.
        try XCTAssertTrue(keychain.containsPINCode(), "The keychain should contain the PIN code.")
        XCTAssertEqual(keychain.pinCode(), "0000", "The stored PIN code should match what was set.")
    }
    
    func testUpdatePINCode() throws {
        // Given a keychain with a PIN code already set.
        try keychain.setPINCode("0000")
        try XCTAssertTrue(keychain.containsPINCode(), "The keychain should contain the PIN code.")
        XCTAssertEqual(keychain.pinCode(), "0000", "The stored PIN code should match what was set.")
        
        // When setting a different PIN code.
        try keychain.setPINCode("1234")
        
        // Then the PIN code should be updated.
        try XCTAssertTrue(keychain.containsPINCode(), "The keychain should still contain the PIN code.")
        XCTAssertEqual(keychain.pinCode(), "1234", "The stored PIN code should match the new value.")
    }
    
    func testRemovePINCode() throws {
        // Given a keychain with a PIN code already set.
        try keychain.setPINCode("0000")
        try XCTAssertTrue(keychain.containsPINCode(), "The keychain should contain the PIN code.")
        XCTAssertEqual(keychain.pinCode(), "0000", "The stored PIN code should match what was set.")
        
        // When removing the PIN code.
        keychain.removePINCode()
        
        // Then the PIN code should no longer be stored.
        try XCTAssertFalse(keychain.containsPINCode(), "The keychain should no longer contain the PIN code.")
        XCTAssertNil(keychain.pinCode(), "There shouldn't be a stored PIN code after removing it.")
    }
    
    func testAddPINCodeBiometricState() throws {
        // Given a keychain without any biometric state.
        XCTAssertFalse(keychain.containsPINCodeBiometricState(), "A new keychain shouldn't contain biometric state.")
        XCTAssertNil(keychain.pinCodeBiometricState(), "A new keychain shouldn't return biometric state.")
        
        // When setting the state.
        let data = Data("Face ID".utf8)
        try keychain.setPINCodeBiometricState(data)
        
        // Then the state should be stored.
        XCTAssertTrue(keychain.containsPINCodeBiometricState(), "The keychain should contain the biometric state.")
        XCTAssertEqual(keychain.pinCodeBiometricState(), data, "The stored biometric state should match what was set.")
    }
    
    func testUpdatePINCodeBiometricState() throws {
        // Given a keychain that contains PIN code biometric state.
        let data = Data("😃".utf8)
        try keychain.setPINCodeBiometricState(data)
        XCTAssertTrue(keychain.containsPINCodeBiometricState(), "The keychain should contain the biometric state.")
        XCTAssertEqual(keychain.pinCodeBiometricState(), data, "The stored biometric state should match what was set.")
        
        // When setting different state.
        let newData = Data("😎".utf8)
        try keychain.setPINCodeBiometricState(newData)
        
        // Then the state should be updated.
        XCTAssertTrue(keychain.containsPINCodeBiometricState(), "The keychain should still contain biometric state.")
        XCTAssertNotEqual(keychain.pinCodeBiometricState(), data, "The stored biometric state shouldn't match the old value.")
        XCTAssertEqual(keychain.pinCodeBiometricState(), newData, "The stored biometric state should match the new value.")
    }
    
    func testRemovePINCodeBiometricState() throws {
        // Given a keychain that contains PIN code biometric state.
        let data = Data("Face ID".utf8)
        try keychain.setPINCodeBiometricState(data)
        XCTAssertTrue(keychain.containsPINCodeBiometricState(), "The keychain should contain the biometric state.")
        XCTAssertEqual(keychain.pinCodeBiometricState(), data, "The stored biometric state should match what was set.")
        
        // When removing the state.
        keychain.removePINCodeBiometricState()
        
        // Then the state should no longer be stored.
        XCTAssertFalse(keychain.containsPINCodeBiometricState(), "The keychain should no longer contain the biometric state.")
        XCTAssertNil(keychain.pinCodeBiometricState(), "There shouldn't be any stored biometric state after removing it.")
    }
}
