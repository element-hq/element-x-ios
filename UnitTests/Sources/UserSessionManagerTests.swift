//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
struct UserSessionManagerTests {
    let userSessionStore = UserSessionStoreMock()
    let appSettings = AppSettings.volatile()
    
    @Test(arguments: [
        // An upgrade from a single account, before any order was stored.
        ([String](), ["@alice:matrix.org"], ["@alice:matrix.org"]),
        // A stale account is dropped, the stored order wins.
        (["@bob:matrix.org", "@alice:matrix.org", "@gone:matrix.org"], ["@alice:matrix.org", "@bob:matrix.org"], ["@bob:matrix.org", "@alice:matrix.org"]),
        // Accounts missing from the stored order are appended, sorted.
        (["@bob:matrix.org"], ["@carol:matrix.org", "@bob:matrix.org", "@alice:matrix.org"], ["@bob:matrix.org", "@alice:matrix.org", "@carol:matrix.org"])
    ])
    func reconcilesTheStoredOrderWithTheKeychain(storedUserIDs: [String], keychainUserIDs: [String], expectedUserIDs: [String]) {
        appSettings.recentUserIDs = storedUserIDs
        userSessionStore.userIDs = keychainUserIDs
        
        let manager = UserSessionManager(userSessionStore: userSessionStore, appSettings: appSettings)
        
        #expect(manager.userIDs == expectedUserIDs)
        #expect(appSettings.recentUserIDs == expectedUserIDs)
    }
    
    @Test
    func restoreFallsBackToTheNextAccount() async {
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        // Alice already has a live session, e.g. when restoring again after clearing the cache.
        manager.add(makeUserSession(userID: "@alice:matrix.org"))
        let bob = makeUserSession(userID: "@bob:matrix.org")
        userSessionStore.restoreUserSessionUserIDClosure = { userID in
            userID == "@bob:matrix.org" ? .success(bob) : .failure(.failedRestoringLogin)
        }
        
        guard case .success(let userSession) = await manager.restoreActiveSession() else {
            Issue.record("Restoring should fall back to Bob.")
            return
        }
        
        #expect(userSession.clientProxy.userID == "@bob:matrix.org")
        #expect(manager.userIDs == ["@bob:matrix.org"])
        #expect(appSettings.recentUserIDs == ["@bob:matrix.org"])
        #expect(manager.session(for: "@alice:matrix.org") == nil)
        // Nothing can use the session until it's added, e.g. while migrations run.
        #expect(manager.activeSession == nil)
    }
    
    @Test
    func restoreFailsWhenNoAccountCanBeRestored() async {
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        userSessionStore.restoreUserSessionUserIDReturnValue = .failure(.failedRestoringLogin)
        
        guard case .failure(.failedRestoringSessions) = await manager.restoreActiveSession() else {
            Issue.record("Restoring should fail once every account has failed.")
            return
        }
        
        #expect(userSessionStore.restoreUserSessionUserIDReceivedInvocations == ["@alice:matrix.org", "@bob:matrix.org"])
        #expect(manager.userIDs.isEmpty)
    }
    
    @Test
    func addRegistersTheSession() {
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        
        // A known account keeps its place, e.g. after clearing the cache.
        let bob = makeUserSession(userID: "@bob:matrix.org")
        manager.add(bob)
        #expect(manager.userIDs == ["@alice:matrix.org", "@bob:matrix.org"])
        #expect((manager.session(for: "@bob:matrix.org") as? UserSessionMock) === bob)
        #expect(manager.activeSession == nil)
        
        // A new account becomes the active one.
        let carol = makeUserSession(userID: "@carol:matrix.org")
        manager.add(carol)
        #expect(manager.userIDs == ["@carol:matrix.org", "@alice:matrix.org", "@bob:matrix.org"])
        #expect(appSettings.recentUserIDs == manager.userIDs)
        #expect((manager.activeSession as? UserSessionMock) === carol)
        #expect(manager.sessions.map(\.clientProxy.userID) == ["@carol:matrix.org", "@bob:matrix.org"])
    }
    
    @Test
    func addReplacesTheSessionOfAKnownAccount() {
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        manager.add(makeUserSession(userID: "@alice:matrix.org"))
        
        // E.g. restoring again after clearing the cache, or signing in again after a soft logout.
        let newAlice = makeUserSession(userID: "@alice:matrix.org")
        manager.add(newAlice)
        
        #expect(manager.userIDs == ["@alice:matrix.org", "@bob:matrix.org"])
        #expect((manager.activeSession as? UserSessionMock) === newAlice)
    }
    
    @Test
    func removeDeletesTheAccount() {
        let manager = makeManager(userIDs: ["@alice:matrix.org"])
        let alice = makeUserSession(userID: "@alice:matrix.org")
        manager.add(alice)
        
        manager.remove(userID: "@alice:matrix.org")
        
        #expect((userSessionStore.logoutUserSessionReceivedUserSession as? UserSessionMock) === alice)
        #expect(manager.userIDs.isEmpty)
        #expect(manager.activeSession == nil)
        #expect(appSettings.recentUserIDs.isEmpty)
    }
    
    // MARK: - Helpers
    
    private func makeManager(userIDs: [String]) -> UserSessionManager {
        userSessionStore.userIDs = userIDs
        return UserSessionManager(userSessionStore: userSessionStore, appSettings: appSettings)
    }
    
    private func makeUserSession(userID: String) -> UserSessionMock {
        UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: userID))))
    }
}
