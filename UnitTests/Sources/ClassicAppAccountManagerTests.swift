//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

final class ClassicAppAccountManagerTests {
    let testDirectory: URL = .temporaryDirectory.appending(component: UUID().uuidString)
    let accountAESKey: Data
    let accountIV: Data
    let cryptoStorePassphrase: Data
    
    let classicAppAccountManager: ClassicAppAccountManager
    
    init() throws {
        accountAESKey = try #require(Data(base64Encoded: "BzaSCm5i8QhJr6wGBPj7MDvqBwkwuHLqkRxprVV2zJE="))
        accountIV = try #require(Data(base64Encoded: "dMmg6H2dYTRBE8PwjfAbAQ=="))
        cryptoStorePassphrase = try #require(Data(base64Encoded: "ERE/ZXw8rlY3Lv3MBG9sV9g+euOuJnrJaSuvrAMWPrI="))
        
        classicAppAccountManager = ClassicAppAccountManager(cacheFolder: testDirectory,
                                                            aesKey: accountAESKey,
                                                            iv: accountIV,
                                                            cryptoStorePassphrase: cryptoStorePassphrase)
    }
    
    @Test
    func noAccounts() {
        classicAppAccountManager.loadAccounts()
        
        #expect(classicAppAccountManager.accounts.isEmpty)
    }
    
    @Test
    func activeAccount() throws {
        let account = ClassicAppAccount.mock(classicAppAccountManager: classicAppAccountManager,
                                             cryptoStorePassphrase: cryptoStorePassphrase)
        
        try setupFixtures(for: account)
        
        classicAppAccountManager.loadAccounts()
        
        #expect(classicAppAccountManager.accounts.count == 1)
        #expect(classicAppAccountManager.accounts.first == account)
    }
    
    // MARK: - Helpers
    
    private func setupFixtures(for account: ClassicAppAccount) throws {
        let bundle = Bundle(for: Self.self)
        
        // Copy the accountsV2 file (contains the MXKAccount for the signed in user).
        let accountFileSource = try #require(bundle.url(forResource: "accountsV2", withExtension: nil))
        let accountFileDestination = classicAppAccountManager.accountFile()
        try FileManager.default.createDirectory(at: accountFileDestination.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: accountFileSource, to: accountFileDestination)
        
        // Copy the required users file (contains a subset of known MXUsers including the signed in user).
        let userFileName = "94" // UInt(bitPattern: account.userID.hash) % 100
        let userFileSource = try #require(bundle.url(forResource: userFileName, withExtension: nil))
        let usersDestination = classicAppAccountManager.storeUsersPath(for: account.userID)
        try FileManager.default.createDirectory(at: usersDestination, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: userFileSource, to: usersDestination.appending(component: userFileName))
    }
}

extension ClassicAppAccount {
    /// Creates a mock account based on the fixtures used by this test.
    static func mock(classicAppAccountManager: ClassicAppAccountManager, cryptoStorePassphrase: Data) -> ClassicAppAccount {
        let userID = "@classicappaccount:matrix.org"
        
        return ClassicAppAccount(userID: userID,
                                 displayName: "Classic App Account",
                                 avatarURL: "mxc://matrix.org/LYIzLOiILkjQJCqsgzAOUirs",
                                 serverName: "matrix.org",
                                 homeserverURL: "https://matrix-client.matrix.org",
                                 cryptoStoreURL: classicAppAccountManager.cryptoStoreURL(for: userID),
                                 cryptoStorePassphrase: cryptoStorePassphrase.base64EncodedString(),
                                 accessToken: "mct_6luZquERViQxGSXqzdxDeMpQkEjHpk_ISvHO2") // Note: Deactivated account
    }
}
