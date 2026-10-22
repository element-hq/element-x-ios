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
struct UserSessionTests {
    private let clock = ManualClock()
    private let verificationStateSubject = CurrentValueSubject<SessionVerificationState, Never>(.unknown)
    private let recoveryStateSubject = CurrentValueSubject<SecureBackupRecoveryState, Never>(.unknown)
    private let encryptionSetupContinuation: AsyncStream<Void>.Continuation
    private let identityChecks: AsyncStream<Void>
    private let identityChecksContinuation: AsyncStream<Void>.Continuation
    private let clientProxy: ClientProxyMock
    private let userSession: UserSession
    
    init() {
        let (encryptionSetup, encryptionSetupContinuation) = AsyncStream<Void>.makeStream()
        self.encryptionSetupContinuation = encryptionSetupContinuation
        (identityChecks, identityChecksContinuation) = AsyncStream<Void>.makeStream()
        
        clientProxy = ClientProxyMock(.init())
        clientProxy.verificationStatePublisher = verificationStateSubject.asCurrentValuePublisher()
        // Only returns once a test finishes the encryption setup.
        clientProxy.waitForE2EEInitializationTasksClosure = {
            for await _ in encryptionSetup { }
        }
        
        let secureBackupController = SecureBackupControllerMock()
        secureBackupController.recoveryState = recoveryStateSubject.asCurrentValuePublisher()
        clientProxy.secureBackupController = secureBackupController
        
        userSession = UserSession(clientProxy: clientProxy,
                                  userSettings: .mock(),
                                  userHooks: UserHooks(),
                                  mediaProvider: MediaProviderMock(.init()),
                                  voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                  liveLocationService: LiveLocationServiceMock(.init()),
                                  notificationService: NotificationServiceMock(.init()),
                                  clock: clock)
    }
    
    @Test
    func unverifiedIsHeldBackWhileEncryptionIsSettingUp() async throws {
        verificationStateSubject.send(.unverified)
        
        let deferred = deferFulfillment(userSession.sessionSecurityStatePublisher) { $0.recoveryState == .disabled }
        recoveryStateSubject.send(.disabled)
        let state = try await deferred.fulfill()
        
        #expect(state.verificationState == .unknown)
    }
    
    @Test
    func verifiedIsPassedOnWhileEncryptionIsSettingUp() async throws {
        let deferred = deferFulfillment(userSession.sessionSecurityStatePublisher) { $0.verificationState == .verified }
        verificationStateSubject.send(.verified)
        try await deferred.fulfill()
    }
    
    @Test
    func unverifiedIsReportedOnceVerified() async throws {
        let verified = deferFulfillment(userSession.sessionSecurityStatePublisher) { $0.verificationState == .verified }
        verificationStateSubject.send(.verified)
        try await verified.fulfill()
        
        // e.g. the identity was reset on another device.
        let unverified = deferFulfillment(userSession.sessionSecurityStatePublisher) { $0.verificationState == .unverified }
        verificationStateSubject.send(.unverified)
        try await unverified.fulfill()
    }
    
    @Test
    func unverifiedIsReportedOnceEncryptionIsSetUpForAnExistingIdentity() async throws {
        setOwnIdentity(isTrusted: false)
        verificationStateSubject.send(.unverified)
        
        let deferred = deferFulfillment(userSession.sessionSecurityStatePublisher) { $0.verificationState == .unverified }
        encryptionSetupContinuation.finish()
        try await deferred.fulfill()
    }
    
    @Test
    func unverifiedIsHeldBackForANewIdentityUntilVerified() async throws {
        setOwnIdentity(isTrusted: true)
        verificationStateSubject.send(.unverified)
        
        let identityChecked = deferFulfillment(identityChecks) { _ in true }
        encryptionSetupContinuation.finish()
        try await identityChecked.fulfill()
        
        let unverifiedReported = deferFailure(userSession.sessionSecurityStatePublisher, timeout: .seconds(1)) { $0.verificationState == .unverified }
        try await unverifiedReported.fulfill()
        
        let deferred = deferFulfillment(userSession.sessionSecurityStatePublisher) { $0.verificationState == .verified }
        verificationStateSubject.send(.verified)
        try await deferred.fulfill()
    }
    
    @Test
    func unverifiedIsReportedForANewIdentityAfterTimingOut() async throws {
        setOwnIdentity(isTrusted: true)
        verificationStateSubject.send(.unverified)
        #expect(await clock.waitForScheduledSleep() == .seconds(10))
        
        let identityChecked = deferFulfillment(identityChecks) { _ in true }
        encryptionSetupContinuation.finish()
        try await identityChecked.fulfill()
        
        let deferred = deferFulfillment(userSession.sessionSecurityStatePublisher) { $0.verificationState == .unverified }
        clock.advance(by: .seconds(10))
        try await deferred.fulfill()
    }
    
    @Test
    func unverifiedIsReportedAfterTimingOutWhileEncryptionIsSettingUp() async throws {
        verificationStateSubject.send(.unverified)
        #expect(await clock.waitForScheduledSleep() == .seconds(10))
        
        let deferred = deferFulfillment(userSession.sessionSecurityStatePublisher) { $0.verificationState == .unverified }
        clock.advance(by: .seconds(10))
        try await deferred.fulfill()
    }
    
    // MARK: - Private
    
    private func setOwnIdentity(isTrusted: Bool) {
        let identity = UserIdentityProxyMock(.init(verificationState: isTrusted ? .verified : .notVerified))
        clientProxy.userIdentityForFallBackToServerClosure = { [identityChecksContinuation] _, _ in
            identityChecksContinuation.yield()
            return .success(identity)
        }
    }
}
