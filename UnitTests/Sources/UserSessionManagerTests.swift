//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Testing

@MainActor
struct UserSessionManagerTests {
    let userSessionStore = UserSessionStoreMock()
    let userSessionMigrator = UserSessionMigratorMock(.init())
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
        userSessionMigrator.migrateClosure = { _ in
            // Migrations run before the session can be used.
            #expect(manager.session(for: "@bob:matrix.org") == nil)
        }
        let recorder = RestorationRecorder(manager)
        
        await manager.restoreSessions()
        
        #expect(userSessionStore.restoreUserSessionUserIDReceivedInvocations == ["@alice:matrix.org", "@bob:matrix.org"])
        #expect(userSessionMigrator.migrateCallsCount == 1)
        #expect((userSessionMigrator.migrateReceivedUserSession as? UserSessionMock) === bob)
        #expect(recorder.restoredUserIDs == ["@bob:matrix.org"])
        // The store deletes an account that fails to restore.
        #expect(manager.userIDs == ["@bob:matrix.org"])
        #expect((manager.activeSession as? UserSessionMock) === bob)
    }
    
    @Test("Restoring removes every account that fails")
    func restoreFailures() async {
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        userSessionStore.restoreUserSessionUserIDReturnValue = .failure(.failedRestoringLogin)
        let recorder = RestorationRecorder(manager)
        
        await manager.restoreSessions()
        
        #expect(userSessionStore.restoreUserSessionUserIDReceivedInvocations == ["@alice:matrix.org", "@bob:matrix.org"])
        #expect(manager.userIDs.isEmpty)
        #expect(manager.activeSession == nil)
        #expect(!userSessionMigrator.migrateCalled)
        #expect(recorder.restoredUserIDs.isEmpty)
    }
    
    @Test("Restoring makes only one account live without multi-account")
    func restoreSingleAccount() async {
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        let sessions = ["@alice:matrix.org": makeUserSession(userID: "@alice:matrix.org"), "@bob:matrix.org": makeUserSession(userID: "@bob:matrix.org")]
        userSessionStore.restoreUserSessionUserIDClosure = { userID in sessions[userID].map { .success($0) } ?? .failure(.failedRestoringLogin) }
        
        await manager.restoreSessions()
        
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
        let recorder = RestorationRecorder(manager)
        
        await manager.restoreSessions()
        
        #expect(userSessionStore.restoreUserSessionUserIDReceivedInvocations == ["@alice:matrix.org", "@bob:matrix.org"])
        #expect(recorder.restoredUserIDs == ["@alice:matrix.org", "@bob:matrix.org"])
        #expect(aliceClientProxy.resumeServicesCalled)
        #expect(bobClientProxy.resumeServicesCalled)
        #expect(manager.activeSession?.clientProxy.userID == "@alice:matrix.org")
    }
    
    @Test("Restoring skips accounts that are already live")
    func restoreSkipsLiveAccounts() async {
        appSettings.multiAccountEnabled = true
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        manager.addNewSession(makeUserSession(userID: "@alice:matrix.org"))
        userSessionStore.restoreUserSessionUserIDReturnValue = .success(makeUserSession(userID: "@bob:matrix.org"))
        
        await manager.restoreSessions()
        #expect(userSessionStore.restoreUserSessionUserIDReceivedInvocations == ["@bob:matrix.org"])
        
        // Once every account is live, there's nothing left to restore.
        await manager.restoreSessions()
        #expect(userSessionStore.restoreUserSessionUserIDCallsCount == 1)
    }
    
    @Test("Restoring doesn't resume sessions while the services are paused")
    func restoreWhilePaused() async {
        let manager = makeManager(userIDs: ["@alice:matrix.org"])
        let aliceClientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org"))
        userSessionStore.restoreUserSessionUserIDReturnValue = .success(UserSessionMock(.init(clientProxy: aliceClientProxy)))
        
        // E.g. a background launch, which pauses the sessions when its task completes.
        await manager.restoreSessions()
        
        #expect(manager.activeSession != nil)
        #expect(!aliceClientProxy.resumeServicesCalled)
    }
    
    @Test("Signing in while the services are running resumes the new session")
    func signInWhileRunning() async {
        let manager = makeManager(userIDs: [])
        await manager.resumeServices()
        let aliceClientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org"))
        
        await waitForConfirmation("Wait for the new session to resume", timeout: .seconds(1)) { confirmation in
            aliceClientProxy.resumeServicesClosure = { confirmation() }
            manager.addNewSession(UserSessionMock(.init(clientProxy: aliceClientProxy)))
        }
    }
    
    @Test("Signing in while the services are paused doesn't resume the new session")
    func signInWhilePaused() async {
        let manager = makeManager(userIDs: [])
        let aliceClientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org"))
        
        await waitForConfirmation("The new session shouldn't resume", expectedCount: 0, timeout: .seconds(1)) { confirmation in
            aliceClientProxy.resumeServicesClosure = { confirmation() }
            manager.addNewSession(UserSessionMock(.init(clientProxy: aliceClientProxy)))
        }
    }
    
    @Test("Clearing the caches pauses the account's session and replaces it by restoring the account")
    func clearCachesReplacesSession() async {
        appSettings.multiAccountEnabled = true
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        let aliceClientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org"))
        aliceClientProxy.clearCachesReturnValue = .success(())
        let oldAlice = UserSessionMock(.init(clientProxy: aliceClientProxy))
        let bobClientProxy = ClientProxyMock(.init(userID: "@bob:matrix.org"))
        let bob = UserSessionMock(.init(clientProxy: bobClientProxy))
        manager.addNewSession(oldAlice)
        manager.addNewSession(bob)
        
        let newAlice = makeUserSession(userID: "@alice:matrix.org")
        userSessionStore.restoreUserSessionUserIDReturnValue = .success(newAlice)
        userSessionMigrator.migrateClosure = { _ in
            // The cleared session stays live until the new one replaces it.
            #expect((manager.session(for: "@alice:matrix.org") as? UserSessionMock) === oldAlice)
        }
        
        await manager.clearCaches(userID: "@alice:matrix.org")
        #expect(aliceClientProxy.pauseServicesCalled)
        #expect(!bobClientProxy.pauseServicesCalled)
        #expect(aliceClientProxy.clearCachesCalled)
        #expect(userSessionStore.restoreUserSessionUserIDReceivedInvocations == ["@alice:matrix.org"])
        #expect((manager.activeSession as? UserSessionMock) === newAlice)
        #expect((manager.session(for: "@bob:matrix.org") as? UserSessionMock) === bob)
        
        await manager.restoreSessions()
        #expect(userSessionStore.restoreUserSessionUserIDCallsCount == 1)
    }
    
    @Test("Restoring after clearing the caches falls back to a live account")
    func restoreAfterClearingCaches() async {
        appSettings.multiAccountEnabled = true
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        let aliceClientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org"))
        aliceClientProxy.clearCachesReturnValue = .success(())
        manager.addNewSession(UserSessionMock(.init(clientProxy: aliceClientProxy)))
        let bob = makeUserSession(userID: "@bob:matrix.org")
        manager.addNewSession(bob)
        userSessionStore.restoreUserSessionUserIDReturnValue = .failure(.failedRestoringLogin)
        
        await manager.clearCaches(userID: "@alice:matrix.org")
        
        #expect(userSessionStore.restoreUserSessionUserIDReceivedInvocations == ["@alice:matrix.org"])
        #expect(manager.userIDs == ["@bob:matrix.org"])
        #expect((manager.activeSession as? UserSessionMock) === bob)
    }
    
    @Test("Logging out an account mid-restore doesn't stop the other accounts restoring")
    func logoutDuringRestore() async {
        appSettings.multiAccountEnabled = true
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org", "@carol:matrix.org"])
        manager.addNewSession(makeUserSession(userID: "@alice:matrix.org"))
        let sessions = ["@bob:matrix.org": makeUserSession(userID: "@bob:matrix.org"), "@carol:matrix.org": makeUserSession(userID: "@carol:matrix.org")]
        userSessionStore.restoreUserSessionUserIDClosure = { userID in sessions[userID].map { .success($0) } ?? .failure(.failedRestoringLogin) }
        userSessionMigrator.migrateClosure = { userSession in
            guard userSession as? UserSessionMock === sessions["@bob:matrix.org"] else { return }
            await manager.logout(userID: "@alice:matrix.org")
        }
        let recorder = RestorationRecorder(manager)
        
        await manager.restoreSessions()
        
        #expect(recorder.restoredUserIDs == ["@bob:matrix.org", "@carol:matrix.org"])
        #expect(manager.userIDs == ["@bob:matrix.org", "@carol:matrix.org"])
    }
    
    @Test("An account removed while it's restoring isn't added back")
    func removalDuringRestore() async {
        appSettings.multiAccountEnabled = true
        let manager = makeManager(userIDs: ["@alice:matrix.org"])
        let aliceClientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org"))
        aliceClientProxy.clearCachesReturnValue = .success(())
        manager.addNewSession(UserSessionMock(.init(clientProxy: aliceClientProxy)))
        userSessionStore.restoreUserSessionUserIDReturnValue = .success(makeUserSession(userID: "@alice:matrix.org"))
        // The cleared session is still live, so it can be logged out while its replacement restores.
        userSessionMigrator.migrateClosure = { _ in await manager.logout(userID: "@alice:matrix.org") }
        let recorder = RestorationRecorder(manager)
        
        await manager.clearCaches(userID: "@alice:matrix.org")
        
        #expect(recorder.restoredUserIDs.isEmpty)
        #expect(manager.userIDs.isEmpty)
        #expect(manager.activeSession == nil)
    }
    
    @Test("Adding a new session registers it as the active account, with nothing to migrate")
    func addNewSession() {
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        let carol = makeUserSession(userID: "@carol:matrix.org")
        
        manager.addNewSession(carol)
        
        #expect(manager.userIDs == ["@carol:matrix.org", "@alice:matrix.org", "@bob:matrix.org"])
        #expect(carol.userSettings.account.lastSelectedDate != nil)
        #expect((userSessionMigrator.markAsMigratedReceivedUserSession as? UserSessionMock) === carol)
        #expect((manager.activeSession as? UserSessionMock) === carol)
        #expect(manager.sessionsPublisher.value.map(\.clientProxy.userID) == ["@carol:matrix.org"])
    }
    
    @Test("Removing an account deletes it")
    func removeAccount() {
        let manager = makeManager(userIDs: ["@alice:matrix.org"])
        let alice = makeUserSession(userID: "@alice:matrix.org")
        manager.addNewSession(alice)
        
        manager.remove(userID: "@alice:matrix.org")
        
        #expect(userSessionStore.logoutUserIDReceivedUserID == "@alice:matrix.org")
        #expect(manager.userIDs.isEmpty)
        #expect(manager.activeSession == nil)
    }
    
    @Test("Logging out tears down and removes only the given account")
    func logoutOneAccount() async throws {
        appSettings.multiAccountEnabled = true
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        let aliceClientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org"))
        let aliceNotificationService = NotificationServiceMock(.init())
        let aliceLiveLocationService = LiveLocationServiceMock(.init())
        let alice = UserSessionMock(.init(clientProxy: aliceClientProxy,
                                          liveLocationService: aliceLiveLocationService,
                                          notificationService: aliceNotificationService))
        let bobClientProxy = ClientProxyMock(.init(userID: "@bob:matrix.org"))
        let bobNotificationService = NotificationServiceMock(.init())
        let bobLiveLocationService = LiveLocationServiceMock(.init())
        let bob = UserSessionMock(.init(clientProxy: bobClientProxy,
                                        liveLocationService: bobLiveLocationService,
                                        notificationService: bobNotificationService))
        manager.addNewSession(alice)
        manager.addNewSession(bob)
        
        let deferred = deferFulfillment(manager.callbacksPublisher) { $0 == .didRemoveAccount(userID: "@alice:matrix.org", error: nil) }
        await manager.logout(userID: "@alice:matrix.org")
        try await deferred.fulfill()
        
        #expect(aliceClientProxy.pauseServicesCalled)
        #expect(aliceNotificationService.tearDownCalled)
        #expect(aliceLiveLocationService.stopAllLiveLocationsCalled)
        #expect(aliceClientProxy.logoutCalled)
        #expect(userSessionStore.logoutUserIDReceivedUserID == "@alice:matrix.org")
        #expect(manager.userIDs == ["@bob:matrix.org"])
        
        #expect(!bobClientProxy.pauseServicesCalled)
        #expect(!bobNotificationService.tearDownCalled)
        #expect(!bobLiveLocationService.stopAllLiveLocationsCalled)
        #expect(!bobClientProxy.logoutCalled)
        #expect((manager.activeSession as? UserSessionMock) === bob)
    }
    
    @Test("Logging out an account that's already logging out waits for the existing logout call to complete")
    func duplicateLogout() async {
        let manager = makeManager(userIDs: ["@alice:matrix.org"])
        let aliceClientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org"))
        manager.addNewSession(UserSessionMock(.init(clientProxy: aliceClientProxy)))
        
        // Simulate the SDK reporting an auth error while the server logout is in flight, which logs out from its own task.
        var duplicateLogout: Task<Void, Never>?
        aliceClientProxy.logoutClosure = { duplicateLogout = Task { await manager.logout(userID: "@alice:matrix.org") } }
        
        await manager.logout(userID: "@alice:matrix.org")
        await duplicateLogout?.value
        
        #expect(aliceClientProxy.logoutCallsCount == 1)
        #expect(userSessionStore.logoutUserIDCallsCount == 1)
        #expect(manager.userIDs.isEmpty)
    }
    
    @Test("Logging out every account waits for a logout of the same account that's already in progress")
    func logoutAllDuringLogout() async {
        let manager = makeManager(userIDs: ["@alice:matrix.org"])
        let aliceClientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org"))
        manager.addNewSession(UserSessionMock(.init(clientProxy: aliceClientProxy)))
        let (serverLogoutReleased, serverLogoutReleasedContinuation) = AsyncStream<Void>.makeStream()
        
        // Given a logout that's waiting on the server, as on a stalled network.
        let logout = await waitForConfirmation(timeout: .seconds(1)) { confirmation in
            aliceClientProxy.logoutClosure = {
                confirmation()
                for await _ in serverLogoutReleased {
                    break
                }
            }
            return Task { await manager.logout(userID: "@alice:matrix.org") }
        }
        
        // When every account is logged out meanwhile (e.g. Forgot PIN on the lock screen).
        let logoutAll = await waitForConfirmation(timeout: .seconds(1)) { confirmation in
            Task {
                confirmation()
                await manager.logoutAll() // Holds the main actor until it reaches the logout in progress.
                return manager.userIDs
            }
        }
        serverLogoutReleasedContinuation.yield()
        let userIDsAfterLogoutAll = await logoutAll.value
        await logout.value
        
        // Then it only returns once the account is gone, as App Lock is disabled straight after it returns.
        #expect(userIDsAfterLogoutAll.isEmpty)
    }
    
    @Test("Logging out every account removes the live ones and those that aren't live yet, the active one last")
    func logoutAll() async {
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        let aliceClientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org"))
        manager.addNewSession(UserSessionMock(.init(clientProxy: aliceClientProxy)))
        var removals: [UserSessionManagerCallback] = []
        let cancellable = manager.callbacksPublisher.sink { removals.append($0) }
        
        await manager.logoutAll()
        
        // Only a live session can be logged out of the server, but every account is removed from the device.
        #expect(aliceClientProxy.logoutCalled)
        #expect(userSessionStore.logoutUserIDReceivedInvocations == ["@bob:matrix.org", "@alice:matrix.org"])
        #expect(removals == [.didRemoveAccount(userID: "@bob:matrix.org", error: nil),
                             .didRemoveAccount(userID: "@alice:matrix.org", error: nil)])
        #expect(manager.userIDs.isEmpty)
        cancellable.cancel()
    }
    
    @Test("Adding a session connects its services")
    func addConnectsServices() {
        let manager = makeManager(userIDs: [])
        let alice = makeUserSession(userID: "@alice:matrix.org")
        
        manager.addNewSession(alice)
        
        #expect(notificationManager.addReceivedService === alice.notificationService)
        #expect(liveLocationManager.addReceivedService === alice.liveLocationService)
        #expect(elementCallManager.addReceivedService === alice.elementCallService)
    }
    
    @Test("Removing an account disconnects its services")
    func removeDisconnectsServices() {
        let manager = makeManager(userIDs: ["@alice:matrix.org"])
        manager.addNewSession(makeUserSession(userID: "@alice:matrix.org"))
        
        manager.remove(userID: "@alice:matrix.org")
        
        #expect(notificationManager.removeUserIDReceivedInvocations == ["@alice:matrix.org"])
        #expect(liveLocationManager.removeUserIDReceivedInvocations == ["@alice:matrix.org"])
        #expect(elementCallManager.removeUserIDReceivedInvocations == ["@alice:matrix.org"])
    }
    
    @Test("Resetting disconnects every account's services")
    func resetAllAccounts() {
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        manager.addNewSession(makeUserSession(userID: "@alice:matrix.org"))
        
        manager.reset()
        
        #expect(Set(notificationManager.removeUserIDReceivedInvocations) == ["@alice:matrix.org", "@bob:matrix.org"])
        #expect(Set(liveLocationManager.removeUserIDReceivedInvocations) == ["@alice:matrix.org", "@bob:matrix.org"])
        #expect(Set(elementCallManager.removeUserIDReceivedInvocations) == ["@alice:matrix.org", "@bob:matrix.org"])
    }
    
    @Test("A failed restore disconnects the account's services and reports its removal")
    func restorationFailure() async throws {
        let manager = makeManager(userIDs: ["@alice:matrix.org"])
        userSessionStore.restoreUserSessionUserIDReturnValue = .failure(.failedRestoringLogin)
        
        let deferred = deferFulfillment(manager.callbacksPublisher) { $0 == .didRemoveAccount(userID: "@alice:matrix.org", error: .failedRestoringSession) }
        await manager.restoreSessions()
        try await deferred.fulfill()
        
        #expect(notificationManager.removeUserIDReceivedInvocations == ["@alice:matrix.org"])
        #expect(liveLocationManager.removeUserIDReceivedInvocations == ["@alice:matrix.org"])
        #expect(elementCallManager.removeUserIDReceivedInvocations == ["@alice:matrix.org"])
    }
    
    @Test("Resuming and pausing the services reach every session")
    func resumeAndPauseServices() async {
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        let aliceClientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org"))
        let bobClientProxy = ClientProxyMock(.init(userID: "@bob:matrix.org"))
        manager.addNewSession(UserSessionMock(.init(clientProxy: aliceClientProxy)))
        manager.addNewSession(UserSessionMock(.init(clientProxy: bobClientProxy)))
        
        await manager.resumeServices()
        #expect(aliceClientProxy.resumeServicesCallsCount == 1)
        #expect(bobClientProxy.resumeServicesCallsCount == 1)
        
        await manager.pauseServices()
        #expect(aliceClientProxy.pauseServicesCallsCount == 1)
        #expect(bobClientProxy.pauseServicesCallsCount == 1)
    }
    
    @Test("An auth error logs out only the account it belongs to, even when it isn't the active one")
    func authError() async throws {
        appSettings.multiAccountEnabled = true
        let manager = makeManager(userIDs: ["@alice:matrix.org", "@bob:matrix.org"])
        let aliceClientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org"))
        let bobClientProxy = ClientProxyMock(.init(userID: "@bob:matrix.org"))
        let bob = UserSessionMock(.init(clientProxy: bobClientProxy))
        manager.addNewSession(UserSessionMock(.init(clientProxy: aliceClientProxy)))
        manager.addNewSession(bob)
        
        let deferred = deferFulfillment(manager.callbacksPublisher) { $0 == .didRemoveAccount(userID: "@bob:matrix.org", error: .remoteLogout) }
        bob.callbacks.send(.didReceiveAuthError)
        try await deferred.fulfill()
        
        #expect(bobClientProxy.logoutCalled)
        #expect(!aliceClientProxy.logoutCalled)
        #expect(manager.userIDs == ["@alice:matrix.org"])
    }
    
    @Test("An auth error from a replaced session is ignored")
    func replacedSessionAuthError() async throws {
        let manager = makeManager(userIDs: ["@alice:matrix.org"])
        let oldAliceClientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org"))
        oldAliceClientProxy.clearCachesReturnValue = .success(())
        let oldAlice = UserSessionMock(.init(clientProxy: oldAliceClientProxy))
        manager.addNewSession(oldAlice)
        userSessionStore.restoreUserSessionUserIDReturnValue = .success(makeUserSession(userID: "@alice:matrix.org"))
        await manager.clearCaches(userID: "@alice:matrix.org")
        
        let deferredFailure = deferFailure(manager.callbacksPublisher, timeout: .milliseconds(300)) { _ in true }
        oldAlice.callbacks.send(.didReceiveAuthError)
        try await deferredFailure.fulfill()
        
        #expect(manager.userIDs == ["@alice:matrix.org"])
    }
    
    // MARK: - Helpers
    
    private func makeManager(userIDs: [String]) -> UserSessionManager {
        userSessionStore.userIDs = userIDs
        return UserSessionManager(userSessionStore: userSessionStore,
                                  appSettings: appSettings,
                                  notificationManager: notificationManager,
                                  liveLocationManager: liveLocationManager,
                                  elementCallManager: elementCallManager,
                                  userSessionMigrator: userSessionMigrator,
                                  signposter: Signposter())
    }
    
    private func makeUserSession(userID: String) -> UserSessionMock {
        UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: userID))))
    }
}

/// Records the accounts reported as restored, in order.
private final class RestorationRecorder {
    private(set) var restoredUserIDs: [String] = []
    private var cancellable: AnyCancellable?
    
    init(_ manager: UserSessionManagerProtocol) {
        cancellable = manager.callbacksPublisher.sink { [weak self] callback in
            guard case .didRestoreSession(let userID) = callback else { return }
            self?.restoredUserIDs.append(userID)
        }
    }
}
