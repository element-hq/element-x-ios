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
    var userIDsPublisher: CurrentValuePublisher<[String], Never> { get }
    /// The live sessions, in the same order as `userIDs`.
    var sessions: [UserSessionProtocol] { get }
    /// The session of the account whose UI is on screen.
    var activeSession: UserSessionProtocol? { get }
    
    func session(for userID: String) -> UserSessionProtocol?
}
