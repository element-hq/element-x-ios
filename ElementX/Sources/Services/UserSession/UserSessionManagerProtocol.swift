//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

enum UserSessionManagerCallback: Equatable {
    /// An account's session was restored and is now live.
    case didRestoreSession(userID: String)
    /// An account was removed along with all of its data, with an error when the user didn't ask for it.
    case didRemoveAccount(userID: String, error: UserSessionManagerError?)
}

enum UserSessionManagerError: Error, Equatable {
    /// The server logged the account out.
    case remoteLogout
    /// The account's session couldn't be restored.
    case failedRestoringSession
}

// sourcery: AutoMockable
protocol UserSessionManagerProtocol: AnyObject {
    /// Every signed in account, most recently active first. Known before any session is live, so use it to count accounts.
    var userIDs: [String] { get }
    /// The live sessions, in the same order as `userIDs`, republished when one of their profiles or unread counts changes.
    var sessionsPublisher: CurrentValuePublisher<[UserSessionProtocol], Never> { get }
    /// The session of the account whose UI is on screen.
    var activeSession: UserSessionProtocol? { get }
    /// The changes made to the accounts, such as an account being removed.
    var callbacksPublisher: AnyPublisher<UserSessionManagerCallback, Never> { get }
    /// The delegate that stores changes to a client's session, such as refreshed tokens.
    var clientSessionDelegate: ClientSessionDelegate { get }
    
    func session(for userID: String) -> UserSessionProtocol?
    
    // MARK: - Lifecycle
    
    /// Restores every account that isn't live, or whose caches were cleared, most recently selected first and one after the other.
    ///
    /// Each session is migrated, added, reported with `didRestoreSession`, then resumed if the services are running.
    /// An account that fails is removed (the store deletes its data). Without `multiAccountEnabled` only one account is ever live.
    func restoreSessions() async
    /// Clears an account's caches, then restores it to replace its session
    ///
    /// The session will be reported as ready with `didRestoreSession`.
    func clearCaches(userID: String) async
    /// Creates the session of an account that has just signed in, and stores its credentials.
    ///
    /// The session isn't registered: add it with `addNewSession` once it's ready to be used.
    func userSession(for client: ClientProtocol, sessionDirectories: SessionDirectories, passphrase: Data) async -> Result<UserSessionProtocol, UserSessionStoreError>
    /// Registers the session of an account that has just signed in, making a new account the active one.
    /// The session is resumed if the services are running.
    func addNewSession(_ userSession: UserSessionProtocol)
    /// Logs an account out of the server, then removes it.
    func logout(userID: String) async
    /// Logs out every account.
    func logoutAll() async
    /// Deletes an account's credentials and data, and forgets its session.
    func remove(userID: String)
    /// Deletes every account's credentials and data.
    func reset()
    
    // MARK: - Services
    
    /// Whether any live session is still running a search backfill.
    var isSearchBackfillRunning: Bool { get }
    
    /// Resumes every live session's services, and those of the sessions restored while they're running.
    func resumeServices() async
    /// Pauses every live session's services.
    func pauseServices() async
    func configurePresence(_ presence: ClientProxyPresence, sendImmediately: Bool) async
    func startSearchBackfill(strategy: SearchBackfillStrategy)
    func stopSearchBackfill()
}
