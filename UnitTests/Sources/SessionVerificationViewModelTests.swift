//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Testing

@MainActor
@Suite
struct SessionVerificationViewModelTests {
    var viewModel: SessionVerificationScreenViewModelProtocol!
    var context: SessionVerificationViewModelType.Context!
    var sessionVerificationController: SessionVerificationControllerProxyMock!
    
    init() throws {
        sessionVerificationController = SessionVerificationControllerProxyMock.configureMock()
        viewModel = SessionVerificationScreenViewModel(sessionVerificationControllerProxy: sessionVerificationController,
                                                       flow: .deviceInitiator,
                                                       appSettings: AppSettings(),
                                                       mediaProvider: MediaProviderMock(configuration: .init()))
        context = viewModel.context
    }

    @Test
    func requestVerification() async throws {
        #expect(context.viewState.verificationState == .initial)
        
        context.send(viewAction: .requestVerification)
        
        try await Task.sleep(for: .milliseconds(100))
        #expect(sessionVerificationController.requestDeviceVerificationCallsCount == 1)
        #expect(context.viewState.verificationState == .requestingVerification)
    }
    
    @Test
    func verificationCancellation() async throws {
        #expect(context.viewState.verificationState == .initial)
        
        context.send(viewAction: .requestVerification)
        
        viewModel.stop()
        
        #expect(context.viewState.verificationState == .cancelling)
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.verificationState == .cancelled
        }
        
        try await deferred.fulfill()
        
        #expect(context.viewState.verificationState == .cancelled)
        
        context.send(viewAction: .restart)
        
        #expect(context.viewState.verificationState == .initial)

        #expect(sessionVerificationController.requestDeviceVerificationCallsCount == 1)
        #expect(sessionVerificationController.cancelVerificationCallsCount == 1)
    }
    
    @Test
    mutating func receiveChallenge() async throws {
        try await setupChallengeReceived()
    }
    
    @Test
    mutating func acceptChallenge() async throws {
        try await setupChallengeReceived()
        
        let deferred = deferFulfillment(sessionVerificationController.actions
            .delay(for: .seconds(0.1), scheduler: DispatchQueue.main)) { callback in
            if case .finished = callback { return true }
            return false
        }
        
        context.send(viewAction: .accept)
        
        try await deferred.fulfill()
        
        #expect(context.viewState.verificationState == .verified)
        #expect(sessionVerificationController.approveVerificationCallsCount == 1)
    }
    
    @Test
    mutating func declineChallenge() async throws {
        try await setupChallengeReceived()
        
        let deferred = deferFulfillment(sessionVerificationController.actions
            .delay(for: .seconds(0.1), scheduler: DispatchQueue.main)) { callback in
            if case .cancelled = callback { return true }
            return false
        }
        
        context.send(viewAction: .decline)
        
        try await deferred.fulfill()
        
        #expect(context.viewState.verificationState == .cancelled)
        #expect(sessionVerificationController.declineVerificationCallsCount == 1)
    }
    
    // MARK: - Private
    
    private mutating func setupChallengeReceived() async throws {
        let deferredAccepted = deferFulfillment(sessionVerificationController.actions
            .delay(for: .seconds(0.1), scheduler: DispatchQueue.main)) { callback in
            if case .acceptedVerificationRequest = callback { return true }
            return false
        }
        context.send(viewAction: .requestVerification)
        try await deferredAccepted.fulfill()
        #expect(context.viewState.verificationState == .verificationRequestAccepted)
        
        let deferredStarted = deferFulfillment(sessionVerificationController.actions
            .delay(for: .seconds(0.1), scheduler: DispatchQueue.main)) { callback in
            if case .startedSasVerification = callback { return true }
            return false
        }
        context.send(viewAction: .startSasVerification)
        try await deferredStarted.fulfill()
        #expect(context.viewState.verificationState == .sasVerificationStarted)
        
        let deferredData = deferFulfillment(sessionVerificationController.actions
            .delay(for: .seconds(0.1), scheduler: DispatchQueue.main)) { callback in
            if case .receivedVerificationData = callback { return true }
            return false
        }
        try await deferredData.fulfill()
        #expect(context.viewState.verificationState == .showingChallenge(emojis: SessionVerificationControllerProxyMock.emojis))

        #expect(sessionVerificationController.requestDeviceVerificationCallsCount == 1)
        #expect(sessionVerificationController.startSasVerificationCallsCount == 1)
    }
}
