//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import KeychainAccess
import MatrixRustSDK

protocol ClassicAppManagerProtocol {
    func loadAccounts() throws -> [ClassicAppAccount]
}

enum ClassicAppManagerError: Error {
    case invalidAppGroupIdentifier(String)
    case missingAccountKeys
    case missingCryptoStorePassphrase
}

/// Reads accounts from Element Classic's shared storage.
final class ClassicAppManager: ClassicAppManagerProtocol {
    private enum KeychainKeys: String {
        case cryptoSDKStoreKey
        case accountIV = "accountIv"
        case accountAESKey = "accountAesKey"
    }
    
    private let classicAppGroupIdentifier: String
    private let keychain: Keychain
    
    /// Creates an instance using the Classic app identifiers specified in the `Info.plist` file.
    /// Returns `nil` when a Classic app has not been configured in the project.
    init?(classicAppGroupIdentifier: String? = InfoPlistReader.main.classicAppGroupIdentifier,
          classicAppKeychainServiceIdentifier: String? = InfoPlistReader.main.classicAppKeychainServiceIdentifier,
          classicAppKeychainAccessGroupIdentifier: String? = InfoPlistReader.main.classicAppKeychainAccessGroupIdentifier) {
        guard let classicAppGroupIdentifier, let classicAppKeychainServiceIdentifier, let classicAppKeychainAccessGroupIdentifier else {
            MXLog.info("Classic App IDs not available, skipping initialisation.")
            return nil
        }
        
        self.classicAppGroupIdentifier = classicAppGroupIdentifier
        keychain = Keychain(service: classicAppKeychainServiceIdentifier, accessGroup: classicAppKeychainAccessGroupIdentifier)
    }
    
    /// Loads all of the active accounts from the Classic app.
    func loadAccounts() throws -> [ClassicAppAccount] {
        // The account data is stored in the App Group container.
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: classicAppGroupIdentifier) else {
            throw ClassicAppManagerError.invalidAppGroupIdentifier(classicAppGroupIdentifier)
        }
        
        // And the data is encrypted with keys that are stored in the Keychain.
        guard let accountIV = try keychain.getData(KeychainKeys.accountIV.rawValue),
              let accountAESKey = try keychain.getData(KeychainKeys.accountAESKey.rawValue) else {
            throw ClassicAppManagerError.missingAccountKeys
        }
        
        guard let cryptoStorePassphrase = try keychain.getData(KeychainKeys.cryptoSDKStoreKey.rawValue) else {
            throw ClassicAppManagerError.missingCryptoStorePassphrase
        }
        
        let accountManager = ClassicAppAccountManager(cacheFolder: url,
                                                      aesKey: accountAESKey,
                                                      iv: accountIV,
                                                      cryptoStorePassphrase: cryptoStorePassphrase)
        accountManager.loadAccounts()
        return accountManager.accounts
    }
}
