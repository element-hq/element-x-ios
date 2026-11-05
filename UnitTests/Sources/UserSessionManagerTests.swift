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
    let elementCallManager = ElementCallManagerMock()
    
    @Test("Accounts are ordered by when they were last selected")
    func accountOrder() {
        appSettings.userSettings(for: "@alice:matrix.org").account.lastSelectedDate = .now.addingTimeInterval(-60)
        appSettings.userSettings(for: "@bob:matrix.org").account.lastSelectedDate = .now
        
        // Accounts that were never selected (e.g. after upgrading from a single account) come last.
        let manager = makeManager(userIDs: ["@dave:matrix.org", "@alice:matrix.org", "@carol:matrix.org", "@bob:matrix.org"])
        
        #expect(manager.userIDs == ["@bob:matrix.org", "@alice:matrix.org", "@carol:matrix.org", "@dave:matrix.org"])
    }
    
    @Test("Restoring falls back to the next account when one fails")
    func restoreFallback() async {
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
    
    @Test("Restoring removes every account that fails")
    func restoreFailures() async {
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
    
    @Test("Restoring makes only one account live without multi-account")
    func restoreSingleAccount() async {
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        let sessions = ["@alice:matrix.org": makeUserSession(userID: "@alice:matrix.org"), "@bob:matrix.org": makeUserSession(userID: "@bob:matrix.org")]
        userSessionStore.restoreUserSessionUserIDClosure = { userID in sessions[userID].map { .success($0) } ?? .failure(.failedRestoringLogin) }
        
        await manager.restoreSessions { _ in } didAdd: { _ in }
        
        #expect(userSessionStore.restoreUserSessionUserIDReceivedInvocations == ["@alice:matrix.org"])
        #expect(manager.userIDs == ["@alice:matrix.org", "@bob:matrix.org"])
        #expect(manager.sessionsPublisher.value.map(\.clientProxy.userID) == ["@alice:matrix.org"])
    }
    
    @Test("Restoring makes every account live with multi-account")
    func restoreMultiAccount() async {
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
    
    @Test("Restoring skips accounts that are already live")
    func restoreSkipsLiveAccounts() async {
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
    
    @Test("Restoring doesn't resume sessions while the services are paused")
    func restoreWhilePaused() async {
        let manager = makeManager(userIDs: ["@alice:matrix.org"])
        let aliceClientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org"))
        userSessionStore.restoreUserSessionUserIDReturnValue = .success(UserSessionMock(.init(clientProxy: aliceClientProxy)))
        
        // E.g. a background launch, which pauses the sessions when its task completes.
        await manager.restoreSessions { _ in } didAdd: { _ in }
        
        #expect(manager.activeSession != nil)
        #expect(!aliceClientProxy.resumeServicesCalled)
    }
    
    @Test("Restoring stops once cancelled")
    func restoreCancellation() async {
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
    
    @Test("Clearing the caches replaces the session on the next restore")
    func clearCachesReplacesSession() async {
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
    
    @Test("Restoring after clearing the caches falls back to a live account")
    func restoreAfterClearingCaches() async {
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
    
    @Test("Adding a session registers it, making a new account the active one")
    func addSession() {
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
    
    @Test("Adding a session replaces the session of a known account")
    func addKnownAccount() {
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        manager.add(makeUserSession(userID: "@alice:matrix.org"))
        
        // E.g. restoring again after clearing the cache, or signing in again after a soft logout.
        let newAlice = makeUserSession(userID: "@alice:matrix.org")
        manager.add(newAlice)
        
        #expect(manager.userIDs == ["@alice:matrix.org", "@bob:matrix.org"])
        #expect((manager.activeSession as? UserSessionMock) === newAlice)
    }
    
    @Test("Removing an account deletes it")
    func removeAccount() {
        let manager = makeManager(userIDs: ["@alice:matrix.org"])
        let alice = makeUserSession(userID: "@alice:matrix.org")
        manager.add(alice)
        
        manager.remove(userID: "@alice:matrix.org")
        
        #expect((userSessionStore.logoutUserSessionReceivedUserSession as? UserSessionMock) === alice)
        #expect(manager.userIDs.isEmpty)
        #expect(manager.activeSession == nil)
    }
    
    @Test("Logging out tears down and removes only the given account")
    func logoutOneAccount() async {
        appSettings.multiAccountEnabled = true
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        let aliceClientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org"))
        let aliceNotificationService = NotificationServiceMock(.init())
        let aliceLiveLocationService = LiveLocationServiceMock(.init())
        let alice = UserSessionMock(.init(clientProxy: aliceClientProxy,
                                          liveLocationService: aliceLiveLocationService,
                                          notificationService: aliceNotificationService))
        alice.userSettings.account.seenInvites = ["!room:matrix.org"]
        let bobClientProxy = ClientProxyMock(.init(userID: "@bob:matrix.org"))
        let bobNotificationService = NotificationServiceMock(.init())
        let bobLiveLocationService = LiveLocationServiceMock(.init())
        let bob = UserSessionMock(.init(clientProxy: bobClientProxy,
                                        liveLocationService: bobLiveLocationService,
                                        notificationService: bobNotificationService))
        manager.add(alice)
        manager.add(bob)
        
        await manager.logout(userID: "@alice:matrix.org")
        
        #expect(aliceClientProxy.pauseServicesCalled)
        #expect(aliceNotificationService.tearDownCalled)
        #expect(aliceLiveLocationService.stopAllLiveLocationsCalled)
        #expect(aliceClientProxy.logoutCalled)
        #expect((userSessionStore.logoutUserSessionReceivedUserSession as? UserSessionMock) === alice)
        #expect(alice.userSettings.account.seenInvites.isEmpty)
        #expect(manager.userIDs == ["@bob:matrix.org"])
        
        #expect(!bobClientProxy.pauseServicesCalled)
        #expect(!bobNotificationService.tearDownCalled)
        #expect(!bobLiveLocationService.stopAllLiveLocationsCalled)
        #expect(!bobClientProxy.logoutCalled)
        #expect((manager.activeSession as? UserSessionMock) === bob)
    }
    
    @Test("Logging out an account that's already logging out is ignored")
    func duplicateLogout() async {
        let manager = makeManager(userIDs: ["@alice:matrix.org"])
        let aliceClientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org"))
        manager.add(UserSessionMock(.init(clientProxy: aliceClientProxy)))
        
        // Simulate the SDK reporting an auth error while the server logout is in flight.
        aliceClientProxy.logoutClosure = { await manager.logout(userID: "@alice:matrix.org") }
        
        await manager.logout(userID: "@alice:matrix.org")
        
        #expect(aliceClientProxy.logoutCallsCount == 1)
        #expect(userSessionStore.logoutUserSessionCallsCount == 1)
        #expect(manager.userIDs.isEmpty)
    }
    
    @Test("Adding a session connects its services")
    func addConnectsServices() {
        let manager = makeManager(userIDs: [])
        let alice = makeUserSession(userID: "@alice:matrix.org")
        
        manager.add(alice)
        
        #expect(notificationManager.addReceivedService === alice.notificationService)
        #expect(liveLocationManager.addReceivedService === alice.liveLocationService)
        #expect(elementCallManager.addReceivedService === alice.elementCallService)
    }
    
    @Test("Removing an account disconnects its services")
    func removeDisconnectsServices() {
        let manager = makeManager(userIDs: ["@alice:matrix.org"])
        manager.add(makeUserSession(userID: "@alice:matrix.org"))
        
        manager.remove(userID: "@alice:matrix.org")
        
        #expect(notificationManager.removeUserIDReceivedInvocations == ["@alice:matrix.org"])
        #expect(liveLocationManager.removeUserIDReceivedInvocations == ["@alice:matrix.org"])
        #expect(elementCallManager.removeUserIDReceivedInvocations == ["@alice:matrix.org"])
    }
    
    @Test("Resetting disconnects every account's services")
    func resetAllAccounts() {
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        manager.add(makeUserSession(userID: "@alice:matrix.org"))
        
        manager.reset()
        
        #expect(Set(notificationManager.removeUserIDReceivedInvocations) == ["@alice:matrix.org", "@bob:matrix.org"])
        #expect(Set(liveLocationManager.removeUserIDReceivedInvocations) == ["@alice:matrix.org", "@bob:matrix.org"])
        #expect(Set(elementCallManager.removeUserIDReceivedInvocations) == ["@alice:matrix.org", "@bob:matrix.org"])
    }
    
    @Test("A failed restore disconnects the account's services")
    func restoreFailureDisconnectsServices() async {
        let manager = makeManager(userIDs: ["@alice:matrix.org"])
        userSessionStore.restoreUserSessionUserIDReturnValue = .failure(.failedRestoringLogin)
        
        await manager.restoreSessions { _ in } didAdd: { _ in }
        
        #expect(notificationManager.removeUserIDReceivedInvocations == ["@alice:matrix.org"])
        #expect(liveLocationManager.removeUserIDReceivedInvocations == ["@alice:matrix.org"])
        #expect(elementCallManager.removeUserIDReceivedInvocations == ["@alice:matrix.org"])
    }
    
    @Test("Resuming and pausing the services reach every session")
    func resumeAndPauseServices() async {
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
    
    @Test("The auth errors of the live sessions are reported")
    func authErrors() async throws {
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        manager.add(makeUserSession(userID: "@alice:matrix.org"))
        let bob = makeUserSession(userID: "@bob:matrix.org")
        manager.add(bob)
        
        let deferred = deferFulfillment(manager.callbacksPublisher) { $0 == .didReceiveAuthError(userID: "@bob:matrix.org") }
        bob.callbacks.send(.didReceiveAuthError)
        try await deferred.fulfill()
        
        // A replaced session (e.g. after clearing the cache) mustn't report anything anymore.
        let deferredFailure = deferFailure(manager.callbacksPublisher, timeout: .milliseconds(300)) { _ in true }
        manager.add(makeUserSession(userID: "@bob:matrix.org"))
        bob.callbacks.send(.didReceiveAuthError)
        try await deferredFailure.fulfill()
    }
    
    // MARK: - Helpers
    
    private func makeManager(userIDs: [String]) -> UserSessionManager {
        userSessionStore.userIDs = userIDs
        return UserSessionManager(userSessionStore: userSessionStore,
                                  appSettings: appSettings,
                                  notificationManager: notificationManager,
                                  liveLocationManager: liveLocationManager,
                                  elementCallManager: elementCallManager)
    }
    
    private func makeUserSession(userID: String) -> UserSessionMock {
        UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: userID))))
    }
}

private final class RestorationRecorder {
    var preparedUserIDs: [String] = []
    var addedUserIDs: [String] = []
}
