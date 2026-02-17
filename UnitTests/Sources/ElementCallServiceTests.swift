//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Clocks
@testable import ElementX
import PushKit
import Testing

@MainActor
@Suite
struct ElementCallServiceTests {
    private var callProvider: CXProviderMock
    private var currentDate: Date
    private var testClock: TestClock<Duration>
    private var pushRegistry: PKPushRegistry
    private var service: ElementCallService
    
    init() {
        pushRegistry = PKPushRegistry(queue: nil)
        callProvider = CXProviderMock(.init())
        currentDate = Date()
        testClock = TestClock()
        var date = currentDate
        let dateProvider: () -> Date = {
            date
        }
        service = ElementCallService(callProvider: callProvider, timeProvider: TimeProvider(clock: testClock, now: dateProvider))
    }
    
    @Test
    func incomingCall() async {
        var testSetup = self
        #expect(!testSetup.callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
        
        await confirmation { confirmation in
            let pkPushPayloadMock = PKPushPayloadMock().updatingExpiration(testSetup.currentDate, lifetime: 30)
            
            testSetup.service.pushRegistry(testSetup.pushRegistry, didReceiveIncomingPushWith: pkPushPayloadMock, for: .voIP) {
                confirmation()
            }
        }
        
        #expect(testSetup.callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
    }
    
    @Test(.disabled("Flaky test"))
    func callIsTimingOut() async {
        var testSetup = self
        #expect(!testSetup.callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
        
        await confirmation { confirmation in
            let pushPayload = PKPushPayloadMock().updatingExpiration(testSetup.currentDate, lifetime: 20)
            
            testSetup.service.pushRegistry(testSetup.pushRegistry,
                                           didReceiveIncomingPushWith: pushPayload,
                                           for: .voIP) {
                confirmation()
            }
        }
        
        await confirmation { confirmation in
            testSetup.callProvider.reportCallWithEndedAtReasonClosure = { _, _, reason in
                if reason == .unanswered {
                    confirmation()
                } else {
                    Issue.record("Call should have ended as unanswered")
                }
            }
            
            // advance past the timeout
            await testSetup.testClock.advance(by: .seconds(30))
        }
    }
    
    @Test(.disabled("Flaky test"))
    mutating func expiredRingLifetimeIsIgnored() {
        #expect(!callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
        
        let pushPayload = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 20)
        
        currentDate = currentDate.addingTimeInterval(60)
        
        service.pushRegistry(pushRegistry,
                             didReceiveIncomingPushWith: pushPayload,
                             for: .voIP) { }
        sleep(20)
        
        #expect(!callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
    }
    
    @Test(.disabled("Flaky test"))
    func lifetimeIsCapped() async {
        var testSetup = self
        
        await confirmation { confirmation in
            testSetup.callProvider.reportCallWithEndedAtReasonClosure = { _, _, reason in
                if reason == .unanswered {
                    confirmation()
                } else {
                    Issue.record("Call should have ended as unanswered")
                }
            }
            
            #expect(!testSetup.callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
            
            let pushPayload = PKPushPayloadMock().updatingExpiration(testSetup.currentDate, lifetime: 300)
            
            testSetup.service.pushRegistry(testSetup.pushRegistry,
                                           didReceiveIncomingPushWith: pushPayload,
                                           for: .voIP) { }
            
            // Advance past the max timeout but below the 300
            await testSetup.testClock.advance(by: .seconds(100))
        }
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
