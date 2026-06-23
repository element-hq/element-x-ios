//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Kingfisher
import MatrixRustSDK

class UserSessionStore: UserSessionStoreProtocol {
    private let keychainController: KeychainControllerProtocol
    private let appSettings: AppSettings
    private let networkMonitor: NetworkMonitorProtocol
    private let appHooks: AppHooks
    
    /// Whether or not there are sessions in the store.
    var hasSessions: Bool { !keychainController.restorationTokens().isEmpty }
    /// All the user IDs managed by the store.
    var userIDs: [String] { keychainController.restorationTokens().map(\.userID) }
    
    var clientSessionDelegate: ClientSessionDelegate { keychainController }
    
    init(keychainController: KeychainControllerProtocol,
         appSettings: AppSettings,
         appHooks: AppHooks,
         networkMonitor: NetworkMonitorProtocol) {
        self.keychainController = keychainController
        self.appSettings = appSettings
        self.appHooks = appHooks
        self.networkMonitor = networkMonitor
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
            restoreKeyStorageIfNeeded(clientProxy)
            return .success(buildUserSessionWithClient(clientProxy))
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

            bootstrapKeyStorageIfNeeded(clientProxy)

            return .success(buildUserSessionWithClient(clientProxy))
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

    /// On a brand new login, automatically enables key backup, generates a recovery key and stores
    /// it in the keychain so that re-logins on this device can restore silently.
    ///
    /// Runs fully detached and is completely fail-safe: any error is logged and we fall through to
    /// the existing behaviour. It must never block or fail the login.
    private func bootstrapKeyStorageIfNeeded(_ clientProxy: ClientProxyProtocol) {
        let secureBackupController = clientProxy.secureBackupController
        let userID = clientProxy.userID

        Task { [weak self] in
            guard let self else { return }

            do {
                guard !appSettings.hasBootstrappedKeyStorage else { return }

                if secureBackupController.recoveryState.value == .enabled {
                    MXLog.info("Recovery already enabled, marking key storage as bootstrapped.")
                    appSettings.hasBootstrappedKeyStorage = true
                    return
                }

                if secureBackupController.keyBackupState.value != .enabled {
                    MXLog.info("Bootstrapping key storage: enabling backup.")
                    if case .failure(let error) = await secureBackupController.enable() {
                        MXLog.error("Failed enabling backup while bootstrapping key storage: \(error)")
                        return
                    }
                }

                MXLog.info("Bootstrapping key storage: generating recovery key.")
                switch await secureBackupController.generateRecoveryKey() {
                case .success(let key):
                    keychainController.setRecoveryKey(key, forUsername: userID)

                    if case .failure(let error) = await secureBackupController.confirmRecoveryKey(key) {
                        MXLog.error("Failed confirming recovery key while bootstrapping key storage: \(error)")
                        return
                    }

                    appSettings.hasBootstrappedKeyStorage = true
                    MXLog.info("Finished bootstrapping key storage.")
                case .failure(let error):
                    MXLog.error("Failed generating recovery key while bootstrapping key storage: \(error)")
                }
            } catch {
                MXLog.error("Unexpected error while bootstrapping key storage: \(error)")
            }
        }
    }

    /// On a re-login on the same device, silently restores from the recovery key stored in the
    /// keychain so the user doesn't hit the encryption confirmation/reset screen.
    ///
    /// Runs fully detached and is completely fail-safe: any error is logged and we fall through to
    /// the existing behaviour.
    private func restoreKeyStorageIfNeeded(_ clientProxy: ClientProxyProtocol) {
        let secureBackupController = clientProxy.secureBackupController
        let userID = clientProxy.userID

        Task { [weak self] in
            guard let self else { return }

            do {
                guard let storedKey = keychainController.recoveryKey(forUsername: userID) else { return }

                // Only attempt a restore when recovery isn't already fully enabled (e.g. .incomplete).
                guard secureBackupController.recoveryState.value != .enabled else { return }

                MXLog.info("Restoring key storage from stored recovery key.")
                switch await secureBackupController.confirmRecoveryKey(storedKey) {
                case .success:
                    MXLog.info("Finished restoring key storage from stored recovery key.")
                case .failure(let error):
                    MXLog.error("Failed restoring key storage from stored recovery key: \(error)")
                }
            } catch {
                MXLog.error("Unexpected error while restoring key storage: \(error)")
            }
        }
    }

    private func buildUserSessionWithClient(_ clientProxy: ClientProxyProtocol) -> UserSessionProtocol {
        let mediaProvider = MediaProvider(mediaLoader: clientProxy.mediaLoader,
                                          imageCache: .onlyInMemory,
                                          homeserverReachabilityPublisher: clientProxy.homeserverReachabilityPublisher)
        
        let voiceMessageMediaManager = VoiceMessageMediaManager(mediaProvider: mediaProvider)
        
        return UserSession(clientProxy: clientProxy,
                           mediaProvider: mediaProvider,
                           voiceMessageMediaManager: voiceMessageMediaManager)
    }
    
    private func restorePreviousLogin(_ credentials: KeychainCredentials) async -> Result<ClientProxyProtocol, UserSessionStoreError> {
        guard credentials.restorationToken.sessionDirectories.isNonTransientUserDataValid() else {
            MXLog.error("Failed restoring login, missing non-transient user data")
            return .failure(.failedRestoringLogin)
        }
        
        let homeserverURL = credentials.restorationToken.session.homeserverUrl
        appHooks.remoteSettingsHook.loadCache(forHomeserver: homeserverURL, applyingTo: appSettings)
        
        let builder = ClientBuilder
            .baseBuilder(httpProxy: URL(string: homeserverURL)?.globalProxy,
                         slidingSync: .restored,
                         sessionDelegate: keychainController,
                         appHooks: appHooks,
                         enableOnlySignedDeviceIsolationMode: appSettings.enableOnlySignedDeviceIsolationMode,
                         enableKeyShareOnInvite: appSettings.enableKeyShareOnInvite,
                         threadsEnabled: appSettings.threadsEnabled)
            .sqliteStore(config: .init(dataPath: credentials.restorationToken.sessionDirectories.dataPath,
                                       cachePath: credentials.restorationToken.sessionDirectories.cachePath)
                    .passphrase(passphrase: credentials.restorationToken.passphrase))
            .username(username: credentials.userID)
            .homeserverUrl(url: homeserverURL)
        
        do {
            let client = try await builder.build()
            try await client.restoreSession(session: credentials.restorationToken.session)
            
            MXLog.info("Set up session for user \(credentials.userID) at: \(credentials.restorationToken.sessionDirectories)")
            
            Task(priority: .low) { await appHooks.remoteSettingsHook.updateCache(using: client) }
            
            return try await .success(setupProxyForClient(client))
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
    
    private func setupProxyForClient(_ client: ClientProtocol) async throws -> ClientProxyProtocol {
        do {
            return try await ClientProxy(client: client,
                                         networkMonitor: networkMonitor,
                                         appSettings: appSettings)
        } catch {
            throw UserSessionStoreError.failedSettingUpClientProxy(error)
        }
    }
}
