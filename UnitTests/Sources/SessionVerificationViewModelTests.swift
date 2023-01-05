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

import Combine
import XCTest

@testable import ElementX

@MainActor
class SessionVerificationViewModelTests: XCTestCase {
    var viewModel: SessionVerificationViewModelProtocol!
    var context: SessionVerificationViewModelType.Context!
    var sessionVerificationController: SessionVerificationControllerProxyProtocol!
    
    @MainActor
    override func setUpWithError() throws {
        sessionVerificationController = MockSessionVerificationControllerProxy()
        viewModel = SessionVerificationViewModel(sessionVerificationControllerProxy: sessionVerificationController)
        context = viewModel.context
    }

    func testRequestVerification() async {
        XCTAssertEqual(context.viewState.verificationState, .initial)
        
        context.send(viewAction: .requestVerification)
        
        await Task.yield()
        
        XCTAssertEqual(context.viewState.verificationState, .requestingVerification)
    }
    
    func testVerificationCancellation() async throws {
        XCTAssertEqual(context.viewState.verificationState, .initial)
        
        context.send(viewAction: .requestVerification)
        
        context.send(viewAction: .close)
        
        await Task.yield()
        
        XCTAssertEqual(context.viewState.verificationState, .cancelling)
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertEqual(context.viewState.verificationState, .cancelled)
        
        context.send(viewAction: .restart)
        
        await Task.yield()
        
        XCTAssertEqual(context.viewState.verificationState, .initial)
    }
    
    func testReceiveChallenge() {
        setupChallengeReceived()
    }
    
    func testAcceptChallenge() {
        setupChallengeReceived()
        
        let waitForAcceptance = XCTestExpectation(description: "Wait for acceptance")
        
        let cancellable = sessionVerificationController.callbacks
            .debounce(for: .seconds(2.0), scheduler: DispatchQueue.main)
            .sink { callback in
                switch callback {
                case .finished:
                    waitForAcceptance.fulfill()
                default:
                    XCTFail("Unexpected session verification controller callback")
                }
            }
        
        defer {
            cancellable.cancel()
        }
                
        context.send(viewAction: .accept)
        
        wait(for: [waitForAcceptance], timeout: 10.0)
        
        XCTAssertEqual(context.viewState.verificationState, .verified)
    }
    
    func testDeclineChallenge() {
        setupChallengeReceived()
        
        let expectation = XCTestExpectation(description: "Wait for cancellation")
        
        let cancellable = sessionVerificationController.callbacks
            .debounce(for: .seconds(2.0), scheduler: DispatchQueue.main)
            .sink { callback in
                switch callback {
                case .cancelled:
                    expectation.fulfill()
                default:
                    XCTFail("Unexpected session verification controller callback")
                }
            }
        
        defer {
            cancellable.cancel()
        }
                
        context.send(viewAction: .decline)
        
        wait(for: [expectation], timeout: 10.0)
        
        XCTAssertEqual(context.viewState.verificationState, .cancelled)
    }
    
    // MARK: - Private
    
    private func setupChallengeReceived() {
        let requestAcceptanceExpectation = XCTestExpectation(description: "Wait for request acceptance")
        let sasVerificationStartExpectation = XCTestExpectation(description: "Wait for SaS verification start")
        let verificationDataReceivalExpectation = XCTestExpectation(description: "Wait for Emoji data")
        
        let cancellable = sessionVerificationController.callbacks
            .debounce(for: .seconds(2.0), scheduler: DispatchQueue.main)
            .sink { callback in
                switch callback {
                case .acceptedVerificationRequest:
                    requestAcceptanceExpectation.fulfill()
                case .startedSasVerification:
                    sasVerificationStartExpectation.fulfill()
                case .receivedVerificationData:
                    verificationDataReceivalExpectation.fulfill()
                default:
                    break
                }
            }
        
        defer {
            cancellable.cancel()
        }
        
        context.send(viewAction: .requestVerification)
        wait(for: [requestAcceptanceExpectation], timeout: 10.0)
        XCTAssertEqual(context.viewState.verificationState, .verificationRequestAccepted)
        
        context.send(viewAction: .startSasVerification)
        wait(for: [sasVerificationStartExpectation], timeout: 10.0)
        XCTAssertEqual(context.viewState.verificationState, .sasVerificationStarted)
        
        wait(for: [verificationDataReceivalExpectation], timeout: 10.0)
        XCTAssertEqual(context.viewState.verificationState, .showingChallenge(emojis: MockSessionVerificationControllerProxy.emojis))
    }
}
