//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class AccountManager {
    static let kMXKAccountsKey = "accountsV2"
    static let kMXFileStoreFolder = "MXFileStore"
    static let cryptoStoreFolder = "MXCryptoStore"
    
    let cacheFolder: URL
    let iv: Data
    let aesKey: Data
    
    var mxAccounts: [MXKAccountData] = []
    
    var activeAccounts: [MXKAccountData] {
        mxAccounts.filter { !$0.isDisabled && !$0.isSoftLogout }
    }
    
    init(cacheFolder: URL, iv: Data, aesKey: Data) {
        self.cacheFolder = cacheFolder
        self.iv = iv
        self.aesKey = aesKey
    }
    
    /// Return the path of the file containing stored MXAccounts array
    func accountFile() -> URL {
        cacheFolder.appending(component: "MatrixKit").appending(component: Self.kMXKAccountsKey)
    }
    
    func loadAccounts() {
        MXLog.info("Loading accounts from Classic app.")
        let accountFile = accountFile()
        if FileManager.default.fileExists(atPath: accountFile.path(percentEncoded: false)) {
            let startDate = Date()
            
            do {
                let fileContent = try Data(contentsOf: accountFile, options: [.alwaysMapped, .uncached])
                
                // Decrypt data if encryption method is provided
                let unciphered = try MXAES.decrypt(fileContent, aesKey: aesKey, iv: iv)
                let decoder = NSKeyedUnarchiver(forReadingWith: unciphered)
                decoder.setClass(MXKAccountData.self, forClassName: "MXKAccount")
                decoder.setClass(MXThirdPartyIdentifier.self, forClassName: "MXThirdPartyIdentifier")
                decoder.setClass(MXDevice.self, forClassName: "MXDevice")
                
                guard let accounts = decoder.decodeObject(forKey: "mxAccounts") as? [MXKAccountData] else {
                    MXLog.error("Failed to decode accounts.")
                    return
                }
                
                mxAccounts = accounts
                
                MXLog.info("[MXKAccountManager] loadAccounts. \(mxAccounts.count) accounts loaded in \(Date().timeIntervalSince(startDate) * 1000)ms")
            } catch {
                MXLog.error("Failed to load account file: \(error)")
            }
        }
        
        if mxAccounts.isEmpty {
            MXLog.info("[MXKAccountManager] loadAccounts. No accounts")
        }
    }
    
    func storePath(for credentials: MXCredentials) -> URL {
        #warning("Nullability")
        guard let userID = credentials.userId else { fatalError() }
        return cacheFolder.appending(component: Self.kMXFileStoreFolder).appending(component: userID)
    }
    
    /// From `MXCryptoMachineStore`
    func cryptoStoreURL(for credentials: MXCredentials) -> URL {
        #warning("Nullability")
        guard let userID = credentials.userId else { fatalError() }
        return cacheFolder.appending(component: Self.cryptoStoreFolder).appending(component: userID)
    }
}
