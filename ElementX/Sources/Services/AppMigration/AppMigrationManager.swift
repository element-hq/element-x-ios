//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import KeychainAccess
import MatrixRustSDK

protocol AppMigrationManagerProtocol { }

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
    
    func test() throws {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: classicAppAccessGroup) else {
            return
        }
        
        let storePassphrase = try keychain.getData(KeychainKeys.cryptoSDKStoreKey.rawValue)
        let accountIV = try keychain.getData(KeychainKeys.accountIV.rawValue)
        let accountAES = try keychain.getData(KeychainKeys.accountAESKey.rawValue)
        
        if let accountIV, let accountAES {
            let accountManager = AccountManager(cacheFolder: url, iv: accountIV, aesKey: accountAES)
            accountManager.loadAccounts()
            MXLog.dev("Loaded accounts: \(accountManager.mxAccounts.compactMap(\.mxCredentials.userId).formatted(.list(type: .and)))")
            MXLog.dev("Active accounts: \(accountManager.activeAccounts.compactMap(\.mxCredentials.userId).formatted(.list(type: .and)))")
            
            for account in accountManager.activeAccounts {
                let storeDirectory = accountManager.storePath(for: account.mxCredentials)
                let contents = try? FileManager.default.contentsOfDirectory(at: storeDirectory, includingPropertiesForKeys: nil)
                MXLog.dev("Store contents for \(account.mxCredentials.userId ?? "unknown"): \(String(describing: contents))")
                let cryptoStoreDirectory = accountManager.cryptoStoreURL(for: account.mxCredentials)
                let cryptoContents = try? FileManager.default.contentsOfDirectory(at: cryptoStoreDirectory, includingPropertiesForKeys: nil)
                MXLog.dev("Crypto store contents for \(account.mxCredentials.userId ?? "unknown"): \(String(describing: cryptoContents))")
            }
        }
    }
}
