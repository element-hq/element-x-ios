//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class ClassicAppAccountManager {
    private let cacheFolder: URL
    private let aesKey: Data
    private let iv: Data
    private let cryptoStorePassphrase: Data
    
    private(set) var accounts: [ClassicAppAccount] = []
    
    init(cacheFolder: URL, aesKey: Data, iv: Data, cryptoStorePassphrase: Data) {
        self.cacheFolder = cacheFolder
        self.aesKey = aesKey
        self.iv = iv
        self.cryptoStorePassphrase = cryptoStorePassphrase
    }
    
    func loadAccounts() {
        MXLog.info("Loading accounts from Classic app.")
        
        let accountFile = accountFile()
        if FileManager.default.fileExists(atPath: accountFile.path(percentEncoded: false)) {
            let startDate = Date()
            
            do {
                let fileContent = try Data(contentsOf: accountFile, options: [.alwaysMapped, .uncached])
                
                // Decrypt data if encryption method is provided
                let unciphered = try ClassicAppAES.decrypt(fileContent, aesKey: aesKey, iv: iv)
                let decoder = NSKeyedUnarchiver(forReadingWith: unciphered)
                decoder.setClass(ClassicAppMXAccount.self, forClassName: "MXKAccount")
                
                guard let mxAccounts = decoder.decodeObject(forKey: "mxAccounts") as? [ClassicAppMXAccount] else {
                    MXLog.error("Failed to decode accounts.")
                    return
                }
                
                MXLog.info("\(mxAccounts.count) accounts loaded in \(Date().timeIntervalSince(startDate) * 1000)ms.")
                
                accounts = mxAccounts
                    .filter(\.isActive)
                    .compactMap(makeAccount)
                
                MXLog.info("\(mxAccounts.count) active accounts available.")
            } catch {
                MXLog.error("Failed to load account file: \(error)")
            }
        }
    }
    
    // MARK: - Private
    
    private func makeAccount(for mxAccount: ClassicAppMXAccount) -> ClassicAppAccount? {
        let userID = mxAccount.userID
        let user = loadUser(for: mxAccount)
        
        guard let serverName = serverName(for: userID) else { return nil }
        
        return ClassicAppAccount(userID: userID,
                                 displayName: user?.displayName,
                                 avatarURL: user?.avatarURL.flatMap(URL.init(string:)),
                                 serverName: serverName,
                                 cryptoStoreURL: cryptoStoreURL(for: userID),
                                 cryptoStorePassphrase: cryptoStorePassphrase)
    }
    
    private func loadUser(for mxAccount: ClassicAppMXAccount) -> ClassicAppMXUser? {
        let userID = mxAccount.userID
        let groupID = String(userID.hash % 100)
        let groupFile = storeUsersPath(for: userID).appendingPathComponent(groupID)
        
        do {
            let fileContent = try Data(contentsOf: groupFile)
            let decoder = NSKeyedUnarchiver(forReadingWith: fileContent)
            decoder.setClass(ClassicAppMXUser.self, forClassName: "MXUser")
            decoder.setClass(ClassicAppMXUser.self, forClassName: "MXMyUser")
            
            let groupUsers = decoder.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? [String: ClassicAppMXUser]
            return groupUsers?[userID]
        } catch {
            MXLog.warning("Users group \(groupID) file for \(mxAccount.userID) has been corrupted.")
            return nil
        }
    }
    
    /// The server name extracted from the user's ID.
    private func serverName(for userID: String) -> String? {
        #warning("Expose a serverName method for this from the SDK?")
        let components = userID.components(separatedBy: ":")
        guard components.count > 1 else { return nil }
        return components[1] // Directly use [1] as .last may be the port number.
    }
    
    // MARK: - File URLs
    
    private static let matrixKitFolder = "MatrixKit"
    private static let cryptoStoreFolder = "MXCryptoStore"
    private static let kMXKAccountsKey = "accountsV2"
    private static let kMXFileStoreFolder = "MXFileStore"
    private static let kMXFileStoreUsersFolder = "users"
    
    /// The file URL that contains the app's `MXAccounts` array.
    private func accountFile() -> URL {
        cacheFolder.appending(component: Self.matrixKitFolder).appending(component: Self.kMXKAccountsKey)
    }
    
    /// The database file URL as defined in `MXCryptoMachineStore`.
    private func cryptoStoreURL(for userID: String) -> URL {
        cacheFolder.appending(component: Self.cryptoStoreFolder).appending(component: userID)
    }
    
    /// This store contains all of the users known to the specific user ID.
    private func storeUsersPath(for userID: String) -> URL {
        storePath(for: userID).appending(component: Self.kMXFileStoreUsersFolder)
    }
    
    private func storePath(for userID: String) -> URL {
        fileStorePath.appending(component: userID)
    }
    
    private var fileStorePath: URL {
        cacheFolder.appending(component: Self.kMXFileStoreFolder)
    }
}
