//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

/// Owns the live session of every account signed in on this device, most recently active first.
///
/// Only the `AppCoordinator` calls the lifecycle methods, so the active account always changes
/// through its state machine. Everything else gets a `UserSessionManagerProtocol`.
final class UserSessionManager: UserSessionManagerProtocol {
    private let userSessionStore: UserSessionStoreProtocol
    private let appSettings: AppSettings
    
    private let userIDsSubject: CurrentValueSubject<[String], Never>
    private var sessionsByUserID: [String: UserSessionProtocol] = [:]
    
    var userIDs: [String] {
        userIDsSubject.value
    }
    
    var userIDsPublisher: CurrentValuePublisher<[String], Never> {
        userIDsSubject.asCurrentValuePublisher()
    }
    
    var sessions: [UserSessionProtocol] {
        userIDs.compactMap { sessionsByUserID[$0] }
    }
    
    var activeSession: UserSessionProtocol? {
        userIDs.first.flatMap { sessionsByUserID[$0] }
    }
    
    init(userSessionStore: UserSessionStoreProtocol, appSettings: AppSettings) {
        self.userSessionStore = userSessionStore
        self.appSettings = appSettings
        
        // The keychain decides which accounts exist, the stored order only sorts them.
        let keychainUserIDs = userSessionStore.userIDs
        let storedUserIDs = appSettings.recentUserIDs
        let userIDs = storedUserIDs.filter { keychainUserIDs.contains($0) } + keychainUserIDs.filter { !storedUserIDs.contains($0) }.sorted()
        userIDsSubject = .init(userIDs)
        
        if userIDs != storedUserIDs {
            appSettings.recentUserIDs = userIDs
        }
    }
    
    func session(for userID: String) -> UserSessionProtocol? {
        sessionsByUserID[userID]
    }
    
    // MARK: - Lifecycle
    
    /// Restores the most recently active account, falling back to the next one when it fails (the store deletes failed accounts).
    ///
    /// The session isn't registered: `add` it once it's ready to be used, e.g. after any migrations.
    func restoreActiveSession() async -> Result<UserSessionProtocol, UserSessionManagerError> {
        guard !userIDs.isEmpty else {
            return .failure(.noAccounts)
        }
        
        while let userID = userIDs.first {
            switch await userSessionStore.restoreUserSession(userID: userID) {
            case .success(let userSession):
                return .success(userSession)
            case .failure(let error):
                MXLog.error("Failed restoring \(userID), falling back to the next account: \(error)")
                sessionsByUserID[userID] = nil
                setUserIDs(userIDs.filter { $0 != userID })
            }
        }
        
        return .failure(.failedRestoringSessions)
    }
    
    /// Registers a session that's ready to be used, replacing any previous session for its account.
    /// A new account becomes the active one, a known account keeps its place.
    func add(_ userSession: UserSessionProtocol) {
        let userID = userSession.clientProxy.userID
        sessionsByUserID[userID] = userSession
        
        if !userIDs.contains(userID) {
            setUserIDs([userID] + userIDs)
        }
    }
    
    /// Deletes an account's credentials and data, and forgets its session.
    func remove(userID: String) {
        guard let userSession = sessionsByUserID.removeValue(forKey: userID) else {
            MXLog.error("Tried to remove \(userID), which doesn't have a live session.")
            return
        }
        
        userSessionStore.logout(userSession: userSession)
        setUserIDs(userIDs.filter { $0 != userID })
    }
    
    /// Deletes every account's credentials and data.
    func reset() {
        userSessionStore.reset()
        sessionsByUserID.removeAll()
        setUserIDs([])
    }
    
    // MARK: - Private
    
    private func setUserIDs(_ userIDs: [String]) {
        appSettings.recentUserIDs = userIDs
        userIDsSubject.send(userIDs)
    }
}
