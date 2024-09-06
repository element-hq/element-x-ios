//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class SessionVerificationStateMachineTests: XCTestCase {
    private var stateMachine: SessionVerificationScreenStateMachine!
    
    @MainActor
    override func setUpWithError() throws {
        stateMachine = SessionVerificationScreenStateMachine()
    }
    
    func testAcceptChallenge() {
        XCTAssertEqual(stateMachine.state, .initial)
        
        stateMachine.processEvent(.requestVerification)
        XCTAssertEqual(stateMachine.state, .requestingVerification)
        
        stateMachine.processEvent(.didAcceptVerificationRequest)
        XCTAssertEqual(stateMachine.state, .verificationRequestAccepted)
        
        stateMachine.processEvent(.didStartSasVerification)
        XCTAssertEqual(stateMachine.state, .sasVerificationStarted)
        
        stateMachine.processEvent(.didReceiveChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
        XCTAssertEqual(stateMachine.state, .showingChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
        
        stateMachine.processEvent(.acceptChallenge)
        XCTAssertEqual(stateMachine.state, .acceptingChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
        
        stateMachine.processEvent(.didAcceptChallenge)
        XCTAssertEqual(stateMachine.state, .verified)
    }
    
    func testDeclineChallenge() {
        XCTAssertEqual(stateMachine.state, .initial)
        
        stateMachine.processEvent(.requestVerification)
        XCTAssertEqual(stateMachine.state, .requestingVerification)
        
        stateMachine.processEvent(.didAcceptVerificationRequest)
        XCTAssertEqual(stateMachine.state, .verificationRequestAccepted)
        
        stateMachine.processEvent(.didStartSasVerification)
        XCTAssertEqual(stateMachine.state, .sasVerificationStarted)
        
        stateMachine.processEvent(.didReceiveChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
        XCTAssertEqual(stateMachine.state, .showingChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
        
        stateMachine.processEvent(.declineChallenge)
        XCTAssertEqual(stateMachine.state, .decliningChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
        
        stateMachine.processEvent(.didCancel)
        XCTAssertEqual(stateMachine.state, .cancelled)
        
        stateMachine.processEvent(.restart)
        XCTAssertEqual(stateMachine.state, .initial)
    }
    
    func testCancellation() {
        XCTAssertEqual(stateMachine.state, .initial)
        
        stateMachine.processEvent(.requestVerification)
        XCTAssertEqual(stateMachine.state, .requestingVerification)
        
        stateMachine.processEvent(.cancel)
        XCTAssertEqual(stateMachine.state, .cancelling)
        
        stateMachine.processEvent(.didCancel)
        XCTAssertEqual(stateMachine.state, .cancelled)
        
        // This duplication is intentional
        stateMachine.processEvent(.didCancel)
        XCTAssertEqual(stateMachine.state, .cancelled)
        
        stateMachine.processEvent(.restart)
        XCTAssertEqual(stateMachine.state, .initial)
        
        stateMachine.processEvent(.requestVerification)
        XCTAssertEqual(stateMachine.state, .requestingVerification)
        
        stateMachine.processEvent(.didAcceptVerificationRequest)
        XCTAssertEqual(stateMachine.state, .verificationRequestAccepted)
        
        stateMachine.processEvent(.didStartSasVerification)
        XCTAssertEqual(stateMachine.state, .sasVerificationStarted)
        
        stateMachine.processEvent(.didReceiveChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
        XCTAssertEqual(stateMachine.state, .showingChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
        
        stateMachine.processEvent(.cancel)
        XCTAssertEqual(stateMachine.state, .cancelling)
        
        stateMachine.processEvent(.didCancel)
        XCTAssertEqual(stateMachine.state, .cancelled)
        
        stateMachine.processEvent(.restart)
        XCTAssertEqual(stateMachine.state, .initial)
        
        stateMachine.processEvent(.restart)
        XCTAssertEqual(stateMachine.state, .initial)
    }
}
