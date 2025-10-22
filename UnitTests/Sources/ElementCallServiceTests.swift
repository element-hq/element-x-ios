//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Clocks
import PushKit
import XCTest

@testable import ElementX

@MainActor
class ElementCallServiceTests: XCTestCase {
    var callProvider: CXProviderMock!
    var currentDate: Date!
    var testClock: TestClock<Duration>!
    let pushRegistry = PKPushRegistry(queue: nil)
    
    var service: ElementCallService!
    
    func testIncomingCall() async {
        setupService()
        
        XCTAssertFalse(callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
        
        let expectation = XCTestExpectation(description: "Call accepted")
        
        let pkPushPayloadMock = PKPushPayloadMock().addSeconds(currentDate, lifetime: 30)
        
        service.pushRegistry(pushRegistry, didReceiveIncomingPushWith: pkPushPayloadMock, for: .voIP) {
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertTrue(callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
    }
    
    func testCallIsTimingOut() async {
        setupService()
        
        XCTAssertFalse(callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
        
        let expectation = XCTestExpectation(description: "Call accepted")
        
        let pushPayload = PKPushPayloadMock().addSeconds(currentDate, lifetime: 20)
        
        service.pushRegistry(pushRegistry,
                             didReceiveIncomingPushWith: pushPayload,
                             for: .voIP) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1)
        
        // advance past the timeout
        await testClock.advance(by: .seconds(30))
        
        // Call should have ended with unanswered
        XCTAssertTrue(callProvider.reportCallWithEndedAtReasonCalled)
        XCTAssertEqual(callProvider.reportCallWithEndedAtReasonReceivedArguments?.reason, .unanswered)
    }
    
    func testExpiredRingLifetimeIsIgnored() async {
        setupService()
   
        XCTAssertFalse(callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
        
        let pushPayload = PKPushPayloadMock().addSeconds(currentDate, lifetime: 20)
        
        currentDate = currentDate.addingTimeInterval(60)
        
        service.pushRegistry(pushRegistry,
                             didReceiveIncomingPushWith: pushPayload,
                             for: .voIP) { }
        sleep(20)
        
        XCTAssertTrue(!callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
    }
    
    func testLifetimeIsCapped() async {
        setupService()
   
        XCTAssertFalse(callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
        
        let pushPayload = PKPushPayloadMock().addSeconds(currentDate, lifetime: 300)
        
        service.pushRegistry(pushRegistry,
                             didReceiveIncomingPushWith: pushPayload,
                             for: .voIP) { }
        
        // advance pass the max timeout but below the 300
        await testClock.advance(by: .seconds(100))
        
        // Call should have ended with unanswered
        XCTAssertTrue(callProvider.reportCallWithEndedAtReasonCalled)
        XCTAssertEqual(callProvider.reportCallWithEndedAtReasonReceivedArguments?.reason, .unanswered)
    }
    
    // MARK: - Helpers
    
    private func setupService() {
        callProvider = CXProviderMock(.init())
        currentDate = Date()
        testClock = TestClock()
        let dateProvider: () -> Date = {
            self.currentDate
        }
        service = ElementCallService(callProvider: callProvider, timeClock: Time(clock: testClock, now: dateProvider))
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
    
    func addSeconds(_ from: Date, lifetime: Int) -> Self {
        dict[ElementCallServiceNotificationKey.expirationDate.rawValue] = from.addingTimeInterval(TimeInterval(lifetime))
        return self
    }
}
