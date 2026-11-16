//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import KeychainAccess
import Testing

struct KeychainControllerTests {
    var keychain: KeychainController
    
    init() {
        keychain = KeychainController(service: .tests,
                                      accessGroup: InfoPlistReader.main.keychainAccessGroupIdentifier)
        keychain.removeAllRestorationTokens()
        keychain.resetSecrets()
    }
    
    @Test("A restoration token can be stored and retrieved")
    func addRestorationToken() {
        // Given an empty keychain.
        #expect(keychain.restorationTokens().isEmpty, "The keychain should be empty to begin with.")
        
        // When adding an restoration token.
        let username = "@test:example.com"
        let restorationToken = RestorationToken.mock()
        keychain.setRestorationToken(restorationToken, forUsername: username)
        
        // Then the restoration token should be stored in the keychain.
        #expect(keychain.restorationTokenForUsername(username) == restorationToken, "The retrieved restoration token should match the value that was stored.")
    }
    
    @Test("Removing the only restoration token empties the keychain")
    func removingRestorationToken() {
        // Given a keychain with a stored restoration token.
        let username = "@test:example.com"
        let restorationToken = RestorationToken.mock()
        keychain.setRestorationToken(restorationToken, forUsername: username)
        #expect(keychain.restorationTokens().count == 1, "The keychain should have 1 restoration token.")
        #expect(keychain.restorationTokenForUsername(username) == restorationToken, "The initial restoration token should match the value that was stored.")
        
        // When deleting the restoration token.
        keychain.removeRestorationTokenForUsername(username)
        
        // Then the keychain should be empty.
        #expect(keychain.restorationTokens().isEmpty, "The keychain should be empty after deleting the token.")
        #expect(keychain.restorationTokenForUsername(username) == nil, "There restoration token should not be returned after removal.")
    }
    
    @Test("All restoration tokens can be removed at once")
    func removingAllRestorationTokens() {
        // Given a keychain with 5 stored restoration tokens.
        for index in 0..<5 {
            keychain.setRestorationToken(.mock(), forUsername: "@test\(index):example.com")
        }
        #expect(keychain.restorationTokens().count == 5, "The keychain should have 5 restoration tokens.")
        
        // When deleting all of the restoration tokens.
        keychain.removeAllRestorationTokens()
        
        // Then the keychain should be empty.
        #expect(keychain.restorationTokens().isEmpty, "The keychain should be empty after deleting the token.")
    }
    
    @Test("Removing one restoration token leaves the others untouched")
    func removingSingleRestorationTokens() {
        // Given a keychain with 5 stored restoration tokens.
        for index in 0..<5 {
            keychain.setRestorationToken(.mock(), forUsername: "@test\(index):example.com")
        }
        #expect(keychain.restorationTokens().count == 5, "The keychain should have 5 restoration tokens.")
        
        // When deleting one of the restoration tokens.
        keychain.removeRestorationTokenForUsername("@test2:example.com")
        
        // Then the other 4 items should remain untouched.
        #expect(keychain.restorationTokens().count == 4, "The keychain have 4 remaining restoration tokens.")
        #expect(keychain.restorationTokenForUsername("@test0:example.com") != nil, "The restoration token should not have been deleted.")
        #expect(keychain.restorationTokenForUsername("@test1:example.com") != nil, "The restoration token should not have been deleted.")
        #expect(keychain.restorationTokenForUsername("@test2:example.com") == nil, "The restoration token should have been deleted.")
        #expect(keychain.restorationTokenForUsername("@test3:example.com") != nil, "The restoration token should not have been deleted.")
        #expect(keychain.restorationTokenForUsername("@test4:example.com") != nil, "The restoration token should not have been deleted.")
    }
    
