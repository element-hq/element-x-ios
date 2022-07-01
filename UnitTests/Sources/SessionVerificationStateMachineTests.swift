//
//  SessionVerificationStateMachineTests.swift
//  UnitTests
//
//  Created by Stefan Ceriu on 28/06/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import XCTest

@testable import ElementX

@MainActor
class SessionVerificationStateMachineTests: XCTestCase {
    private var stateMachine: SessionVerificationStateMachine!
    
    @MainActor
    override func setUpWithError() throws {
        stateMachine = SessionVerificationStateMachine()
    }
    
    func testAcceptChallenge() {
        XCTAssertEqual(stateMachine.state, .initial)
        
        stateMachine.processEvent(.requestVerification)
        XCTAssertEqual(stateMachine.state, .requestingVerification)
        
        stateMachine.processEvent(.didReceiveChallenge(emojis: MockSessionVerificationControllerProxy.emojis))
        XCTAssertEqual(stateMachine.state, .showingChallenge(emojis: MockSessionVerificationControllerProxy.emojis))
        
        stateMachine.processEvent(.acceptChallenge)
        XCTAssertEqual(stateMachine.state, .acceptingChallenge(emojis: MockSessionVerificationControllerProxy.emojis))
        
        stateMachine.processEvent(.didAcceptChallenge)
        XCTAssertEqual(stateMachine.state, .verified)
    }
    
    func testDeclineChallenge() {
        XCTAssertEqual(stateMachine.state, .initial)
        
        stateMachine.processEvent(.requestVerification)
        XCTAssertEqual(stateMachine.state, .requestingVerification)
        
        stateMachine.processEvent(.didReceiveChallenge(emojis: MockSessionVerificationControllerProxy.emojis))
        XCTAssertEqual(stateMachine.state, .showingChallenge(emojis: MockSessionVerificationControllerProxy.emojis))
        
        stateMachine.processEvent(.declineChallenge)
        XCTAssertEqual(stateMachine.state, .decliningChallenge(emojis: MockSessionVerificationControllerProxy.emojis))
        
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
        
        stateMachine.processEvent(.didReceiveChallenge(emojis: MockSessionVerificationControllerProxy.emojis))
        XCTAssertEqual(stateMachine.state, .showingChallenge(emojis: MockSessionVerificationControllerProxy.emojis))
        
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
