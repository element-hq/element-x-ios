//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Clocks
@testable import ElementX
import PushKit
import XCTest

@MainActor
class ElementCallServiceTests: XCTestCase {
    var callProvider: CXProviderMock!
    var currentDate: Date!
    var testClock: TestClock<Duration>!
    var pushRegistry: PKPushRegistry!
    
    var service: ElementCallService!
    
    override func tearDown() {
        callProvider = nil
        currentDate = nil
        testClock = nil
        pushRegistry = nil
    }
    
    func testIncomingCall() async {
        setupService()
        
        XCTAssertFalse(callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
        
        let expectation = XCTestExpectation(description: "Call accepted")
        
        let pkPushPayloadMock = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 30)
        
        service.pushRegistry(pushRegistry, didReceiveIncomingPushWith: pkPushPayloadMock, for: .voIP) {
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertTrue(callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
    }
    
    func disabled_testCallIsTimingOut() async {
        setupService()
        
        XCTAssertFalse(callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
        let expectation = XCTestExpectation(description: "Call accepted")
        
        let pushPayload = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 20)
        
        service.pushRegistry(pushRegistry,
                             didReceiveIncomingPushWith: pushPayload,
                             for: .voIP) {
            expectation.fulfill()
        }
        
        let expectation2 = XCTestExpectation(description: "Call ended unanswered")
        callProvider.reportCallWithEndedAtReasonClosure = { _, _, reason in
            if reason == .unanswered {
                expectation2.fulfill()
            } else {
                XCTFail("Call should have ended as unanswered")
            }
        }
        
        await fulfillment(of: [expectation], timeout: 1)
        
        // advance past the timeout
        await testClock.advance(by: .seconds(30))
        await fulfillment(of: [expectation2], timeout: 1)
    }
    
    func testExpiredRingLifetimeIsIgnored() {
        setupService()
   
        XCTAssertFalse(callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
        
        let pushPayload = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 20)
        
        currentDate = currentDate.addingTimeInterval(60)
        
        service.pushRegistry(pushRegistry,
                             didReceiveIncomingPushWith: pushPayload,
                             for: .voIP) { }
        sleep(20)
        
        XCTAssertTrue(!callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
    }
    
    func disabled_testLifetimeIsCapped() async throws {
        setupService()
        
        let expectation = expectation(description: "Call has ended unanswered")
        callProvider.reportCallWithEndedAtReasonClosure = { _, _, reason in
            if reason == .unanswered {
                expectation.fulfill()
            } else {
                XCTFail("Call should have ended as unanswered")
            }
        }
        
        XCTAssertFalse(callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
        
        let pushPayload = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 300)
        
        service.pushRegistry(pushRegistry,
                             didReceiveIncomingPushWith: pushPayload,
                             for: .voIP) { }
        
        // Advance past the max timeout but below the 300
        await testClock.advance(by: .seconds(100))
        await fulfillment(of: [expectation], timeout: 1)
    }
    
    // MARK: - Helpers
    
    private func setupService() {
        pushRegistry = PKPushRegistry(queue: nil)
        callProvider = CXProviderMock(.init())
        currentDate = Date()
        testClock = TestClock()
        let dateProvider: () -> Date = {
            self.currentDate
        }
        service = ElementCallService(callProvider: callProvider, timeProvider: TimeProvider(clock: testClock, now: dateProvider))
    }
}

private class PKPushPayloadMock: PKPushPayload {
    var dict: [AnyHashable: Any] = [:]
    
    override init() {
        dict[ElementCallServiceNotificationKey.roomID.rawValue] = "!room:example.com"
        dict[ElementCallServiceNotificationKey.roomDisplayName.rawValue] = "welcome"
        dict[ElementCallServiceNotificationKey.rtcNotifyEventID.rawValue] = "$000"
        dict[ElementCallServiceNotificationKey.expirationDate.rawValue] = Date(timeIntervalSince1970: 10)
    }
    
    override var dictionaryPayload: [AnyHashable: Any] {
        dict
    }
    
    func updatingExpiration(_ from: Date, lifetime: TimeInterval) -> Self {
        dict[ElementCallServiceNotificationKey.expirationDate.rawValue] = from.addingTimeInterval(lifetime)
        return self
    }
}
