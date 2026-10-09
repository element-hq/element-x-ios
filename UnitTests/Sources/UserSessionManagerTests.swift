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
    
    @Test
    func ordersAccountsByWhenTheyWereLastSelected() {
        appSettings.userSettings(for: "@alice:matrix.org").account.lastSelectedDate = .now.addingTimeInterval(-60)
        appSettings.userSettings(for: "@bob:matrix.org").account.lastSelectedDate = .now
        
        // Accounts that were never selected (e.g. after upgrading from a single account) come last.
        let manager = makeManager(userIDs: ["@dave:matrix.org", "@alice:matrix.org", "@carol:matrix.org", "@bob:matrix.org"])
        
        #expect(manager.userIDs == ["@bob:matrix.org", "@alice:matrix.org", "@carol:matrix.org", "@dave:matrix.org"])
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
    func onlyTheActiveAccountsRemoteSettingsAreApplied() async {
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        
        // Another account's remote settings must never replace the active account's.
        userSessionStore.restoreUserSessionUserIDReturnValue = .success(makeUserSession(userID: "@bob:matrix.org"))
        _ = await manager.restoreUserSession(userID: "@bob:matrix.org")
        #expect(!userSessionStore.applyRemoteSettingsForUserIDCalled)
        
        userSessionStore.restoreUserSessionUserIDReturnValue = .success(makeUserSession(userID: "@alice:matrix.org"))
        _ = await manager.restoreActiveSession()
        #expect(userSessionStore.applyRemoteSettingsForUserIDReceivedInvocations == ["@alice:matrix.org"])
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
        #expect(appSettings.userSettings(for: "@carol:matrix.org").account.lastSelectedDate != nil)
        #expect((manager.activeSession as? UserSessionMock) === carol)
        #expect(manager.sessionsPublisher.value.map(\.clientProxy.userID) == ["@carol:matrix.org", "@bob:matrix.org"])
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
    }
    
    @Test
    func resumingAndPausingReachEverySession() async {
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        let aliceClientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org"))
        let bobClientProxy = ClientProxyMock(.init(userID: "@bob:matrix.org"))
        manager.add(UserSessionMock(.init(clientProxy: aliceClientProxy)))
        manager.add(UserSessionMock(.init(clientProxy: bobClientProxy)))
        
        await manager.resumeServices()
        #expect(aliceClientProxy.resumeServicesCallsCount == 1)
        #expect(bobClientProxy.resumeServicesCallsCount == 1)
        
        await manager.pauseServices()
        #expect(aliceClientProxy.pauseServicesCallsCount == 1)
        #expect(bobClientProxy.pauseServicesCallsCount == 1)
    }
    
    @Test
    func restoringTheOtherSessionsResumesThemWhileServicesRun() async {
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        manager.add(makeUserSession(userID: "@alice:matrix.org"))
        let bobClientProxy = ClientProxyMock(.init(userID: "@bob:matrix.org"))
        userSessionStore.restoreUserSessionUserIDReturnValue = .success(UserSessionMock(.init(clientProxy: bobClientProxy)))
        await manager.resumeServices()
        
        await confirmation("Bob is prepared before being added") { prepared in
            await manager.restoreOtherSessions { userSession in
                #expect(userSession.clientProxy.userID == "@bob:matrix.org")
                #expect(manager.session(for: "@bob:matrix.org") == nil)
                prepared()
            }
        }
        
        #expect(userSessionStore.restoreUserSessionUserIDReceivedInvocations == ["@bob:matrix.org"])
        #expect(manager.sessionsPublisher.value.map(\.clientProxy.userID) == ["@alice:matrix.org", "@bob:matrix.org"])
        #expect(bobClientProxy.resumeServicesCalled)
    }
    
    @Test
    func restoringTheOtherSessionsDoesntResumeThemWhilePaused() async {
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        manager.add(makeUserSession(userID: "@alice:matrix.org"))
        let bobClientProxy = ClientProxyMock(.init(userID: "@bob:matrix.org"))
        userSessionStore.restoreUserSessionUserIDReturnValue = .success(UserSessionMock(.init(clientProxy: bobClientProxy)))
        
        // E.g. a background launch, which pauses the sessions when its task completes.
        await manager.restoreOtherSessions { _ in }
        
        #expect(manager.sessionsPublisher.value.map(\.clientProxy.userID) == ["@alice:matrix.org", "@bob:matrix.org"])
        #expect(!bobClientProxy.resumeServicesCalled)
    }
    
    @Test
    func restoringTheOtherSessionsWithASingleAccountDoesNothing() async {
        let manager = makeManager(userIDs: ["@alice:matrix.org"])
        manager.add(makeUserSession(userID: "@alice:matrix.org"))
        await manager.resumeServices()
        
        await confirmation("There's no other account to prepare", expectedCount: 0) { prepared in
            await manager.restoreOtherSessions { _ in prepared() }
        }
        
        #expect(!userSessionStore.restoreUserSessionUserIDCalled)
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
