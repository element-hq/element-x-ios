//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum UserSessionStoreError: Error {
    case missingCredentials
    case failedRestoringLogin
    case failedSettingUpSession
}

protocol UserSessionStoreProtocol {
    /// Deletes all data stored in the shared container and keychain
    func reset()
    
    /// Whether or not there are sessions in the store.
    var hasSessions: Bool { get }
    
    /// All the user IDs managed by the store.
    var userIDs: [String] { get }
    
    /// Returns the delegate that should handle any changes to a `Client`'s `Session`.
    var clientSessionDelegate: ClientSessionDelegate { get }
    
    /// Restores an existing user session.
    func restoreUserSession() async -> Result<UserSessionProtocol, UserSessionStoreError>
    
    /// Creates a user session for a new client from the SDK along with the passphrase used for the data stores.
    func userSession(for client: Client, sessionDirectories: SessionDirectories, passphrase: String?) async -> Result<UserSessionProtocol, UserSessionStoreError>
    
    /// Logs out of the specified session.
    func logout(userSession: UserSessionProtocol)
    
    /// Clears our all the matrix sdk state data for the specified session
    func clearCache(for userID: String)
}
