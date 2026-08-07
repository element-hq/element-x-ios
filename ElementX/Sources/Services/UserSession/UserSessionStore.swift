//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

class UserSessionStore: UserSessionStoreProtocol {
    private let keychainController: KeychainControllerProtocol
    private let appSettings: AppSettings
    private let analyticsService: AnalyticsServiceProtocol
    private let networkMonitor: NetworkMonitorProtocol
    private let appHooks: AppHooks
    
    /// Whether or not there are sessions in the store.
    var hasSessions: Bool {
        !keychainController.restorationTokens().isEmpty
    }
    
    /// All the user IDs managed by the store.
    var userIDs: [String] {
        keychainController.restorationTokens().map(\.userID)
    }
    
    var clientSessionDelegate: ClientSessionDelegate {
        keychainController
    }
    
    init(keychainController: KeychainControllerProtocol,
         appSettings: AppSettings,
         analyticsService: AnalyticsServiceProtocol,
         appHooks: AppHooks,
         networkMonitor: NetworkMonitorProtocol) {
        self.keychainController = keychainController
        self.appSettings = appSettings
        self.analyticsService = analyticsService
        self.appHooks = appHooks
        self.networkMonitor = networkMonitor
    }
    
    /// The result of the expensive, UI-independent prefix of a session restore.
    struct EagerRestoredSession: Sendable {
        let client: ClientProtocol
        /// Built and already started on the detached task so the first sync request goes
        /// out during scene bring-up; nil if the eager build failed (the `ClientProxy`
        /// then builds its own, keeping the original failure semantics).
        let syncService: SyncService?
    }

    /// The client being built and restored eagerly by [`beginEagerRestore`], consumed
    /// by the next `restoreUserSession()` call.
    private var eagerClientTask: Task<EagerRestoredSession, Error>?

    /// Kick off the expensive prefix of a session restore (store opens + session
    /// restore) on a detached task, so that it runs concurrently with the rest of the
    /// app's launch instead of queueing behind scene bring-up on the main actor.
    /// `restoreUserSession()` picks up the result.
    func beginEagerRestore() {
        guard eagerClientTask == nil,
              let credentials = keychainController.restorationTokens().first else { return }

        // Main-actor-isolated, and must precede the builder configuration reading
        // `appSettings` - so it runs here rather than on the detached task.
        appHooks.remoteSettingsHook.loadCache(forHomeserver: credentials.restorationToken.session.homeserverUrl,
                                              applyingTo: appSettings)

        let sessionDelegate = clientSessionDelegate
        let appSettings = appSettings
        let appHooks = appHooks

        eagerClientTask = Task.detached(priority: .userInitiated) {
            try await Self.buildAndRestoreClient(credentials: credentials,
                                                 sessionDelegate: sessionDelegate,
                                                 appSettings: appSettings,
                                                 appHooks: appHooks)
        }
    }

    /// Deletes all data stored in the shared container and keychain
    func reset() {
        MXLog.warning("Resetting the UserSessionStore. All accounts will be affected.")
        try? FileManager.default.removeItem(at: .sessionsBaseDirectory)
        keychainController.removeAllRestorationTokens()
    }
    
    func restoreUserSession() async -> Result<UserSessionProtocol, UserSessionStoreError> {
        let availableCredentials = keychainController.restorationTokens()
        
        guard let credentials = availableCredentials.first else {
            return .failure(.missingCredentials)
        }
        
        switch await restorePreviousLogin(credentials) {
        case .success(let clientProxy):
            return await .success(buildUserSessionWithClient(clientProxy))
        case .failure(let error):
            MXLog.error("Failed restoring login with error: \(error)")
            
            // On any restoration failure reset the token and restart
            keychainController.removeRestorationTokenForUsername(credentials.userID)
            credentials.restorationToken.sessionDirectories.delete()
            
            return .failure(error)
        }
    }
    
