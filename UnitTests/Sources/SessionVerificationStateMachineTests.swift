//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@Suite
@MainActor
struct SessionVerificationStateMachineTests {
    private var stateMachine: SessionVerificationScreenStateMachine
    
    init() {
        stateMachine = SessionVerificationScreenStateMachine(state: .initial)
    }
    
    @Test
    func acceptChallenge() {
        #expect(stateMachine.state == .initial)
        
        stateMachine.processEvent(.requestVerification)
        #expect(stateMachine.state == .requestingVerification)
        
        stateMachine.processEvent(.didAcceptVerificationRequest)
        #expect(stateMachine.state == .verificationRequestAccepted)
        
        stateMachine.processEvent(.didStartSasVerification)
        #expect(stateMachine.state == .sasVerificationStarted)
        
        stateMachine.processEvent(.didReceiveChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
        #expect(stateMachine.state == .showingChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
        
        stateMachine.processEvent(.acceptChallenge)
        #expect(stateMachine.state == .acceptingChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
        
        stateMachine.processEvent(.didAcceptChallenge)
        #expect(stateMachine.state == .verified)
    }
    
    @Test
    func declineChallenge() {
        #expect(stateMachine.state == .initial)
        
        stateMachine.processEvent(.requestVerification)
        #expect(stateMachine.state == .requestingVerification)
        
        stateMachine.processEvent(.didAcceptVerificationRequest)
        #expect(stateMachine.state == .verificationRequestAccepted)
        
        stateMachine.processEvent(.didStartSasVerification)
        #expect(stateMachine.state == .sasVerificationStarted)
        
        stateMachine.processEvent(.didReceiveChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
        #expect(stateMachine.state == .showingChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
        
        stateMachine.processEvent(.declineChallenge)
        #expect(stateMachine.state == .decliningChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
        
        stateMachine.processEvent(.didCancel)
        #expect(stateMachine.state == .cancelled)
        
        stateMachine.processEvent(.restart)
        #expect(stateMachine.state == .initial)
    }
    
    @Test
    func cancellation() {
        #expect(stateMachine.state == .initial)
        
        stateMachine.processEvent(.requestVerification)
        #expect(stateMachine.state == .requestingVerification)
        
        stateMachine.processEvent(.cancel)
        #expect(stateMachine.state == .cancelling)
        
        stateMachine.processEvent(.didCancel)
        #expect(stateMachine.state == .cancelled)
        
        // This duplication is intentional
        stateMachine.processEvent(.didCancel)
        #expect(stateMachine.state == .cancelled)
        
        stateMachine.processEvent(.restart)
        #expect(stateMachine.state == .initial)
        
        stateMachine.processEvent(.requestVerification)
        #expect(stateMachine.state == .requestingVerification)
        
        stateMachine.processEvent(.didAcceptVerificationRequest)
        #expect(stateMachine.state == .verificationRequestAccepted)
        
        stateMachine.processEvent(.didStartSasVerification)
        #expect(stateMachine.state == .sasVerificationStarted)
        
        stateMachine.processEvent(.didReceiveChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
        #expect(stateMachine.state == .showingChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
        
        stateMachine.processEvent(.cancel)
        #expect(stateMachine.state == .cancelling)
        
        stateMachine.processEvent(.didCancel)
        #expect(stateMachine.state == .cancelled)
        
        stateMachine.processEvent(.restart)
        #expect(stateMachine.state == .initial)
        
        stateMachine.processEvent(.restart)
        #expect(stateMachine.state == .initial)
    }
}
