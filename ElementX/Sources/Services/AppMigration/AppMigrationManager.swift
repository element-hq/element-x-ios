//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import KeychainAccess
import MatrixRustSDK

protocol AppMigrationManagerProtocol {
    func loadClassicAppAccounts() throws -> [ClassicAppAccount]
}

final class AppMigrationManager: AppMigrationManagerProtocol {
    private enum KeychainKeys: String {
        case cryptoSDKStoreKey
        case accountIV = "accountIv"
        case accountAESKey = "accountAesKey"
    }
    
    private let classicAppAccessGroup: String
    private let keychain: Keychain
    
    init(classicAppBundleIdentifier: String, classicAppAccessGroup: String) {
        self.classicAppAccessGroup = classicAppAccessGroup
        #warning("Developer ID")
        keychain = Keychain(service: "\(classicAppBundleIdentifier).encryption-manager-service",
                            accessGroup: "7J4U792NQT.\(classicAppBundleIdentifier).keychain.shared")
    }
    
    func loadClassicAppAccounts() throws -> [ClassicAppAccount] {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: classicAppAccessGroup) else {
            MXLog.error("The Classic App's app group identifier isn't valid: \(classicAppAccessGroup)")
            return []
        }
        
        guard let accountIV = try keychain.getData(KeychainKeys.accountIV.rawValue),
              let accountAESKey = try keychain.getData(KeychainKeys.accountAESKey.rawValue) else {
            MXLog.error("The Classic App's account keys aren't available in the keychain.")
            return []
        }
        
        let storePassphrase = try keychain.getData(KeychainKeys.cryptoSDKStoreKey.rawValue)
        
        let accountManager = ClassicAppAccountManager(cacheFolder: url, iv: accountIV, aesKey: accountAESKey)
        accountManager.loadAccounts()
        MXLog.dev("Loaded accounts: \(accountManager.accounts.compactMap(\.credentials.userID).formatted(.list(type: .and)))")
        MXLog.dev("Active accounts: \(accountManager.activeAccounts.compactMap(\.userID).formatted(.list(type: .and)))")
        
        for account in accountManager.activeAccounts {
            let storeDirectory = accountManager.storePath(for: account.userID)
            let contents = try? FileManager.default.contentsOfDirectory(at: storeDirectory, includingPropertiesForKeys: nil)
            MXLog.dev("Store contents for \(account.userID): \(String(describing: contents))")
            let cryptoStoreDirectory = accountManager.cryptoStoreURL(for: account.userID)
            let cryptoContents = try? FileManager.default.contentsOfDirectory(at: cryptoStoreDirectory, includingPropertiesForKeys: nil)
            MXLog.dev("Crypto store contents for \(account.userID): \(String(describing: cryptoContents))")
        }
        
        return accountManager.activeAccounts
    }
}
