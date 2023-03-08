//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
