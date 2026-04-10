//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import KeychainAccess
import MatrixRustSDK

// sourcery: AutoMockable
protocol ClassicAppManagerProtocol {
    /// Loads all of the accounts found in the Classic app's file store.
    func loadAccounts() throws -> [ClassicAppAccount]
    /// Determines which secrets will be available when loading the secrets bundle for a given account.
    func availableSecrets(for account: ClassicAppAccount) async throws -> ClassicAppAccount.AvailableSecrets
    /// Loads the secrets bundle for a given account.
    func secretsBundle(for account: ClassicAppAccount) async throws -> SecretsBundleWithUserId
}

enum ClassicAppManagerError: Error {
    case invalidAppGroupIdentifier(String)
    case missingAccountKeys
    case missingCryptoStorePassphrase
    case missingKeyBackupVersion
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
    
    func availableSecrets(for account: ClassicAppAccount) async throws -> ClassicAppAccount.AvailableSecrets {
        switch try await databaseContainsSecretsBundle(databasePath: account.cryptoStoreURL.path(percentEncoded: false),
                                                       passphrase: account.cryptoStorePassphrase,
                                                       backupInfo: keyBackupVersion(for: account)) {
        case .complete: .complete
        case .none: .unavailable
        case .withoutBackup, .unusedBackup: .requiresBackup
        }
    }
    
    func secretsBundle(for account: ClassicAppAccount) async throws -> SecretsBundleWithUserId {
        guard let keyBackupVersion = try await keyBackupVersion(for: account) else {
            throw ClassicAppManagerError.missingKeyBackupVersion
        }
        
        return try await SecretsBundleWithUserId.fromDatabase(databasePath: account.cryptoStoreURL.path(percentEncoded: false),
                                                              passphrase: account.cryptoStorePassphrase,
                                                              backupInfo: keyBackupVersion)
    }
    
    /// Fetches the current key backup version from the homeserver. This is needed to determine whether
    /// the backup key from the crypto store is for the backup currently being used by the account.
    private func keyBackupVersion(for account: ClassicAppAccount) async throws -> String? {
        let url = account.homeserverURL.appending(path: "_matrix/client/v3/room_keys/version")
        var request = URLRequest(url: url)
        request.setValue("Bearer \(account.accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 200 {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
}
