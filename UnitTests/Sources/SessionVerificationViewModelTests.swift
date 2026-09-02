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
        sessionVerificationController = SessionVerificationControllerProxyMock.configureMock()
        viewModel = SessionVerificationScreenViewModel(sessionVerificationControllerProxy: sessionVerificationController,
                                                       secureBackupController: SecureBackupControllerMock(.init()),
                                                       flow: .deviceInitiator,
                                                       appSettings: .volatile(),
                                                       mediaProvider: MediaProviderMock(.init()))
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
    
    @Test
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
    
    @Test
    func missingSecretsMakesVerificationUnavailable() async throws {
        let sessionVerificationController = SessionVerificationControllerProxyMock.configureMock()
        let viewModel = makeResponderViewModel(sessionVerificationController: sessionVerificationController,
                                               recoveryState: .incomplete)
        
        #expect(viewModel.context.viewState.isUnavailable)
        #expect(viewModel.context.viewState.title == UntranslatedL10n.screenSessionVerificationUnavailableTitle)
        #expect(viewModel.context.viewState.message == UntranslatedL10n.screenSessionVerificationUnavailableSubtitle)
        
        try await Task.sleep(for: .milliseconds(100))
        #expect(sessionVerificationController.acceptVerificationRequestCallsCount == 0)
    }
    
    @Test
    func holdingSecretsAllowsVerification() {
        let viewModel = makeResponderViewModel(sessionVerificationController: SessionVerificationControllerProxyMock.configureMock(),
                                               recoveryState: .enabled)
        
        #expect(!viewModel.context.viewState.isUnavailable)
        #expect(viewModel.context.viewState.title == L10n.screenSessionVerificationRequestTitle)
    }
    
    // MARK: - Private
    
    private func makeResponderViewModel(sessionVerificationController: SessionVerificationControllerProxyMock,
                                        recoveryState: SecureBackupRecoveryState) -> SessionVerificationScreenViewModelProtocol {
        let details = SessionVerificationRequestDetails(senderProfile: UserProfile(userID: "@bob:matrix.org"),
                                                        flowID: "flow-id",
                                                        deviceID: "CODEMISTAKE",
                                                        deviceDisplayName: "Bob's Element X iOS",
                                                        firstSeenDate: .init(timeIntervalSince1970: 0))
        
        return SessionVerificationScreenViewModel(sessionVerificationControllerProxy: sessionVerificationController,
                                                  secureBackupController: SecureBackupControllerMock(.init(recoveryState: recoveryState)),
                                                  flow: .deviceResponder(requestDetails: details),
                                                  appSettings: .volatile(),
                                                  mediaProvider: MediaProviderMock(.init()))
    }
    
    private mutating func setupChallengeReceived() async throws {
        let actionsPublisher = sessionVerificationController.actions.delay(for: .seconds(0.1), scheduler: DispatchQueue.main)
        let cancellable = actionsPublisher
            .sink { [sessionVerificationController] action in
                if case .acceptedVerificationRequest = action {
                    Task { await sessionVerificationController?.startSasVerification() }
                }
            }
        
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
        
        cancellable.cancel()
    }
}
