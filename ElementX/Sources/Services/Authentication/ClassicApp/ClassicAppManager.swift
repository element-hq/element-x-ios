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

final class ClassicAppManager: ClassicAppManagerProtocol {
    private enum KeychainKeys: String {
        case cryptoSDKStoreKey
        case accountIV = "accountIv"
        case accountAESKey = "accountAesKey"
    }
    
    private let classicAppGroupIdentifier: String
    private let keychain: Keychain
    
    init(classicAppGroupIdentifier: String, classicAppKeychainServiceIdentifier: String, classicAppKeychainAccessGroupIdentifier: String) {
        self.classicAppGroupIdentifier = classicAppGroupIdentifier
        keychain = Keychain(service: classicAppKeychainServiceIdentifier, accessGroup: classicAppKeychainAccessGroupIdentifier)
    }
    
    func loadAccounts() throws -> [ClassicAppAccount] {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: classicAppGroupIdentifier) else {
            throw ClassicAppManagerError.invalidAppGroupIdentifier(classicAppGroupIdentifier)
        }
        
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
