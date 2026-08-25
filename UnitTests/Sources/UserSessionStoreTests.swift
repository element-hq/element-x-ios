//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import MatrixRustSDK
import MatrixRustSDKMocks
import Testing

@MainActor
struct UserSessionStoreTests {
    let keychainController = KeychainControllerMock()
    let clientFactory = ClientFactoryMock()
    let store: UserSessionStore
    
    init() {
        keychainController.restorationTokensReturnValue = []
        
        store = UserSessionStore(keychainController: keychainController,
                                 clientFactory: clientFactory,
                                 appSettings: .volatile(),
                                 analyticsService: AnalyticsServiceMock(),
                                 appHooks: AppHooks(),
                                 networkMonitor: NetworkMonitorMock(.init()))
    }
    
    // MARK: - Accessors
    
    @Test
    func hasSessions() {
        #expect(!store.hasSessions)
        
        keychainController.restorationTokensReturnValue = [makeCredentials(sessionDirectories: .init())]
        #expect(store.hasSessions)
    }
    
    @Test
    func userIDs() {
        keychainController.restorationTokensReturnValue = [makeCredentials(sessionDirectories: .init(), userID: "@alice:matrix.org"),
                                                           makeCredentials(sessionDirectories: .init(), userID: "@bob:matrix.org")]
        #expect(store.userIDs == ["@alice:matrix.org", "@bob:matrix.org"])
    }
    
    // MARK: - Restoration
    
    @Test
    func restoreWithoutCredentials() async {
        guard case .failure(.missingCredentials) = await store.restoreUserSession() else {
            Issue.record("Restoration should fail when there are no credentials.")
            return
        }
    }
    
    @Test
    func restoreWithMissingUserData() async {
        // Given credentials whose session data is no longer on disk.
        let credentials = makeCredentials(sessionDirectories: .init())
        keychainController.restorationTokensReturnValue = [credentials]
        
        // When restoring the session.
        guard case .failure(.failedRestoringLogin) = await store.restoreUserSession() else {
            Issue.record("Restoration should fail when the non-transient user data is missing.")
            return
        }
        
        // Then the credentials should have been discarded.
        #expect(keychainController.removeRestorationTokenForUsernameReceivedInvocations == [credentials.userID])
    }
    
    @Test
    func restoreWhenClientCreationFails() async throws {
        // Given valid session data but a client factory that fails.
        let sessionDirectories = try makeValidSessionDirectories()
        defer { sessionDirectories.delete() }
        let credentials = makeCredentials(sessionDirectories: sessionDirectories)
        keychainController.restorationTokensReturnValue = [credentials]
        clientFactory.makeAppClientCredentialsClientSessionDelegateAppSettingsAppHooksThrowableError = TestError.generic
        
        // When restoring the session.
        guard case .failure(.failedRestoringLogin) = await store.restoreUserSession() else {
            Issue.record("Restoration should fail when the client can't be created.")
            return
        }
        
        // Then the credentials should have been discarded.
        #expect(keychainController.removeRestorationTokenForUsernameReceivedInvocations == [credentials.userID])
    }
    
    @Test
    func restoreSucceeds() async throws {
        // Given valid session data and a client factory that returns a client.
        let sessionDirectories = try makeValidSessionDirectories()
        defer { sessionDirectories.delete() }
        keychainController.restorationTokensReturnValue = [makeCredentials(sessionDirectories: sessionDirectories)]
        clientFactory.makeAppClientCredentialsClientSessionDelegateAppSettingsAppHooksReturnValue = ClientSDKMock(.init(userID: "@alice:matrix.org"))
        
        // When restoring the session.
        guard case .success(let userSession) = await store.restoreUserSession() else {
            Issue.record("Restoration should succeed.")
            return
        }
        
        // Then a user session should be built for the restored client.
        #expect(userSession.clientProxy.userID == "@alice:matrix.org")
    }
    
    // MARK: - Session creation
    
    @Test
    func userSessionForClientSucceeds() async {
        // Given a freshly authenticated client from the SDK.
        let client = ClientSDKMock(.init(userID: "@alice:matrix.org"))
        let sessionDirectories = SessionDirectories()
        
        // When creating a user session for it.
        guard case .success(let userSession) = await store.userSession(for: client, sessionDirectories: sessionDirectories, passphrase: "passphrase") else {
            Issue.record("Creating the session should succeed.")
            return
        }
        
        // Then the session should be built and its restoration token persisted.
        #expect(userSession.clientProxy.userID == "@alice:matrix.org")
        #expect(keychainController.setRestorationTokenForUsernameReceivedArguments?.forUsername == "@alice:matrix.org")
        #expect(keychainController.setRestorationTokenForUsernameReceivedArguments?.restorationToken.passphrase == "passphrase")
    }
    
    @Test
    func userSessionForClientFails() async {
        // Given a freshly authenticated client that fails to provide its session.
        let client = ClientSDKMock(.init(userID: "@alice:matrix.org"))
        client.sessionThrowableError = TestError.generic
        
        // When creating a user session for it.
        guard case .failure(.failedSettingUpSession) = await store.userSession(for: client, sessionDirectories: .init(), passphrase: "passphrase") else {
            Issue.record("Creating the session should fail.")
            return
        }
        
        // Then nothing should have been persisted.
        #expect(!keychainController.setRestorationTokenForUsernameCalled)
    }
    
    // MARK: - Logout/Reset
    
    @Test
    func logout() {
        // Given a stored session.
        let userID = "@alice:matrix.org"
        keychainController.restorationTokensReturnValue = [makeCredentials(sessionDirectories: .init(), userID: userID)]
        let userSession = UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: userID))))
        
        // When logging out.
        store.logout(userSession: userSession)
        
        // Then the stored credentials should be removed.
        #expect(keychainController.removeRestorationTokenForUsernameReceivedInvocations == [userID])
    }
    
    @Test
    func reset() {
        store.reset()
        #expect(keychainController.removeAllRestorationTokensCalled)
    }
    
    // MARK: - Helpers
    
    private enum TestError: Error { case generic }
    
    private func makeCredentials(sessionDirectories: SessionDirectories, userID: String = "@alice:matrix.org") -> KeychainCredentials {
        let session = Session(accessToken: "accessToken",
                              refreshToken: nil,
                              userId: userID,
                              deviceId: "deviceID",
                              homeserverUrl: "https://matrix.org",
                              oauthData: nil,
                              slidingSyncVersion: .native)
        let restorationToken = RestorationToken(session: session,
                                                sessionDirectories: sessionDirectories,
                                                passphrase: "passphrase",
                                                pusherNotificationClientIdentifier: nil)
        return KeychainCredentials(userID: userID, restorationToken: restorationToken)
    }
    
    private func makeValidSessionDirectories() throws -> SessionDirectories {
        let sessionDirectories = SessionDirectories()
        try FileManager.default.createDirectory(at: sessionDirectories.dataDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: sessionDirectories.cacheDirectory, withIntermediateDirectories: true)
        sessionDirectories.generateMockData()
        return sessionDirectories
    }
}
