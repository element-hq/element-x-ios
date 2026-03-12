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
        
        // First we need to load the accounts file, which contains an array of MXKAccounts (a super class of MXAccount).
        let accountFile = accountFile()
        if FileManager.default.fileExists(atPath: accountFile.path(percentEncoded: false)) {
            let startDate = Date()
            
            do {
                let fileContent = try Data(contentsOf: accountFile, options: [.alwaysMapped, .uncached])
                let unciphered = try ClassicAppAES.decrypt(fileContent, aesKey: aesKey, iv: iv)
                let decoder = try NSKeyedUnarchiver(forReadingFrom: unciphered)
                decoder.requiresSecureCoding = false
                decoder.setClass(ClassicAppMXAccount.self, forClassName: "MXKAccount")
                
                guard let mxAccounts = decoder.decodeObject(forKey: "mxAccounts") as? [ClassicAppMXAccount] else {
                    MXLog.error("Failed to decode accounts.")
                    return
                }
                
                MXLog.info("\(mxAccounts.count) accounts loaded in \(Date().timeIntervalSince(startDate) * 1000)ms.")
                
                // Only consider active accounts using the same logic as Element Classic and then
                // combine the MXAccount data with its profile and crypto store details.
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
    
    /// Combines an MXAccount with its profile and crypto store details.
    private func makeAccount(for mxAccount: ClassicAppMXAccount) -> ClassicAppAccount? {
        let userID = mxAccount.userID
        let user = loadUser(for: mxAccount) // We need an MXUser for the profile as MXAccount doesn't contain that data.
        
        guard let serverName = serverName(for: userID) else { return nil }
        
        return ClassicAppAccount(userID: userID,
                                 displayName: user?.displayName,
                                 avatarURL: user?.avatarURL.flatMap(URL.init(string:)),
                                 serverName: serverName,
                                 cryptoStoreURL: cryptoStoreURL(for: userID),
                                 cryptoStorePassphrase: cryptoStorePassphrase)
    }
    
    private func loadUser(for mxAccount: ClassicAppMXAccount) -> ClassicAppMXUser? {
        // Users are stored across multiple files, so first find the right file for this particular user.
        let userID = mxAccount.userID
        let groupID = String(UInt(bitPattern: userID.hash) % 100) // Swift's .hash is Int whereas Objective-C's is UInt.
        let groupFile = storeUsersPath(for: userID).appending(component: groupID)
        
        guard FileManager.default.fileExists(atPath: groupFile.path(percentEncoded: false)) else {
            MXLog.warning("Missing users group \(groupID) file for \(mxAccount.userID).")
            return nil
        }
        
        do {
            // And then load that file and find the user within its data.
            let fileContent = try Data(contentsOf: groupFile)
            let decoder = try NSKeyedUnarchiver(forReadingFrom: fileContent)
            decoder.requiresSecureCoding = false
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
    func accountFile() -> URL {
        cacheFolder.appending(component: Self.matrixKitFolder).appending(component: Self.kMXKAccountsKey)
    }
    
    /// The database file URL as defined in `MXCryptoMachineStore`.
    func cryptoStoreURL(for userID: String) -> URL {
        cacheFolder.appending(component: Self.cryptoStoreFolder).appending(component: userID)
    }
    
    /// This store contains all of the users known to the specific user ID.
    func storeUsersPath(for userID: String) -> URL {
        storePath(for: userID).appending(component: Self.kMXFileStoreUsersFolder)
    }
    
    private func storePath(for userID: String) -> URL {
        fileStorePath.appending(component: userID)
    }
    
    private var fileStorePath: URL {
        cacheFolder.appending(component: Self.kMXFileStoreFolder)
    }
}
