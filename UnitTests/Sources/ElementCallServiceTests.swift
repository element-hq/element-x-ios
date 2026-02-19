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
final class ElementCallServiceTests {
    private var callProvider: CXProviderMock!
    private var currentDate: Date!
    private var testClock: TestClock<Duration>!
    private var pushRegistry: PKPushRegistry!
    private var service: ElementCallService!
    
    init() {
        pushRegistry = PKPushRegistry(queue: nil)
        callProvider = CXProviderMock(.init())
        currentDate = Date()
        testClock = TestClock()
        let dateProvider: () -> Date = {
            self.currentDate
        }
        service = ElementCallService(callProvider: callProvider, timeProvider: TimeProvider(clock: testClock, now: dateProvider))
    }
    
    deinit {
        callProvider = nil
        currentDate = nil
        testClock = nil
        pushRegistry = nil
    }
    
    @Test
    func incomingCall() async {
        #expect(!callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
        
        await confirmation { confirmation in
            let pkPushPayloadMock = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 30)
            
            service.pushRegistry(pushRegistry, didReceiveIncomingPushWith: pkPushPayloadMock, for: .voIP) {
                confirmation()
            }
        }
        
        #expect(callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
    }
    
    @Test
    func callIsTimingOut() async {
        #expect(!callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
        
        await confirmation { confirmation in
            let pushPayload = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 20)
            
            service.pushRegistry(pushRegistry,
                                 didReceiveIncomingPushWith: pushPayload,
                                 for: .voIP) {
                confirmation()
            }
        }
        
        await confirmation { confirmation in
            callProvider.reportCallWithEndedAtReasonClosure = { _, _, reason in
                if reason == .unanswered {
                    confirmation()
                } else {
                    Issue.record("Call should have ended as unanswered")
                }
            }
            
            // advance past the timeout
            await testClock.advance(by: .seconds(30))
        }
    }
    
    @Test
    func expiredRingLifetimeIsIgnored() {
        #expect(!callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
        
        let pushPayload = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 20)
        
        currentDate = currentDate.addingTimeInterval(60)
        
        service.pushRegistry(pushRegistry,
                             didReceiveIncomingPushWith: pushPayload,
                             for: .voIP) { }
        sleep(20)
        
        #expect(!callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
    }
    
    @Test
    func lifetimeIsCapped() async {
        await confirmation { confirmation in
            callProvider.reportCallWithEndedAtReasonClosure = { _, _, reason in
                if reason == .unanswered {
                    confirmation()
                } else {
                    Issue.record("Call should have ended as unanswered")
                }
            }
            
            #expect(!callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
            
            let pushPayload = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 300)
            
            service.pushRegistry(pushRegistry,
                                 didReceiveIncomingPushWith: pushPayload,
                                 for: .voIP) { }
            
            // Advance past the max timeout but below the 300
            await testClock.advance(by: .seconds(100))
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
