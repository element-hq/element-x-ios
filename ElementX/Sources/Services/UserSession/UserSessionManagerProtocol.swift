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
    case didReceiveAuthError(userID: String, isSoftLogout: Bool)
}

// sourcery: AutoMockable
protocol UserSessionManagerProtocol: AnyObject {
    /// Every signed in account, most recently active first. Known before any session is live, so use it to count accounts.
    var userIDs: [String] { get }
    /// The live sessions, in the same order as `userIDs`.
    var sessionsPublisher: CurrentValuePublisher<[UserSessionProtocol], Never> { get }
    /// The session of the account whose UI is on screen.
    var activeSession: UserSessionProtocol? { get }
    /// The auth errors of every live session, with the account they belong to.
    var callbacksPublisher: AnyPublisher<UserSessionManagerCallback, Never> { get }
    /// The delegate that stores changes to a client's session, such as refreshed tokens.
    var clientSessionDelegate: ClientSessionDelegate { get }
    
    func session(for userID: String) -> UserSessionProtocol?
    
    // MARK: - Lifecycle
    
    /// Restores every account that isn't live, or whose caches were cleared, most recently selected first and one after the other.
    /// Each session is `prepare`d (e.g. migrated), added, passed to `didAdd`, then resumed if the services are running.
    /// An account that fails is removed (the store deletes its data). Without `multiAccountEnabled` only one account is ever live.
    func restoreSessions(prepare: @MainActor (UserSessionProtocol) async -> Void, didAdd: @MainActor (UserSessionProtocol) -> Void) async
    /// Clears an account's caches. Its session stays live until `restoreSessions` replaces it.
    func clearCaches(userID: String) async
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
