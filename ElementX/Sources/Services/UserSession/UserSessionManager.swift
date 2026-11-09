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
/// Accounts only change here: coordinators call its lifecycle methods for the user's actions and react
/// to its callbacks, rather than changing accounts themselves. Flows only receive the `UserSessionDetails` of its sessions.
final class UserSessionManager: UserSessionManagerProtocol {
    private let userSessionStore: UserSessionStoreProtocol
    private let appSettings: AppSettings
    private let notificationManager: NotificationManagerProtocol
    private let liveLocationManager: LiveLocationManagerProtocol
    private let elementCallManager: ElementCallManagerProtocol
    private let userSessionMigrator: UserSessionMigratorProtocol
    
    private let sessionsSubject = CurrentValueSubject<[UserSessionProtocol], Never>([])
    private let callbacksSubject = PassthroughSubject<UserSessionManagerCallback, Never>()
    private var authErrorsCancellable: AnyCancellable?
    /// Whether the services are running, so that the sessions restored meanwhile are resumed too.
    private var areServicesRunning = false
    /// Accounts whose caches were cleared. Their old session stays live until restoring replaces it.
    private var clearedUserIDs: Set<String> = []
    /// Accounts that are logging out, so that their teardown only runs once.
    private var loggingOutUserIDs: Set<String> = []
    /// Restores the signed in accounts.
    private var restorationTask: Task<Void, Never>?
    
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
        callbacksSubject.eraseToAnyPublisher()
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
         liveLocationManager: LiveLocationManagerProtocol,
         elementCallManager: ElementCallManagerProtocol,
         userSessionMigrator: UserSessionMigratorProtocol) {
        self.userSessionStore = userSessionStore
        self.appSettings = appSettings
        self.notificationManager = notificationManager
        self.liveLocationManager = liveLocationManager
        self.elementCallManager = elementCallManager
        self.userSessionMigrator = userSessionMigrator
        
        #warning("Read lastSelectedDate without appSettings.userSettings(for:), which must only come from a user session.")
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
        
        authErrorsCancellable = sessionsSubject
            .map { userSessions in
                Publishers.MergeMany(userSessions.map { userSession in
                    let userID = userSession.clientProxy.userID
                    return userSession.callbacks.map { callback in
                        switch callback {
                        case .didReceiveAuthError: userID
                        }
                    }
                })
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userID in
                guard let self else { return }
                Task { await self.logout(userID: userID, error: .remoteLogout) }
            }
    }
    
    func session(for userID: String) -> UserSessionProtocol? {
        accounts[userID] ?? nil
    }
    
    // MARK: - Lifecycle
    
    func restoreSessions() async {
        let previousRestorationTask = restorationTask
        let restorationTask = Task {
            // A previous restoration may still be building a client, which mustn't share a store with a new one.
            await previousRestorationTask?.value
            await restoreAccounts()
        }
        self.restorationTask = restorationTask
        
        await restorationTask.value
    }
    
    func clearCaches(userID: String) async {
        guard let userSession = session(for: userID) else { return }
        
        await userSession.clientProxy.pauseServices()
        clearedUserIDs.insert(userID) // Marked before clearing, so it is ready to restore after clearing is done.
        await userSession.clientProxy.clearCaches()
        await restoreSessions()
    }
    
    private func restoreAccounts() async {
        for userID in accounts.keys where session(for: userID) == nil || clearedUserIDs.contains(userID) {
            // Every live session syncs, so without multi-account only one account is ever made live.
            guard appSettings.multiAccountEnabled || !hasLiveSession else { return }
            // Skip any account that was removed while restoring those before it.
            guard accounts.keys.contains(userID), let userSession = await restoreUserSession(userID: userID) else { continue }
            
            await userSessionMigrator.migrate(userSession)
            // The account may have been removed while it was restoring.
            guard accounts.keys.contains(userID) else { continue }
            
            add(userSession)
            callbacksSubject.send(.didRestoreSession(userID: userID))
            
            if areServicesRunning {
                await userSession.clientProxy.resumeServices()
            }
            
            // Lets the work queued for this session (e.g. its first sync) start before the next account's restore.
            await Task.yield()
        }
    }
    
    func userSession(for client: ClientProtocol, sessionDirectories: SessionDirectories, passphrase: Data) async -> Result<UserSessionProtocol, UserSessionStoreError> {
        await userSessionStore.userSession(for: client, sessionDirectories: sessionDirectories, passphrase: passphrase)
    }
    
    func addNewSession(_ userSession: UserSessionProtocol) {
        add(userSession)
        
        if areServicesRunning {
            Task { await userSession.clientProxy.resumeServices() }
        }
    }
    
    func logout(userID: String) async {
        await logout(userID: userID, error: nil)
    }
    
    private func logout(userID: String, error: UserSessionManagerError?) async {
        guard let userSession = session(for: userID) else {
            MXLog.error("Tried to log out \(userID), which doesn't have a live session.")
            return
        }
        guard loggingOutUserIDs.insert(userID).inserted else { return }
        defer { loggingOutUserIDs.remove(userID) }
        
        await userSession.clientProxy.pauseServices()
        
        // Delete the pusher and stop the live location shares while the session can still reach the server.
        await userSession.notificationService.tearDown()
        await userSession.liveLocationService.stopAllLiveLocations()
        
        await userSession.clientProxy.logout()
        
        // Remove the user, clearing user data.
        remove(userID: userID)
        
        callbacksSubject.send(.didRemoveAccount(userID: userID, error: error))
    }
    
    func logoutAll() async {
        await restorationTask?.value // Wait for all accounts to finish restoration first.
        
        for userID in userIDs {
            if session(for: userID) != nil {
                await logout(userID: userID)
            } else {
                // Very unlikely to happen in practice.
                remove(userID: userID) // Without a live session just make sure the account's local data is deleted.
                callbacksSubject.send(.didRemoveAccount(userID: userID, error: nil))
            }
        }
    }
    
    func remove(userID: String) {
        guard accounts.keys.contains(userID) else {
            MXLog.error("Tried to remove \(userID), which isn't signed in.")
            return
        }
        
        userSessionStore.logout(userID: userID)
        clearedUserIDs.remove(userID)
        accounts.removeValue(forKey: userID)
        notificationManager.remove(userID: userID)
        liveLocationManager.remove(userID: userID)
        elementCallManager.remove(userID: userID)
    }
    
    func reset() {
        let removedUserIDs = userIDs
        for userID in removedUserIDs {
            notificationManager.remove(userID: userID)
            liveLocationManager.remove(userID: userID)
        }
        userSessionStore.reset()
        clearedUserIDs.removeAll()
        accounts.removeAll()
        for userID in removedUserIDs {
            elementCallManager.remove(userID: userID)
        }
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
            elementCallManager.remove(userID: userID)
            callbacksSubject.send(.didRemoveAccount(userID: userID, error: .failedRestoringSession))
            return nil
        }
    }
    
    /// Registers a session that's ready to be used, replacing any previous session for its account.
    /// A new account becomes the active one, a known account keeps its place.
    private func add(_ userSession: UserSessionProtocol) {
        let userID = userSession.clientProxy.userID
        clearedUserIDs.remove(userID)
        
        if accounts.keys.contains(userID) {
            accounts[userID] = userSession
        } else {
            userSession.userSettings.account.lastSelectedDate = .now
            userSessionMigrator.markAsMigrated(userSession)
            accounts.updateValue(userSession, forKey: userID, insertingAt: 0)
        }
        
        notificationManager.add(userSession.notificationService)
        liveLocationManager.add(userSession.liveLocationService)
        elementCallManager.add(userSession.elementCallService)
    }
}
