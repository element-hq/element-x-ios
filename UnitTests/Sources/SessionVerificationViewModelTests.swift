//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Foundation
import Testing

@MainActor
struct SessionVerificationViewModelTests {
    var viewModel: SessionVerificationScreenViewModelProtocol!
    var context: SessionVerificationViewModelType.Context!
    var sessionVerificationController: SessionVerificationControllerProxyMock!
    
    init() throws {
        sessionVerificationController = SessionVerificationControllerProxyMock.configureMock(requestDelay: .milliseconds(500))
        viewModel = SessionVerificationScreenViewModel(sessionVerificationControllerProxy: sessionVerificationController,
                                                       flow: .deviceInitiator,
                                                       userSession: UserSessionMock(.init()))
        context = viewModel.context
    }
    
    @Test("Requesting verification asks the other device to verify")
    func requestVerification() async throws {
        #expect(context.viewState.verificationState == .initial)
        
        context.send(viewAction: .requestVerification)
        
        try await Task.sleep(for: .milliseconds(100))
        #expect(sessionVerificationController.requestDeviceVerificationCallsCount == 1)
        #expect(context.viewState.verificationState == .requestingVerification)
    }
    
    @Test("Stopping cancels the verification, and restarting goes back to the start")
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
    
    @Test("The emojis are shown once the other device starts SAS verification")
    mutating func receiveChallenge() async throws {
        try await setupChallengeReceived()
    }
    
    @Test("Accepting the challenge verifies the session")
    mutating func acceptChallenge() async throws {
        try await setupChallengeReceived()
        
        let deferred = deferFulfillment(sessionVerificationController.actions
            .delay(for: .seconds(0.1), scheduler: DispatchQueue.main)) { callback in
                if case .finished = callback {
                    return true
                }
                return false
            }
        
        context.send(viewAction: .accept)
        
        try await deferred.fulfill()
        
        #expect(context.viewState.verificationState == .verified)
        #expect(sessionVerificationController.approveVerificationCallsCount == 1)
    }
    
    @Test("Declining the challenge cancels the verification")
    mutating func declineChallenge() async throws {
        try await setupChallengeReceived()
        
        let deferred = deferFulfillment(sessionVerificationController.actions
            .delay(for: .seconds(0.1), scheduler: DispatchQueue.main)) { callback in
                if case .cancelled = callback {
                    return true
                }
                return false
            }
        
        context.send(viewAction: .decline)
        
        try await deferred.fulfill()
        
        #expect(context.viewState.verificationState == .cancelled)
        #expect(sessionVerificationController.declineVerificationCallsCount == 1)
    }
    
    @Test("While waiting for the other side to match, the screen keeps the challenge's subtitle", arguments: [false, true])
    func acceptingChallengeState(isUserVerification: Bool) {
        let flow: SessionVerificationScreenFlow = isUserVerification ? .userInitiator(userID: "@bob:matrix.org") : .deviceInitiator
        var viewState = SessionVerificationScreenViewState(flow: flow,
                                                           learnMoreURL: "https://example.org/encryption",
                                                           verificationState: .showingChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
        let challengeMessage = viewState.message
        #expect(!viewState.isWaiting)
        
        viewState.verificationState = .acceptingChallenge(emojis: SessionVerificationControllerProxyMock.emojis)
        
        #expect(viewState.isWaiting)
        #expect(viewState.message == challengeMessage)
    }
    
    // MARK: - Private
    
    private mutating func setupChallengeReceived() async throws {
        let actionsPublisher = sessionVerificationController.actions.delay(for: .seconds(0.1), scheduler: DispatchQueue.main)
        
        let deferred = deferFulfillment(actionsPublisher,
                                        keyPath: \.self,
                                        transitionValues: [.acceptedVerificationRequest,
                                                           .startedSasVerification,
                                                           .receivedVerificationData(SessionVerificationControllerProxyMock.emojis)])
        context.send(viewAction: .requestVerification)
        try await deferred.fulfill()
        
        #expect(context.viewState.verificationState == .showingChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
        #expect(sessionVerificationController.requestDeviceVerificationCallsCount == 1)
        #expect(sessionVerificationController.startSasVerificationCallsCount == 1)
    }
}