    @Test("An unsupported restoration token is removed when retrieved")
    func unsupportedRestorationToken() throws {
        // Given a keychain with an unsupported restoration token with a sliding sync proxy URL value.
        let underlyingKeychain = Keychain(service: KeychainControllerService.tests.restorationTokenID,
                                          accessGroup: InfoPlistReader.main.keychainAccessGroupIdentifier)
        // Note: We assert with this underlying keychain's keys as keychain.restorationTokens() triggers the deletion that we're testing.
        #expect(underlyingKeychain.allKeys().isEmpty, "The keychain should be empty to begin with.")
        
        let unsupportedToken = RestorationTokenV4(session: SessionV1(accessToken: "1234",
                                                                     refreshToken: nil,
                                                                     userId: "@test:example.com",
                                                                     deviceId: "D3V1C3",
                                                                     homeserverUrl: "https://matrix.example.com",
                                                                     oidcData: nil,
                                                                     slidingSyncVersion: .proxy(url: "https://sync.example.com")),
                                                  sessionDirectory: .sessionsBaseDirectory.appending(component: UUID().uuidString),
                                                  passphrase: RestorationTokenFixtures.base64Passphrase,
                                                  pusherNotificationClientIdentifier: "pusherClientID")
        let tokenData = try JSONEncoder().encode(unsupportedToken)
        try underlyingKeychain.set(tokenData, key: "@test:example.com")
        #expect(underlyingKeychain.allKeys().count == 1)
        
        // When attempting to retrieve the unsupported token.
        let retrievedToken = keychain.restorationTokenForUsername("@test:example.com")
        
        // Then nothing should be returned and the restoration token should be automatically removed.
        #expect(retrievedToken == nil, "The token should not be decoded.")
        #expect(underlyingKeychain.allKeys().isEmpty, "The keychain should be empty again.")
    }
    
    @Test("The homeservers of the stored sessions are collected once each")
    func collectSessionHomeservers() {
        // Given a keychain with two accounts on one homeserver and another account on a different homeserver.
        keychain.setRestorationToken(.mock(homeserverURL: "https://matrix.example.com"), forUsername: "@alice:example.com")
        keychain.setRestorationToken(.mock(homeserverURL: "https://matrix.example.com"), forUsername: "@bob:example.com")
        keychain.setRestorationToken(.mock(homeserverURL: "https://matrix.other.com"), forUsername: "@carol:other.com")
        
        // When getting the homeservers of the restoration tokens.
        let homeservers = keychain.collectSessionHomeservers()
        
        // Then each homeserver should be returned once.
        #expect(homeservers == ["https://matrix.example.com", "https://matrix.other.com"])
    }
    
    @Test("Unsupported restoration tokens are skipped without being removed when collecting session homeservers")
    func collectSessionHomeserversWithUnsupportedToken() throws {
        // Given a keychain with a supported restoration token and an unsupported one with a sliding sync proxy URL value.
        let underlyingKeychain = Keychain(service: KeychainControllerService.tests.restorationTokenID,
                                          accessGroup: InfoPlistReader.main.keychainAccessGroupIdentifier)
        keychain.setRestorationToken(.mock(homeserverURL: "https://matrix.example.com"), forUsername: "@alice:example.com")
        
        let unsupportedToken = RestorationTokenV4(session: SessionV1(accessToken: "1234",
                                                                     refreshToken: nil,
                                                                     userId: "@test:other.com",
                                                                     deviceId: "D3V1C3",
                                                                     homeserverUrl: "https://matrix.other.com",
                                                                     oidcData: nil,
                                                                     slidingSyncVersion: .proxy(url: "https://sync.other.com")),
                                                  sessionDirectory: .sessionsBaseDirectory.appending(component: UUID().uuidString),
                                                  passphrase: RestorationTokenFixtures.base64Passphrase,
                                                  pusherNotificationClientIdentifier: "pusherClientID")
        try underlyingKeychain.set(JSONEncoder().encode(unsupportedToken), key: "@test:other.com")
        #expect(underlyingKeychain.allKeys().count == 2)
        
        // When getting the homeservers of the restoration tokens.
        let homeservers = keychain.collectSessionHomeservers()
        
        // Then only the supported token's homeserver should be returned, leaving the unsupported token in place.
        #expect(homeservers == ["https://matrix.example.com"])
        #expect(underlyingKeychain.allKeys().count == 2, "The unsupported token should only be removed once it can be logged.")
    }
    
    @Test("A PIN code can be stored and retrieved")
    func addPINCode() throws {
        // Given a keychain without a PIN code set.
        #expect(try !keychain.containsPINCode(), "A new keychain shouldn't contain a PIN code.")
        #expect(keychain.pinCode() == nil, "A new keychain shouldn't return a PIN code.")
        
        // When setting a PIN code.
        try keychain.setPINCode("0000")
        
        // Then the PIN code should be stored.
        #expect(try keychain.containsPINCode(), "The keychain should contain the PIN code.")
        #expect(keychain.pinCode() == "0000", "The stored PIN code should match what was set.")
    }
    