    func userSession(for client: ClientProtocol, sessionDirectories: SessionDirectories, passphrase: String) async -> Result<UserSessionProtocol, UserSessionStoreError> {
        do {
            let session = try client.session()
            let userID = try client.userId()
            let clientProxy = try await setupProxyForClient(client)
            
            keychainController.setRestorationToken(RestorationToken(session: session,
                                                                    sessionDirectories: sessionDirectories,
                                                                    passphrase: passphrase,
                                                                    pusherNotificationClientIdentifier: clientProxy.pusherNotificationClientIdentifier),
                                                   forUsername: userID)
            
            MXLog.info("Set up session for user \(userID) at: \(sessionDirectories)")
            
            return await .success(buildUserSessionWithClient(clientProxy))
        } catch {
            MXLog.error("Failed creating user session with error: \(error)")
            return .failure(.failedSettingUpSession)
        }
    }
    
    func logout(userSession: UserSessionProtocol) {
        let userID = userSession.clientProxy.userID
        let credentials = keychainController.restorationTokens().first { $0.userID == userID }
        keychainController.removeRestorationTokenForUsername(userID)
        
        if let credentials {
            credentials.restorationToken.sessionDirectories.delete()
        }
    }
    
    // MARK: - Private
    
    private func buildUserSessionWithClient(_ clientProxy: ClientProxyProtocol) async -> UserSessionProtocol {
        let mediaProvider = MediaProvider(mediaLoader: clientProxy.mediaLoader,
                                          imageCache: .onlyInMemory,
                                          homeserverReachabilityPublisher: clientProxy.homeserverReachabilityPublisher)
        
        let voiceMessageMediaManager = VoiceMessageMediaManager(mediaProvider: mediaProvider)
        
        let liveLocationManager = await MainActor.run {
            LiveLocationManager(clientProxy: clientProxy,
                                appSettings: appSettings)
        }
        
        return UserSession(clientProxy: clientProxy,
                           mediaProvider: mediaProvider,
                           voiceMessageMediaManager: voiceMessageMediaManager,
                           liveLocationManager: liveLocationManager)
    }
    
    private func restorePreviousLogin(_ credentials: KeychainCredentials) async -> Result<ClientProxyProtocol, UserSessionStoreError> {
        if eagerClientTask == nil {
            appHooks.remoteSettingsHook.loadCache(forHomeserver: credentials.restorationToken.session.homeserverUrl,
                                                  applyingTo: appSettings)
        }
        let clientTask = eagerClientTask ?? Task.detached { [sessionDelegate = clientSessionDelegate, appSettings, appHooks] in
            try await Self.buildAndRestoreClient(credentials: credentials,
                                                 sessionDelegate: sessionDelegate,
                                                 appSettings: appSettings,
                                                 appHooks: appHooks)
        }
        eagerClientTask = nil

        let session: EagerRestoredSession
        do {
            session = try await clientTask.value
        } catch {
            MXLog.error("Failed restoring login with error: \(error)")
            return .failure(.failedRestoringLogin)
        }
        let client = session.client

        MXLog.info("Set up session for user \(credentials.userID) at: \(credentials.restorationToken.sessionDirectories)")

        Task(priority: .low) { await appHooks.remoteSettingsHook.updateCache(using: client) }

        do {
            return try await .success(setupProxyForClient(client, prebuiltSyncService: session.syncService))
        } catch UserSessionStoreError.failedSettingUpClientProxy(let error) {
            // If this has failed, there is likely something wrong with the creation of the sync service
            // There is nothing we can do, but at the same time we don't want the user to the get logged out
            // So it's better to crash here and let the app restart
            fatalError("Failed setting up the client proxy with error: \(error)")
        } catch {
            MXLog.error("Failed restoring login with error: \(error)")
            return .failure(.failedRestoringLogin)
        }
    }

