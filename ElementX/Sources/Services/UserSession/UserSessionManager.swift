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
    private let notificationManager: NotificationManagerProtocol
    private let liveLocationManager: LiveLocationManagerProtocol
    
    private let sessionsSubject = CurrentValueSubject<[UserSessionProtocol], Never>([])
    /// Whether the services are running, so that the sessions restored meanwhile are resumed too.
    private var areServicesRunning = false
    /// Accounts whose caches were cleared. Their old session stays live until restoring replaces it.
    private var clearedUserIDs: Set<String> = []
    
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
    
    var callbacksPublisher: AnyPublisher<UserSessionManagerCallback, Never> {
        sessionsSubject
            .map { userSessions in
                Publishers.MergeMany(userSessions.map { userSession in
                    let userID = userSession.clientProxy.userID
                    return userSession.callbacks.map { callback in
                        switch callback {
                        case .didReceiveAuthError(let isSoftLogout):
                            UserSessionManagerCallback.didReceiveAuthError(userID: userID, isSoftLogout: isSoftLogout)
                        }
                    }
                })
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
    
    var clientSessionDelegate: ClientSessionDelegate {
        userSessionStore.clientSessionDelegate
    }
    
    /// Whether an account has a session that's live and up to date (its caches weren't cleared).
    private var hasLiveSession: Bool {
        accounts.contains { userID, userSession in userSession != nil && !clearedUserIDs.contains(userID) }
    }
    
    init(userSessionStore: UserSessionStoreProtocol,
         appSettings: AppSettings,
         notificationManager: NotificationManagerProtocol,
         liveLocationManager: LiveLocationManagerProtocol) {
        self.userSessionStore = userSessionStore
        self.appSettings = appSettings
        self.notificationManager = notificationManager
        self.liveLocationManager = liveLocationManager
        
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
    
    func restoreSessions(prepare: @MainActor (UserSessionProtocol) async -> Void, didAdd: @MainActor (UserSessionProtocol) -> Void) async {
        for userID in accounts.keys where session(for: userID) == nil || clearedUserIDs.contains(userID) {
            // Every live session syncs, so without multi-account only one account is ever made live.
            guard appSettings.multiAccountEnabled || !hasLiveSession else { return }
            // Signing out or clearing the cache cancels this, after which nothing may go live.
            guard !Task.isCancelled else { return }
            guard let userSession = await restoreUserSession(userID: userID) else { continue }
            guard !Task.isCancelled else { return }
            
            await prepare(userSession)
            guard !Task.isCancelled else { return }
            
            add(userSession)
            didAdd(userSession)
            
            if areServicesRunning {
                await userSession.clientProxy.resumeServices()
            }
            
            // Lets the work queued for this session (e.g. its first sync) start before the next account's restore.
            await Task.yield()
        }
    }
    
    func clearCaches(userID: String) async {
        guard let userSession = session(for: userID) else { return }
        
        // Marked before clearing, so a restore that starts meanwhile replaces the session.
        clearedUserIDs.insert(userID)
        await userSession.clientProxy.clearCaches()
    }
    
    func userSession(for client: ClientProtocol, sessionDirectories: SessionDirectories, passphrase: Data) async -> Result<UserSessionProtocol, UserSessionStoreError> {
        await userSessionStore.userSession(for: client, sessionDirectories: sessionDirectories, passphrase: passphrase)
    }
    
    func add(_ userSession: UserSessionProtocol) {
        let userID = userSession.clientProxy.userID
        clearedUserIDs.remove(userID)
        
        if accounts.keys.contains(userID) {
            accounts[userID] = userSession
        } else {
            appSettings.userSettings(for: userID).account.lastSelectedDate = .now
            accounts.updateValue(userSession, forKey: userID, insertingAt: 0)
        }
        
        notificationManager.add(userSession.notificationService)
        liveLocationManager.add(userSession.liveLocationService)
    }
    
    func remove(userID: String) {
        guard let userSession = accounts[userID] ?? nil else {
            MXLog.error("Tried to remove \(userID), which doesn't have a live session.")
            return
        }
        
        userSessionStore.logout(userSession: userSession)
        clearedUserIDs.remove(userID)
        accounts.removeValue(forKey: userID)
        notificationManager.remove(userID: userID)
        liveLocationManager.remove(userID: userID)
    }
    
    func reset() {
        for userID in accounts.keys {
            notificationManager.remove(userID: userID)
            liveLocationManager.remove(userID: userID)
        }
        userSessionStore.reset()
        clearedUserIDs.removeAll()
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
    
    // MARK: - Private
    
    /// Restores an account's session, removing the account when that fails (the store deletes its data).
    private func restoreUserSession(userID: String) async -> UserSessionProtocol? {
        switch await userSessionStore.restoreUserSession(userID: userID) {
        case .success(let userSession):
            return userSession
        case .failure(let error):
            MXLog.error("Failed restoring \(userID): \(error)")
            clearedUserIDs.remove(userID)
            accounts.removeValue(forKey: userID)
            notificationManager.remove(userID: userID)
            liveLocationManager.remove(userID: userID)
            return nil
        }
    }
}