    @Test("Setting a new PIN code replaces the old one")
    func updatePINCode() throws {
        // Given a keychain with a PIN code already set.
        try keychain.setPINCode("0000")
        #expect(try keychain.containsPINCode(), "The keychain should contain the PIN code.")
        #expect(keychain.pinCode() == "0000", "The stored PIN code should match what was set.")
        
        // When setting a different PIN code.
        try keychain.setPINCode("1234")
        
        // Then the PIN code should be updated.
        #expect(try keychain.containsPINCode(), "The keychain should still contain the PIN code.")
        #expect(keychain.pinCode() == "1234", "The stored PIN code should match the new value.")
    }
    
    @Test("A PIN code can be removed")
    func removePINCode() throws {
        // Given a keychain with a PIN code already set.
        try keychain.setPINCode("0000")
        #expect(try keychain.containsPINCode(), "The keychain should contain the PIN code.")
        #expect(keychain.pinCode() == "0000", "The stored PIN code should match what was set.")
        
        // When removing the PIN code.
        keychain.removePINCode()
        
        // Then the PIN code should no longer be stored.
        #expect(try !keychain.containsPINCode(), "The keychain should no longer contain the PIN code.")
        #expect(keychain.pinCode() == nil, "There shouldn't be a stored PIN code after removing it.")
    }
    
    @Test("PIN code biometric state can be stored and retrieved")
    func addPINCodeBiometricState() throws {
        // Given a keychain without any biometric state.
        #expect(!keychain.containsPINCodeBiometricState(), "A new keychain shouldn't contain biometric state.")
        #expect(keychain.pinCodeBiometricState() == nil, "A new keychain shouldn't return biometric state.")
        
        // When setting the state.
        let data = Data("Face ID".utf8)
        try keychain.setPINCodeBiometricState(data)
        
        // Then the state should be stored.
        #expect(keychain.containsPINCodeBiometricState(), "The keychain should contain the biometric state.")
        #expect(keychain.pinCodeBiometricState() == data, "The stored biometric state should match what was set.")
    }
    
    @Test("Setting new PIN code biometric state replaces the old state")
    func updatePINCodeBiometricState() throws {
        // Given a keychain that contains PIN code biometric state.
        let data = Data("😃".utf8)
        try keychain.setPINCodeBiometricState(data)
        #expect(keychain.containsPINCodeBiometricState(), "The keychain should contain the biometric state.")
        #expect(keychain.pinCodeBiometricState() == data, "The stored biometric state should match what was set.")
        
        // When setting different state.
        let newData = Data("😎".utf8)
        try keychain.setPINCodeBiometricState(newData)
        
        // Then the state should be updated.
        #expect(keychain.containsPINCodeBiometricState(), "The keychain should still contain biometric state.")
        #expect(keychain.pinCodeBiometricState() != data, "The stored biometric state shouldn't match the old value.")
        #expect(keychain.pinCodeBiometricState() == newData, "The stored biometric state should match the new value.")
    }
    
    @Test("PIN code biometric state can be removed")
    func removePINCodeBiometricState() throws {
        // Given a keychain that contains PIN code biometric state.
        let data = Data("Face ID".utf8)
        try keychain.setPINCodeBiometricState(data)
        #expect(keychain.containsPINCodeBiometricState(), "The keychain should contain the biometric state.")
        #expect(keychain.pinCodeBiometricState() == data, "The stored biometric state should match what was set.")
        
        // When removing the state.
        keychain.removePINCodeBiometricState()
        
        // Then the state should no longer be stored.
        #expect(!keychain.containsPINCodeBiometricState(), "The keychain should no longer contain the biometric state.")
        #expect(keychain.pinCodeBiometricState() == nil, "There shouldn't be any stored biometric state after removing it.")
    }
}

private extension RestorationToken {
    static func mock(homeserverURL: String = "homeserverUrl") -> RestorationToken {
        RestorationToken(session: .init(accessToken: "accessToken",
                                        refreshToken: "refreshToken",
                                        userId: "userId",
                                        deviceId: "deviceId",
                                        homeserverUrl: homeserverURL,
                                        oauthData: "oauthData",
                                        slidingSyncVersion: .native),
                         sessionDirectories: .init(),
                         passphrase: RestorationTokenFixtures.passphrase,
                         pusherNotificationClientIdentifier: "pusherClientID")
    }
}