    /// The expensive prefix of a session restore: opening the stores and restoring the
    /// session, everything up to (but not including) the `ClientProxy`. Deliberately
    /// `nonisolated` so that it runs off the main actor: at launch the main actor is
    /// busy with scene bring-up for hundreds of milliseconds after the eager restore
    /// starts, and a main-actor-isolated restore cannot run a single step until then.
    private nonisolated static func buildAndRestoreClient(credentials: KeychainCredentials,
                                                          sessionDelegate: ClientSessionDelegate,
                                                          appSettings: AppSettings,
                                                          appHooks: AppHooks) async throws -> EagerRestoredSession {
        guard credentials.restorationToken.sessionDirectories.isNonTransientUserDataValid() else {
            MXLog.error("Failed restoring login, missing non-transient user data")
            throw UserSessionStoreError.failedRestoringLogin
        }

        // NB: the caller runs `appHooks.remoteSettingsHook.loadCache` (main-actor
        // isolated) before handing over to this function.
        let homeserverURL = credentials.restorationToken.session.homeserverUrl

        let builder = ClientBuilder
            .baseBuilder(httpProxy: URL(string: homeserverURL)?.globalProxy,
                         slidingSync: .restored,
                         sessionDelegate: sessionDelegate,
                         appHooks: appHooks,
                         enableOnlySignedDeviceIsolationMode: appSettings.enableOnlySignedDeviceIsolationMode,
                         threadsEnabled: appSettings.threadsEnabled,
                         automaticBackPaginationEnabled: appSettings.automaticBackPaginationEnabled)
            .sqliteStore(config: .init(dataPath: credentials.restorationToken.sessionDirectories.dataPath,
                                       cachePath: credentials.restorationToken.sessionDirectories.cachePath)
                    // The store passphrase is a randomly generated 256-bit key (EncryptionKeyProvider),
                    // so the stores can cache a fast-open copy of their cipher and skip the
                    // brute-force-resistant KDF (4 stores x ~200ms of pure CPU) on every launch.
                    .highEntropyPassphrase(passphrase: credentials.restorationToken.passphrase))
            .withSearchIndexStore(path: credentials.restorationToken.sessionDirectories.dataPath,
                                  password: credentials.restorationToken.passphrase)
            .username(username: credentials.userID)
            .homeserverUrl(url: homeserverURL)

        let client = try await builder.build()
        try await client.restoreSession(session: credentials.restorationToken.session)

        // Build and start the sync service here too: the first sync request then goes
        // out while the main actor is still busy with scene bring-up, instead of after
        // the ClientProxy (main-actor-isolated) gets scheduled. Same configuration as
        // ClientProxyServices; a later start() from the service-state machinery is a
        // no-op. Failures are deferred to the ClientProxy's own build, which keeps the
        // established failure semantics.
        var eagerSyncService: SyncService?
        do {
            var syncServiceBuilder = client
                .syncService()
                .withOfflineMode()
                .withSharePos(enable: true)
            if appSettings.userStatusEnabled {
                syncServiceBuilder = syncServiceBuilder.withProfilesExtension()
            }
            if appSettings.paginatedSyncEnabled {
                syncServiceBuilder = syncServiceBuilder.withPaginatedSync()
            }
            let syncService = try await syncServiceBuilder.finish()
            await syncService.start()
            eagerSyncService = syncService
        } catch {
            MXLog.error("Eager sync service build failed, deferring to ClientProxy: \(error)")
        }

        return EagerRestoredSession(client: client, syncService: eagerSyncService)
    }

    private func setupProxyForClient(_ client: ClientProtocol, prebuiltSyncService: SyncService? = nil) async throws -> ClientProxyProtocol {
        do {
            return try await ClientProxy(client: client,
                                         networkMonitor: networkMonitor,
                                         appSettings: appSettings,
                                         analyticsService: analyticsService,
                                         prebuiltSyncService: prebuiltSyncService)
        } catch {
            throw UserSessionStoreError.failedSettingUpClientProxy(error)
        }
    }
}
