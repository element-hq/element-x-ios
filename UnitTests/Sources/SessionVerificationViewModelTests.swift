//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import XCTest

@testable import ElementX

@MainActor
class SessionVerificationViewModelTests: XCTestCase {
    var viewModel: SessionVerificationScreenViewModelProtocol!
    var context: SessionVerificationViewModelType.Context!
    var sessionVerificationController: SessionVerificationControllerProxyMock!
    
    override func setUpWithError() throws {
        sessionVerificationController = SessionVerificationControllerProxyMock.configureMock()
        viewModel = SessionVerificationScreenViewModel(sessionVerificationControllerProxy: sessionVerificationController)
        context = viewModel.context
    }

    func testRequestVerification() async throws {
        XCTAssertEqual(context.viewState.verificationState, .initial)
        
        context.send(viewAction: .requestVerification)
        
        try await Task.sleep(for: .milliseconds(100))
        XCTAssert(sessionVerificationController.requestVerificationCallsCount == 1)
        XCTAssertEqual(context.viewState.verificationState, .requestingVerification)
    }
    
    func testVerificationCancellation() async throws {
        XCTAssertEqual(context.viewState.verificationState, .initial)
        
        context.send(viewAction: .requestVerification)
        
        viewModel.stop()
        
        XCTAssertEqual(context.viewState.verificationState, .cancelling)
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.verificationState == .cancelled
        }
        
        try await deferred.fulfill()
        
        XCTAssertEqual(context.viewState.verificationState, .cancelled)
        
        context.send(viewAction: .restart)
        
        XCTAssertEqual(context.viewState.verificationState, .initial)

        XCTAssert(sessionVerificationController.requestVerificationCallsCount == 1)
        XCTAssert(sessionVerificationController.cancelVerificationCallsCount == 1)
    }
    
    func testReceiveChallenge() {
        setupChallengeReceived()
    }
    
    func testAcceptChallenge() {
        setupChallengeReceived()
        
        let waitForAcceptance = XCTestExpectation(description: "Wait for acceptance")
        
        let cancellable = sessionVerificationController.callbacks
            .delay(for: .seconds(0.1), scheduler: DispatchQueue.main) // Allow the view model to process the callback first.
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
        XCTAssert(sessionVerificationController.approveVerificationCallsCount == 1)
    }
    
    func testDeclineChallenge() {
        setupChallengeReceived()
        
        let expectation = XCTestExpectation(description: "Wait for cancellation")
        
        let cancellable = sessionVerificationController.callbacks
            .delay(for: .seconds(0.1), scheduler: DispatchQueue.main) // Allow the view model to process the callback first.
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
        XCTAssert(sessionVerificationController.declineVerificationCallsCount == 1)
    }
    
    // MARK: - Private
    
    private func setupChallengeReceived() {
        let requestAcceptanceExpectation = XCTestExpectation(description: "Wait for request acceptance")
        let sasVerificationStartExpectation = XCTestExpectation(description: "Wait for SaS verification start")
        let verificationDataReceivalExpectation = XCTestExpectation(description: "Wait for Emoji data")
        
        let cancellable = sessionVerificationController.callbacks
            .delay(for: .seconds(0.1), scheduler: DispatchQueue.main) // Allow the view model to process the callback first.
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
        XCTAssertEqual(context.viewState.verificationState, .showingChallenge(emojis: SessionVerificationControllerProxyMock.emojis))

        XCTAssert(sessionVerificationController.requestVerificationCallsCount == 1)
        XCTAssert(sessionVerificationController.startSasVerificationCallsCount == 1)
    }
}
