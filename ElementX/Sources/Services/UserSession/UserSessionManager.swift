//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import OrderedCollections

/// Owns the live session of every account signed in on this device, most recently active first.
///
/// Only the `AppCoordinator` calls the lifecycle methods, so the active account always changes
/// through its state machine. Flows only receive its `sessionsPublisher`.
final class UserSessionManager: UserSessionManagerProtocol {
    private let userSessionStore: UserSessionStoreProtocol
    private let appSettings: AppSettings
    
    private let sessionsSubject = CurrentValueSubject<[UserSessionProtocol], Never>([])
    
    /// Every signed in account, most recently selected first, with its session once it's live.
    /// Assigning `nil` removes an account rather than clearing its session.
    private var accounts: OrderedDictionary<String, UserSessionProtocol?> = [:] {
        didSet { sessionsSubject.send(accounts.values.compactMap { $0 }) }
    }
    
    var userIDs: [String] {
        Array(accounts.keys)
    }
    
    var sessionsPublisher: CurrentValuePublisher<[UserSessionProtocol], Never> {
        sessionsSubject.asCurrentValuePublisher()
    }
    
    var activeSession: UserSessionProtocol? {
        accounts.values.first ?? nil
    }
    
    init(userSessionStore: UserSessionStoreProtocol, appSettings: AppSettings) {
        self.userSessionStore = userSessionStore
        self.appSettings = appSettings
        
        let userIDs = userSessionStore.userIDs
            .map { (userID: $0, lastSelectedDate: appSettings.userSettings(for: $0).account.lastSelectedDate) }
            .sorted { lhs, rhs in
                switch (lhs.lastSelectedDate, rhs.lastSelectedDate) {
                case let (lhsDate?, rhsDate?) where lhsDate != rhsDate: lhsDate > rhsDate
                case (.some, .none): true
                case (.none, .some): false
                default: lhs.userID < rhs.userID
                }
            }
            .map(\.userID)
        accounts = OrderedDictionary(uniqueKeysWithValues: userIDs.map { ($0, UserSessionProtocol?.none) })
    }
    
    func session(for userID: String) -> UserSessionProtocol? {
        accounts[userID] ?? nil
    }
    
    // MARK: - Lifecycle
    
    func restoreActiveSession() async -> Result<UserSessionProtocol, UserSessionManagerError> {
        guard !accounts.isEmpty else {
            return .failure(.noAccounts)
        }
        
        while let userID = accounts.keys.first {
            switch await userSessionStore.restoreUserSession(userID: userID) {
            case .success(let userSession):
                return .success(userSession)
            case .failure(let error):
                MXLog.error("Failed restoring \(userID), falling back to the next account: \(error)")
                accounts.removeValue(forKey: userID)
            }
        }
        
        return .failure(.failedRestoringSessions)
    }
    
    func add(_ userSession: UserSessionProtocol) {
        let userID = userSession.clientProxy.userID
        
        if accounts.keys.contains(userID) {
            accounts[userID] = userSession
        } else {
            appSettings.userSettings(for: userID).account.lastSelectedDate = .now
            accounts.updateValue(userSession, forKey: userID, insertingAt: 0)
        }
    }
    
    func remove(userID: String) {
        guard let userSession = accounts[userID] ?? nil else {
            MXLog.error("Tried to remove \(userID), which doesn't have a live session.")
            return
        }
        
        userSessionStore.logout(userSession: userSession)
        accounts.removeValue(forKey: userID)
    }
    
    func reset() {
        userSessionStore.reset()
        accounts.removeAll()
    }
}
