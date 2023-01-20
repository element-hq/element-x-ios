//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import Kingfisher
import MatrixRustSDK

class UserSessionStore: UserSessionStoreProtocol {
    private let keychainController: KeychainControllerProtocol
    private let backgroundTaskService: BackgroundTaskServiceProtocol
    
    /// Whether or not there are sessions in the store.
    var hasSessions: Bool { !keychainController.restorationTokens().isEmpty }
    
    /// The base directory where all session data is stored.
    let baseDirectory: URL
    
    init(backgroundTaskService: BackgroundTaskServiceProtocol) {
        keychainController = KeychainController(service: .sessions,
                                                accessGroup: InfoPlistReader.target.keychainAccessGroupIdentifier)
        self.backgroundTaskService = backgroundTaskService
        baseDirectory = .sessionsBaseDirectory
        MXLog.info("Setup base directory at: \(baseDirectory)")
    }
    
    /// Deletes all data stored in the shared container and keychain
    func reset() {
        try? FileManager.default.removeItem(at: baseDirectory)
        keychainController.removeAllRestorationTokens()
    }
    
    func restoreUserSession() async -> Result<UserSessionProtocol, UserSessionStoreError> {
        let availableCredentials = keychainController.restorationTokens()
        
        guard let credentials = availableCredentials.first else {
            return .failure(.missingCredentials)
        }
        
        switch await restorePreviousLogin(credentials) {
        case .success(let clientProxy):
            return .success(buildUserSessionWithClient(clientProxy))
        case .failure(let error):
            MXLog.error("Failed restoring login with error: \(error)")
            
            // On any restoration failure reset the token and restart
            keychainController.removeAllRestorationTokens()
            deleteSessionDirectory(for: credentials.userID)
            
            return .failure(error)
        }
    }
    
    func userSession(for client: Client) async -> Result<UserSessionProtocol, UserSessionStoreError> {
        switch await setupProxyForClient(client) {
        case .success(let clientProxy):
            return .success(buildUserSessionWithClient(clientProxy))
        case .failure(let error):
            MXLog.error("Failed creating user session with error: \(error)")
            return .failure(error)
        }
    }

    func refreshRestorationToken(for userSession: UserSessionProtocol) -> Result<Void, UserSessionStoreError> {
        guard let restorationToken = userSession.clientProxy.restorationToken else {
            return .failure(.failedRefreshingRestoreToken)
        }

        keychainController.setRestorationToken(restorationToken, forUsername: userSession.clientProxy.userID)

        return .success(())
    }
    
    func logout(userSession: UserSessionProtocol) {
        let userID = userSession.clientProxy.userID
        keychainController.removeRestorationTokenForUsername(userID)
        deleteSessionDirectory(for: userID)
    }
    
    // MARK: - Private
    
    private func buildUserSessionWithClient(_ clientProxy: ClientProxyProtocol) -> UserSessionProtocol {
        let imageCache = ImageCache.onlyInMemory
        imageCache.memoryStorage.config.keepWhenEnteringBackground = true
        
        return UserSession(clientProxy: clientProxy,
                           mediaProvider: MediaProvider(mediaProxy: clientProxy,
                                                        imageCache: imageCache,
                                                        fileCache: FileCache.default,
                                                        backgroundTaskService: backgroundTaskService))
    }
    
    private func restorePreviousLogin(_ credentials: KeychainCredentials) async -> Result<ClientProxyProtocol, UserSessionStoreError> {
        let builder = ClientBuilder()
            .basePath(path: baseDirectory.path)
            .username(username: credentials.userID)
            .homeserverUrl(url: credentials.restorationToken.session.homeserverUrl)
            .userAgent(userAgent: UserAgentBuilder.makeASCIIUserAgent() ?? "unknown")

        do {
            let client: Client = try await Task.dispatch(on: .global()) {
                let client = try builder.build()
                try client.restoreSession(session: credentials.restorationToken.session)
                return client
            }
            return await setupProxyForClient(client)
        } catch {
            MXLog.error("Failed restoring login with error: \(error)")
            return .failure(.failedRestoringLogin)
        }
    }
    
    private func setupProxyForClient(_ client: Client) async -> Result<ClientProxyProtocol, UserSessionStoreError> {
        do {
            let session = try client.session()
            let userId = try client.userId()
            
            keychainController.setRestorationToken(RestorationToken(session: session), forUsername: userId)
        } catch {
            MXLog.error("Failed setting up user session with error: \(error)")
            return .failure(.failedSettingUpSession)
        }
        
        let clientProxy = await ClientProxy(client: client, backgroundTaskService: backgroundTaskService)
        
        return .success(clientProxy)
    }
    
    private func deleteSessionDirectory(for userID: String) {
        // Rust sanitises the user ID replacing invalid characters with an _
        let sanitisedUserID = userID.replacingOccurrences(of: ":", with: "_")
        let url = baseDirectory.appendingPathComponent(sanitisedUserID)
        
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            MXLog.failure("Failed deleting the session data: \(error)")
        }
    }
}
