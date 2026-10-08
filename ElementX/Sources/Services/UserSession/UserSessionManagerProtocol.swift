//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

enum UserSessionManagerError: Error {
    /// There are no signed in accounts to restore.
    case noAccounts
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
    
    func session(for userID: String) -> UserSessionProtocol?
    
    // MARK: - Lifecycle
    
    /// Restores the most recently active account, falling back to the next one when it fails (the store deletes failed accounts).
    ///
    /// The session isn't registered: `add` it once it's ready to be used, e.g. after any migrations.
    func restoreActiveSession() async -> Result<UserSessionProtocol, UserSessionManagerError>
    /// Registers a session that's ready to be used, replacing any previous session for its account.
    /// A new account becomes the active one, a known account keeps its place.
    func add(_ userSession: UserSessionProtocol)
    /// Deletes an account's credentials and data, and forgets its session.
    func remove(userID: String)
    /// Deletes every account's credentials and data.
    func reset()
}
