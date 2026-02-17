//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
@Suite
struct SessionVerificationStateMachineTests {
    private var stateMachine: SessionVerificationScreenStateMachine
    
    init() {
        stateMachine = SessionVerificationScreenStateMachine(state: .initial)
    }
    
    @Test
    func acceptChallenge() {
        var testSetup = self
        #expect(testSetup.stateMachine.state == .initial)
        
        testSetup.stateMachine.processEvent(.requestVerification)
        #expect(testSetup.stateMachine.state == .requestingVerification)
        
        testSetup.stateMachine.processEvent(.didAcceptVerificationRequest)
        #expect(testSetup.stateMachine.state == .verificationRequestAccepted)
        
        testSetup.stateMachine.processEvent(.didStartSasVerification)
        #expect(testSetup.stateMachine.state == .sasVerificationStarted)
        
        testSetup.stateMachine.processEvent(.didReceiveChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
        #expect(testSetup.stateMachine.state == .showingChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
        
        testSetup.stateMachine.processEvent(.acceptChallenge)
        #expect(testSetup.stateMachine.state == .acceptingChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
        
        testSetup.stateMachine.processEvent(.didAcceptChallenge)
        #expect(testSetup.stateMachine.state == .verified)
    }
    
    @Test
    func declineChallenge() {
        var testSetup = self
        #expect(testSetup.stateMachine.state == .initial)
        
        testSetup.stateMachine.processEvent(.requestVerification)
        #expect(testSetup.stateMachine.state == .requestingVerification)
        
        testSetup.stateMachine.processEvent(.didAcceptVerificationRequest)
        #expect(testSetup.stateMachine.state == .verificationRequestAccepted)
        
        testSetup.stateMachine.processEvent(.didStartSasVerification)
        #expect(testSetup.stateMachine.state == .sasVerificationStarted)
        
        testSetup.stateMachine.processEvent(.didReceiveChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
        #expect(testSetup.stateMachine.state == .showingChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
        
        testSetup.stateMachine.processEvent(.declineChallenge)
        #expect(testSetup.stateMachine.state == .decliningChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
        
        testSetup.stateMachine.processEvent(.didCancel)
        #expect(testSetup.stateMachine.state == .cancelled)
        
        testSetup.stateMachine.processEvent(.restart)
        #expect(testSetup.stateMachine.state == .initial)
    }
    
    @Test
    func cancellation() {
        var testSetup = self
        #expect(testSetup.stateMachine.state == .initial)
        
        testSetup.stateMachine.processEvent(.requestVerification)
        #expect(testSetup.stateMachine.state == .requestingVerification)
        
        testSetup.stateMachine.processEvent(.cancel)
        #expect(testSetup.stateMachine.state == .cancelling)
        
        testSetup.stateMachine.processEvent(.didCancel)
        #expect(testSetup.stateMachine.state == .cancelled)
        
        // This duplication is intentional
        testSetup.stateMachine.processEvent(.didCancel)
        #expect(testSetup.stateMachine.state == .cancelled)
        
        testSetup.stateMachine.processEvent(.restart)
        #expect(testSetup.stateMachine.state == .initial)
        
        testSetup.stateMachine.processEvent(.requestVerification)
        #expect(testSetup.stateMachine.state == .requestingVerification)
        
        testSetup.stateMachine.processEvent(.didAcceptVerificationRequest)
        #expect(testSetup.stateMachine.state == .verificationRequestAccepted)
        
        testSetup.stateMachine.processEvent(.didStartSasVerification)
        #expect(testSetup.stateMachine.state == .sasVerificationStarted)
        
        testSetup.stateMachine.processEvent(.didReceiveChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
        #expect(testSetup.stateMachine.state == .showingChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
        
        testSetup.stateMachine.processEvent(.cancel)
        #expect(testSetup.stateMachine.state == .cancelling)
        
        testSetup.stateMachine.processEvent(.didCancel)
        #expect(testSetup.stateMachine.state == .cancelled)
        
        testSetup.stateMachine.processEvent(.restart)
        #expect(testSetup.stateMachine.state == .initial)
        
        testSetup.stateMachine.processEvent(.restart)
        #expect(testSetup.stateMachine.state == .initial)
    }
}
