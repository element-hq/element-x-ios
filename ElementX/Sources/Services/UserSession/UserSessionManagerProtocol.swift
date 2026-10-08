//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

enum UserSessionManagerError: Error {
    /// There are no signed in accounts to restore.
    case noAccounts
    /// The account couldn't be restored, so it has been removed.
    case failedRestoringSession
    /// None of the signed in accounts could be restored, so they have all been removed.
    case failedRestoringSessions
}

// sourcery: AutoMockable
protocol UserSessionManagerProtocol: AnyObject {
    /// Every signed in account, most recently active first. Known before any session is live, so use it to count accounts.
    var userIDs: [String] { get }
    /// The live sessions, in the same order as `userIDs`.
    var sessionsPublisher: CurrentValuePublisher<[UserSessionProtocol], Never> { get }
    /// The session of the account whose UI is on screen.
    var activeSession: UserSessionProtocol? { get }
    /// The delegate that stores changes to a client's session, such as refreshed tokens.
    var clientSessionDelegate: ClientSessionDelegate { get }
    
    func session(for userID: String) -> UserSessionProtocol?
    
    // MARK: - Lifecycle
    
    /// Restores the most recently active account, falling back to the next one when it fails (the store deletes failed accounts).
    ///
    /// The session isn't registered: `add` it once it's ready to be used, e.g. after any migrations.
    func restoreActiveSession() async -> Result<UserSessionProtocol, UserSessionManagerError>
    /// Restores an account's session, removing the account when that fails (the store deletes its data).
    ///
    /// The session isn't registered: `add` it once it's ready to be used, e.g. after any migrations.
    func restoreUserSession(userID: String) async -> Result<UserSessionProtocol, UserSessionManagerError>
    /// Creates the session of an account that has just signed in, and stores its credentials.
    ///
    /// The session isn't registered: `add` it once it's ready to be used.
    func userSession(for client: ClientProtocol, sessionDirectories: SessionDirectories, passphrase: Data) async -> Result<UserSessionProtocol, UserSessionStoreError>
    /// Registers a session that's ready to be used, replacing any previous session for its account.
    /// A new account becomes the active one, a known account keeps its place.
    func add(_ userSession: UserSessionProtocol)
    /// Deletes an account's credentials and data, and forgets its session.
    func remove(userID: String)
    /// Deletes every account's credentials and data.
    func reset()
}
