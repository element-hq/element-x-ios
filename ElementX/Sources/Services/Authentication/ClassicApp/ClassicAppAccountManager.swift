//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class ClassicAppAccountManager {
    static let matrixKitFolder = "MatrixKit"
    static let kMXKAccountsKey = "accountsV2"
    static let kMXFileStoreFolder = "MXFileStore"
    static let kMXFileStoreUsersFolder = "users"
    static let cryptoStoreFolder = "MXCryptoStore"
    
    let cacheFolder: URL
    let iv: Data
    let aesKey: Data
    
    private(set) var accounts: [ClassicAppMXAccount] = []
    private var users: [String: ClassicAppMXUser] = [:]
    
    var activeAccounts: [ClassicAppAccount] {
        accounts
            .filter { !$0.isDisabled && !$0.isSoftLogout }
            .compactMap(activeAccount)
    }
    
    init(cacheFolder: URL, iv: Data, aesKey: Data) {
        self.cacheFolder = cacheFolder
        self.iv = iv
        self.aesKey = aesKey
    }
    
    /// Return the path of the file containing stored MXAccounts array
    func accountFile() -> URL {
        cacheFolder.appending(component: Self.matrixKitFolder).appending(component: Self.kMXKAccountsKey)
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
                decoder.setClass(ClassicAppMXThirdPartyIdentifier.self, forClassName: "MXThirdPartyIdentifier")
                decoder.setClass(ClassicAppMXDevice.self, forClassName: "MXDevice")
                
                guard let accounts = decoder.decodeObject(forKey: "mxAccounts") as? [ClassicAppMXAccount] else {
                    MXLog.error("Failed to decode accounts.")
                    return
                }
                
                self.accounts = accounts
                
                MXLog.info("[MXKAccountManager] loadAccounts. \(accounts.count) accounts loaded in \(Date().timeIntervalSince(startDate) * 1000)ms")
            } catch {
                MXLog.error("Failed to load account file: \(error)")
            }
            
            for account in activeAccounts {
                if let user = loadUsers([account.userID], forAccount: account.userID).first {
                    users[user.userID] = user
                }
            }
        }
        
        if accounts.isEmpty {
            MXLog.info("[MXKAccountManager] loadAccounts. No accounts")
        }
    }
    
    /// From `MXCryptoMachineStore`
    func cryptoStoreURL(for userID: String) -> URL {
        cacheFolder.appending(component: Self.cryptoStoreFolder).appending(component: userID)
    }
    
    var fileStorePath: URL {
        cacheFolder.appending(component: Self.kMXFileStoreFolder)
    }
    
    func storePath(for userID: String) -> URL {
        fileStorePath.appending(component: userID)
    }
    
    /// This store contains all of the users known to the specific user ID.
    func storeUsersPath(for userID: String) -> URL {
        storePath(for: userID).appending(component: Self.kMXFileStoreUsersFolder)
    }
    
    func loadUsers(_ userIDs: [String], forAccount accountUserID: String) -> [ClassicAppMXUser] {
        // Determine which groups to load based on userIds
        var groups: [String: [String]] = [:]
        for userID in userIDs {
            let groupID = String(userID.hash % 100)
            
            if groups[groupID] != nil {
                groups[groupID]?.append(userID)
            } else {
                groups[groupID] = [userID]
            }
        }
        
        let usersFolder = storeUsersPath(for: accountUserID)
        
        var loadedUsers: [ClassicAppMXUser] = []
        for group in groups.keys {
            autoreleasepool {
                let groupFile = usersFolder.appendingPathComponent(group)
                
                // Load stored users in this group
                do {
                    let fileContent = try Data(contentsOf: groupFile)
                    
                    let decoder = NSKeyedUnarchiver(forReadingWith: fileContent)
                    decoder.setClass(ClassicAppMXUser.self, forClassName: "MXUser")
                    decoder.setClass(ClassicAppMXUser.self, forClassName: "MXMyUser")
                    
                    if let groupUsers = decoder.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? [String: ClassicAppMXUser] {
                        let usersToLoad = Set(groups[group] ?? [])
                        for user in groupUsers.values where usersToLoad.contains(user.userID) {
                            loadedUsers.append(user)
                        }
                    }
                } catch {
                    MXLog.warning("[MXFileStore] Warning: MXFileRoomStore file for users group \(group) has been corrupted")
                }
            }
        }
        
        return loadedUsers
    }
    
    private func activeAccount(mxAccount: ClassicAppMXAccount) -> ClassicAppAccount? {
        guard let userID = mxAccount.credentials.userID, let serverName = serverName(for: userID) else {
            return nil
        }
        
        return ClassicAppAccount(userID: userID,
                                 displayName: users[userID]?.displayName,
                                 serverName: serverName,
                                 cryptoStoreURL: cryptoStoreURL(for: userID))
    }
    
    /// The server name extracted from the user's ID.
    private func serverName(for userID: String) -> String? {
        #warning("Expose a serverName method for this from the SDK?")
        let components = userID.components(separatedBy: ":")
        guard components.count > 1 else { return nil }
        return components[1] // Directly use [1] as .last may be the port number.
    }
}

// MARK: - Probably not needed

private extension ClassicAppAccountManager {
    func loadUsers(forAccount accountUserID: String) {
        let startDate = Date()
        var users: [String: ClassicAppMXUser] = [:]
        
        // Load all users which are distributed in several files
        let storeUsersPath = storeUsersPath(for: accountUserID)
        let groups = try? FileManager.default.contentsOfDirectory(atPath: storeUsersPath.path(percentEncoded: false))
        
        if let groups {
            for group in groups {
                let groupFile = storeUsersPath.appending(path: group)
                
                // Load stored users in this group
                do {
                    let fileContent = try Data(contentsOf: groupFile)
                    
                    let decoder = NSKeyedUnarchiver(forReadingWith: fileContent)
                    decoder.setClass(ClassicAppMXUser.self, forClassName: "MXUser")
                    decoder.setClass(ClassicAppMXUser.self, forClassName: "MXMyUser")
                    
                    if let groupUsers = decoder.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? [String: ClassicAppMXUser] {
                        // Append them
                        users.merge(groupUsers) { _, new in new }
                    }
                } catch {
                    MXLog.error("Failed to load users from group \(group): \(error)")
                }
            }
        }
        
        MXLog.debug("[MXFileStore] Loaded \(users.count) MXUsers in \(Date().timeIntervalSince(startDate) * 1000)ms")
        
        self.users = users
    }
}
