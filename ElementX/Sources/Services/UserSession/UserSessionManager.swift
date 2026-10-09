//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK
import OrderedCollections

/// Owns the live session of every account signed in on this device, most recently active first.
///
/// Only the `AppCoordinator` calls the lifecycle methods, so the active account always changes
/// through its state machine. Flows only receive the `UserSessionDetails` of its sessions.
final class UserSessionManager: UserSessionManagerProtocol {
    private let userSessionStore: UserSessionStoreProtocol
    private let appSettings: AppSettings
    
    private let sessionsSubject = CurrentValueSubject<[UserSessionProtocol], Never>([])
    /// Whether the services are running, so that the sessions restored meanwhile are resumed too.
    private var areServicesRunning = false
    
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
    
    var clientSessionDelegate: ClientSessionDelegate {
        userSessionStore.clientSessionDelegate
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
            if case .success(let userSession) = await restoreUserSession(userID: userID) {
                return .success(userSession)
            }
        }
        
        return .failure(.failedRestoringSessions)
    }
    
    func restoreUserSession(userID: String) async -> Result<UserSessionProtocol, UserSessionManagerError> {
        // Remote settings are app wide, so only the active account's are ever applied.
        if userID == accounts.keys.first {
            userSessionStore.applyRemoteSettings(forUserID: userID)
        }
        
        switch await userSessionStore.restoreUserSession(userID: userID) {
        case .success(let userSession):
            return .success(userSession)
        case .failure(let error):
            MXLog.error("Failed restoring \(userID): \(error)")
            accounts.removeValue(forKey: userID)
            return .failure(.failedRestoringSession)
        }
    }
    
    func restoreOtherSessions(prepare: @MainActor (UserSessionProtocol) async -> Void) async {
        for userID in accounts.keys where session(for: userID) == nil {
            // Clearing the cache or signing out cancels this and restores from scratch.
            guard !Task.isCancelled,
                  case .success(let userSession) = await restoreUserSession(userID: userID) else { continue }
            
            await prepare(userSession)
            guard !Task.isCancelled else { return }
            
            add(userSession)
            
            if areServicesRunning {
                await userSession.clientProxy.resumeServices()
            }
        }
    }
    
    func userSession(for client: ClientProtocol, sessionDirectories: SessionDirectories, passphrase: Data) async -> Result<UserSessionProtocol, UserSessionStoreError> {
        await userSessionStore.userSession(for: client, sessionDirectories: sessionDirectories, passphrase: passphrase)
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
    
    // MARK: - Services
    
    var isSearchBackfillRunning: Bool {
        sessionsSubject.value.contains { $0.clientProxy.isSearchBackfillRunning }
    }
    
    func resumeServices() async {
        areServicesRunning = true
        for userSession in sessionsSubject.value {
            await userSession.clientProxy.resumeServices()
        }
    }
    
    func pauseServices() async {
        areServicesRunning = false
        for userSession in sessionsSubject.value {
            await userSession.clientProxy.pauseServices()
        }
    }
    
    func configurePresence(_ presence: ClientProxyPresence, sendImmediately: Bool) async {
        for userSession in sessionsSubject.value {
            _ = await userSession.clientProxy.configurePresence(presence, sendImmediately: sendImmediately)
        }
    }
    
    func startSearchBackfill(strategy: SearchBackfillStrategy) {
        sessionsSubject.value.forEach { $0.clientProxy.startSearchBackfill(strategy: strategy) }
    }
    
    func stopSearchBackfill() {
        sessionsSubject.value.forEach { $0.clientProxy.stopSearchBackfill() }
    }
}
