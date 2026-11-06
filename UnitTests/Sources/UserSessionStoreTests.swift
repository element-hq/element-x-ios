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
    let keychainController = KeychainControllerMock(.init())
    let clientFactory = ClientFactoryMock(.init())
    let appSettings = AppSettings.volatile()
    let store: UserSessionStore
    
    init() {
        store = UserSessionStore(keychainController: keychainController,
                                 clientFactory: clientFactory,
                                 appSettings: appSettings,
                                 analyticsService: AnalyticsServiceMock(.init()),
                                 appHooks: AppHooks(),
                                 networkMonitor: NetworkMonitorMock(.init()))
    }
    
    // MARK: - Accessors
    
    @Test("The store has sessions once credentials are stored")
    func hasSessions() {
        #expect(!store.hasSessions)
        
        keychainController.restorationTokensReturnValue = [makeCredentials(sessionDirectories: .init())]
        #expect(store.hasSessions)
    }
    
    @Test("The user IDs come from the stored credentials")
    func userIDs() {
        keychainController.restorationTokensReturnValue = [makeCredentials(sessionDirectories: .init(), userID: "@alice:matrix.org"),
                                                           makeCredentials(sessionDirectories: .init(), userID: "@bob:matrix.org")]
        #expect(store.userIDs == ["@alice:matrix.org", "@bob:matrix.org"])
    }
    
    // MARK: - Restoration
    
    @Test("Restoring an account without credentials fails")
    func restoreUnknownAccount() async {
        guard case .failure(.unknownAccount) = await store.restoreUserSession(userID: "@alice:matrix.org") else {
            Issue.record("Restoration should fail when there are no credentials.")
            return
        }
    }
    
    @Test("Restoring without the account's data fails and discards its credentials and settings")
    func restoreWithMissingUserData() async {
        // Given credentials whose session data is no longer on disk.
        let credentials = makeCredentials(sessionDirectories: .init())
        keychainController.restorationTokensReturnValue = [credentials]
        appSettings.userSettings(for: credentials.userID).account.seenInvites = ["!room:matrix.org"]
        
        // When restoring the session.
        guard case .failure(.failedRestoringLogin) = await store.restoreUserSession(userID: credentials.userID) else {
            Issue.record("Restoration should fail when the non-transient user data is missing.")
            return
        }
        
        // Then the credentials and settings should have been discarded.
        #expect(keychainController.removeRestorationTokenForUsernameReceivedInvocations == [credentials.userID])
        #expect(appSettings.userSettings(for: credentials.userID).account.seenInvites.isEmpty)
    }
    
    @Test("Restoring fails and discards the credentials when the client can't be created")
    func restoreWhenClientCreationFails() async throws {
        // Given valid session data but a client factory that fails.
        let sessionDirectories = try makeValidSessionDirectories()
        defer { try? sessionDirectories.delete() }
        let credentials = makeCredentials(sessionDirectories: sessionDirectories)
        keychainController.restorationTokensReturnValue = [credentials]
        clientFactory.makeAppClientCredentialsClientSessionDelegateAppSettingsAppHooksThrowableError = TestError.generic
        
        // When restoring the session.
        guard case .failure(.failedRestoringLogin) = await store.restoreUserSession(userID: credentials.userID) else {
            Issue.record("Restoration should fail when the client can't be created.")
            return
        }
        
        // Then the credentials should have been discarded.
        #expect(keychainController.removeRestorationTokenForUsernameReceivedInvocations == [credentials.userID])
    }
    
    @Test("Restoring builds a user session for the account's client")
    func restoreSucceeds() async throws {
        // Given valid session data for Alice, stored after another account.
        let sessionDirectories = try makeValidSessionDirectories()
        defer { try? sessionDirectories.delete() }
        keychainController.restorationTokensReturnValue = [makeCredentials(sessionDirectories: .init(), userID: "@bob:matrix.org"),
                                                           makeCredentials(sessionDirectories: sessionDirectories)]
        
        // When restoring Alice's session.
        guard case .success(let userSession) = await store.restoreUserSession(userID: "@alice:matrix.org") else {
            Issue.record("Restoration should succeed.")
            return
        }
        
        // Then a user session should be built for Alice's client.
        #expect(userSession.clientProxy.userID == "@alice:matrix.org")
    }
    
    // MARK: - Session creation
    
    @Test("A user session is built for a new client and its credentials are stored")
    func userSessionForClientSucceeds() async {
        // Given a freshly authenticated client from the SDK.
        let client = ClientSDKMock(.init(userID: "@alice:matrix.org"))
        let sessionDirectories = SessionDirectories()
        
        // When creating a user session for it.
        guard case .success(let userSession) = await store.userSession(for: client, sessionDirectories: sessionDirectories, passphrase: RestorationTokenFixtures.passphrase) else {
            Issue.record("Creating the session should succeed.")
            return
        }
        
        // Then the session should be built and its restoration token persisted.
        #expect(userSession.clientProxy.userID == "@alice:matrix.org")
        #expect(keychainController.setRestorationTokenForUsernameReceivedArguments?.forUsername == "@alice:matrix.org")
        #expect(keychainController.setRestorationTokenForUsernameReceivedArguments?.restorationToken.passphrase == RestorationTokenFixtures.passphrase)
    }
    
    @Test("Nothing is stored when a new client can't provide its session")
    func userSessionForClientFails() async {
        // Given a freshly authenticated client that fails to provide its session.
        let client = ClientSDKMock(.init(userID: "@alice:matrix.org"))
        client.sessionThrowableError = TestError.generic
        
        // When creating a user session for it.
        guard case .failure(.failedSettingUpSession) = await store.userSession(for: client, sessionDirectories: .init(), passphrase: RestorationTokenFixtures.passphrase) else {
            Issue.record("Creating the session should fail.")
            return
        }
        
        // Then nothing should have been persisted.
        #expect(!keychainController.setRestorationTokenForUsernameCalled)
    }
    
    // MARK: - Logout/Reset
    
    @Test("Logging out deletes the account's credentials and settings")
    func logout() {
        // Given a stored session with some account settings.
        let userID = "@alice:matrix.org"
        keychainController.restorationTokensReturnValue = [makeCredentials(sessionDirectories: .init(), userID: userID)]
        appSettings.userSettings(for: userID).account.seenInvites = ["!room:matrix.org"]
        
        // When logging out.
        store.logout(userID: userID)
        
        // Then the stored credentials and settings should be removed.
        #expect(keychainController.removeRestorationTokenForUsernameReceivedInvocations == [userID])
        #expect(appSettings.userSettings(for: userID).account.seenInvites.isEmpty)
    }
    
    @Test("Resetting deletes every account's credentials")
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
                                                passphrase: RestorationTokenFixtures.passphrase,
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
