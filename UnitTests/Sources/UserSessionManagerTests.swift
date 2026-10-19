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
    let notificationManager = NotificationManagerMock()
    let liveLocationManager = LiveLocationManagerMock()
    
    @Test
    func ordersAccountsByWhenTheyWereLastSelected() {
        appSettings.userSettings(for: "@alice:matrix.org").account.lastSelectedDate = .now.addingTimeInterval(-60)
        appSettings.userSettings(for: "@bob:matrix.org").account.lastSelectedDate = .now
        
        // Accounts that were never selected (e.g. after upgrading from a single account) come last.
        let manager = makeManager(userIDs: ["@dave:matrix.org", "@alice:matrix.org", "@carol:matrix.org", "@bob:matrix.org"])
        
        #expect(manager.userIDs == ["@bob:matrix.org", "@alice:matrix.org", "@carol:matrix.org", "@dave:matrix.org"])
    }
    
    @Test
    func restoringFallsBackToTheNextAccount() async {
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        let bob = makeUserSession(userID: "@bob:matrix.org")
        userSessionStore.restoreUserSessionUserIDClosure = { userID in
            userID == "@bob:matrix.org" ? .success(bob) : .failure(.failedRestoringLogin)
        }
        let recorder = RestorationRecorder()
        
        await manager.restoreSessions { userSession in
            // Migrations run before the session can be used.
            #expect(manager.session(for: userSession.clientProxy.userID) == nil)
            recorder.preparedUserIDs.append(userSession.clientProxy.userID)
        } didAdd: { recorder.addedUserIDs.append($0.clientProxy.userID) }
        
        #expect(userSessionStore.restoreUserSessionUserIDReceivedInvocations == ["@alice:matrix.org", "@bob:matrix.org"])
        #expect(recorder.preparedUserIDs == ["@bob:matrix.org"])
        #expect(recorder.addedUserIDs == ["@bob:matrix.org"])
        // The store deletes an account that fails to restore.
        #expect(manager.userIDs == ["@bob:matrix.org"])
        #expect((manager.activeSession as? UserSessionMock) === bob)
    }
    
    @Test
    func restoringRemovesEveryAccountThatFails() async {
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        userSessionStore.restoreUserSessionUserIDReturnValue = .failure(.failedRestoringLogin)
        let recorder = RestorationRecorder()
        
        await manager.restoreSessions { recorder.preparedUserIDs.append($0.clientProxy.userID) } didAdd: { recorder.addedUserIDs.append($0.clientProxy.userID) }
        
        #expect(userSessionStore.restoreUserSessionUserIDReceivedInvocations == ["@alice:matrix.org", "@bob:matrix.org"])
        #expect(manager.userIDs.isEmpty)
        #expect(manager.activeSession == nil)
        #expect(recorder.preparedUserIDs.isEmpty)
        #expect(recorder.addedUserIDs.isEmpty)
    }
    
    @Test
    func restoringMakesOnlyOneAccountLiveWithoutMultiAccount() async {
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        let sessions = ["@alice:matrix.org": makeUserSession(userID: "@alice:matrix.org"), "@bob:matrix.org": makeUserSession(userID: "@bob:matrix.org")]
        userSessionStore.restoreUserSessionUserIDClosure = { userID in sessions[userID].map { .success($0) } ?? .failure(.failedRestoringLogin) }
        
        await manager.restoreSessions { _ in } didAdd: { _ in }
        
        #expect(userSessionStore.restoreUserSessionUserIDReceivedInvocations == ["@alice:matrix.org"])
        #expect(manager.userIDs == ["@alice:matrix.org", "@bob:matrix.org"])
        #expect(manager.sessionsPublisher.value.map(\.clientProxy.userID) == ["@alice:matrix.org"])
    }
    
    @Test
    func restoringMakesEveryAccountLiveWithMultiAccount() async {
        appSettings.multiAccountEnabled = true
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        let aliceClientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org"))
        let bobClientProxy = ClientProxyMock(.init(userID: "@bob:matrix.org"))
        let sessions = ["@alice:matrix.org": UserSessionMock(.init(clientProxy: aliceClientProxy)), "@bob:matrix.org": UserSessionMock(.init(clientProxy: bobClientProxy))]
        userSessionStore.restoreUserSessionUserIDClosure = { userID in sessions[userID].map { .success($0) } ?? .failure(.failedRestoringLogin) }
        await manager.resumeServices()
        let recorder = RestorationRecorder()
        
        await manager.restoreSessions { _ in } didAdd: { recorder.addedUserIDs.append($0.clientProxy.userID) }
        
        #expect(userSessionStore.restoreUserSessionUserIDReceivedInvocations == ["@alice:matrix.org", "@bob:matrix.org"])
        #expect(recorder.addedUserIDs == ["@alice:matrix.org", "@bob:matrix.org"])
        #expect(aliceClientProxy.resumeServicesCalled)
        #expect(bobClientProxy.resumeServicesCalled)
        #expect(manager.activeSession?.clientProxy.userID == "@alice:matrix.org")
    }
    
    @Test
    func restoringSkipsLiveAccounts() async {
        appSettings.multiAccountEnabled = true
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        manager.add(makeUserSession(userID: "@alice:matrix.org"))
        userSessionStore.restoreUserSessionUserIDReturnValue = .success(makeUserSession(userID: "@bob:matrix.org"))
        
        await manager.restoreSessions { _ in } didAdd: { _ in }
        #expect(userSessionStore.restoreUserSessionUserIDReceivedInvocations == ["@bob:matrix.org"])
        
        // Once every account is live, there's nothing left to restore.
        await manager.restoreSessions { _ in } didAdd: { _ in }
        #expect(userSessionStore.restoreUserSessionUserIDCallsCount == 1)
    }
    
    @Test
    func restoringDoesntResumeSessionsWhilePaused() async {
        let manager = makeManager(userIDs: ["@alice:matrix.org"])
        let aliceClientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org"))
        userSessionStore.restoreUserSessionUserIDReturnValue = .success(UserSessionMock(.init(clientProxy: aliceClientProxy)))
        
        // E.g. a background launch, which pauses the sessions when its task completes.
        await manager.restoreSessions { _ in } didAdd: { _ in }
        
        #expect(manager.activeSession != nil)
        #expect(!aliceClientProxy.resumeServicesCalled)
    }
    
    @Test
    func restoringStopsOnceCancelled() async {
        appSettings.multiAccountEnabled = true
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        userSessionStore.restoreUserSessionUserIDReturnValue = .success(makeUserSession(userID: "@alice:matrix.org"))
        
        // E.g. signing out while an account is being migrated.
        await Task {
            await manager.restoreSessions { _ in withUnsafeCurrentTask { $0?.cancel() } } didAdd: { _ in }
        }.value
        
        #expect(userSessionStore.restoreUserSessionUserIDReceivedInvocations == ["@alice:matrix.org"])
        #expect(manager.activeSession == nil)
        #expect(manager.userIDs == ["@alice:matrix.org", "@bob:matrix.org"])
    }
    
    @Test
    func clearingCachesReplacesTheSessionOnTheNextRestore() async {
        appSettings.multiAccountEnabled = true
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        let aliceClientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org"))
        aliceClientProxy.clearCachesReturnValue = .success(())
        let oldAlice = UserSessionMock(.init(clientProxy: aliceClientProxy))
        let bob = makeUserSession(userID: "@bob:matrix.org")
        manager.add(oldAlice)
        manager.add(bob)
        
        await manager.clearCaches(userID: "@alice:matrix.org")
        #expect(aliceClientProxy.clearCachesCalled)
        
        let newAlice = makeUserSession(userID: "@alice:matrix.org")
        userSessionStore.restoreUserSessionUserIDReturnValue = .success(newAlice)
        await manager.restoreSessions { _ in
            // The cleared session stays live until the new one replaces it.
            #expect((manager.activeSession as? UserSessionMock) === oldAlice)
        } didAdd: { _ in }
        
        #expect(userSessionStore.restoreUserSessionUserIDReceivedInvocations == ["@alice:matrix.org"])
        #expect((manager.activeSession as? UserSessionMock) === newAlice)
        #expect((manager.session(for: "@bob:matrix.org") as? UserSessionMock) === bob)
        
        await manager.restoreSessions { _ in } didAdd: { _ in }
        #expect(userSessionStore.restoreUserSessionUserIDCallsCount == 1)
    }
    
    @Test
    func restoringAfterClearingCachesFallsBackToALiveAccount() async {
        appSettings.multiAccountEnabled = true
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        let aliceClientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org"))
        aliceClientProxy.clearCachesReturnValue = .success(())
        manager.add(UserSessionMock(.init(clientProxy: aliceClientProxy)))
        let bob = makeUserSession(userID: "@bob:matrix.org")
        manager.add(bob)
        userSessionStore.restoreUserSessionUserIDReturnValue = .failure(.failedRestoringLogin)
        
        await manager.clearCaches(userID: "@alice:matrix.org")
        await manager.restoreSessions { _ in } didAdd: { _ in }
        
        #expect(userSessionStore.restoreUserSessionUserIDReceivedInvocations == ["@alice:matrix.org"])
        #expect(manager.userIDs == ["@bob:matrix.org"])
        #expect((manager.activeSession as? UserSessionMock) === bob)
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
    func addingASessionConnectsItsServices() {
        let manager = makeManager(userIDs: [])
        let alice = makeUserSession(userID: "@alice:matrix.org")
        
        manager.add(alice)
        
        #expect(notificationManager.addReceivedService === alice.notificationService)
        #expect(liveLocationManager.addReceivedService === alice.liveLocationService)
    }
    
    @Test
    func removingAnAccountDisconnectsItsServices() {
        let manager = makeManager(userIDs: ["@alice:matrix.org"])
        manager.add(makeUserSession(userID: "@alice:matrix.org"))
        
        manager.remove(userID: "@alice:matrix.org")
        
        #expect(notificationManager.removeUserIDReceivedInvocations == ["@alice:matrix.org"])
        #expect(liveLocationManager.removeUserIDReceivedInvocations == ["@alice:matrix.org"])
    }
    
    @Test
    func resettingDisconnectsEveryService() {
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        manager.add(makeUserSession(userID: "@alice:matrix.org"))
        
        manager.reset()
        
        #expect(Set(notificationManager.removeUserIDReceivedInvocations) == ["@alice:matrix.org", "@bob:matrix.org"])
        #expect(Set(liveLocationManager.removeUserIDReceivedInvocations) == ["@alice:matrix.org", "@bob:matrix.org"])
    }
    
    @Test
    func aFailedRestoreDisconnectsTheAccountsServices() async {
        let manager = makeManager(userIDs: ["@alice:matrix.org"])
        userSessionStore.restoreUserSessionUserIDReturnValue = .failure(.failedRestoringLogin)
        
        await manager.restoreSessions { _ in } didAdd: { _ in }
        
        #expect(notificationManager.removeUserIDReceivedInvocations == ["@alice:matrix.org"])
        #expect(liveLocationManager.removeUserIDReceivedInvocations == ["@alice:matrix.org"])
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
    func reportsTheAuthErrorsOfTheLiveSessions() async throws {
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        manager.add(makeUserSession(userID: "@alice:matrix.org"))
        let bob = makeUserSession(userID: "@bob:matrix.org")
        manager.add(bob)
        
        let deferred = deferFulfillment(manager.callbacksPublisher) { $0 == .didReceiveAuthError(userID: "@bob:matrix.org", isSoftLogout: true) }
        bob.callbacks.send(.didReceiveAuthError(isSoftLogout: true))
        try await deferred.fulfill()
        
        // A replaced session (e.g. after clearing the cache) mustn't report anything anymore.
        let deferredFailure = deferFailure(manager.callbacksPublisher, timeout: .seconds(1)) { _ in true }
        manager.add(makeUserSession(userID: "@bob:matrix.org"))
        bob.callbacks.send(.didReceiveAuthError(isSoftLogout: false))
        try await deferredFailure.fulfill()
    }
    
    // MARK: - Helpers
    
    private func makeManager(userIDs: [String]) -> UserSessionManager {
        userSessionStore.userIDs = userIDs
        return UserSessionManager(userSessionStore: userSessionStore,
                                  appSettings: appSettings,
                                  notificationManager: notificationManager,
                                  liveLocationManager: liveLocationManager)
    }
    
    private func makeUserSession(userID: String) -> UserSessionMock {
        UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: userID))))
    }
}

private final class RestorationRecorder {
    var preparedUserIDs: [String] = []
    var addedUserIDs: [String] = []
}
