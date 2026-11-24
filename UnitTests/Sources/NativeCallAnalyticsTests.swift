//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import ElementCall
@testable import ElementX
import Synchronization
import Testing

@MainActor
final class NativeCallAnalyticsTests {
    private let event = ElementCallAnalyticsEvent.callJoinAttempted(attemptID: "attempt", callKind: .dm)
    /// Every client the analytics made, in order.
    private let made = MadeClients()
    private let analytics: NativeCallAnalytics
    
    init() {
        analytics = NativeCallAnalytics { [made] in
            let client = FakeClient()
            made.clients.append(client)
            return client
        }
    }
    
    @Test
    func withoutConsentNothingIsSent() {
        analytics.track(event)
        
        #expect(made.clients.isEmpty)
    }
    
    @Test
    func withConsentEventsAreSent() {
        analytics.setConsent(true)
        analytics.track(event)
        
        #expect(made.clients.map(\.events) == [[event]])
    }
    
    @Test
    func withdrawingConsentStopsTheClientAndDropsLaterEvents() {
        analytics.setConsent(true)
        analytics.setConsent(false)
        analytics.track(event)
        
        #expect(made.clients.map(\.isStopped) == [true])
        #expect(made.clients.map(\.events) == [[]])
    }
    
    @Test
    func consentingAgainOpensANewClient() {
        analytics.setConsent(true)
        analytics.setConsent(false)
        analytics.setConsent(true)
        analytics.track(event)
        
        #expect(made.clients.map(\.events) == [[], [event]])
    }
    
    @Test
    func repeatedConsentKeepsTheSameClient() {
        analytics.setConsent(true)
        analytics.setConsent(true)
        
        #expect(made.clients.count == 1)
    }
}

@MainActor
private final class MadeClients {
    var clients: [FakeClient] = []
}

private final nonisolated class FakeClient: NativeCallAnalyticsClientProtocol {
    private let state = Mutex<(events: [ElementCallAnalyticsEvent], isStopped: Bool)>(([], false))
    
    var events: [ElementCallAnalyticsEvent] {
        state.withLock(\.events)
    }
    
    var isStopped: Bool {
        state.withLock(\.isStopped)
    }
    
    func capture(_ event: ElementCallAnalyticsEvent) {
        state.withLock { $0.events.append(event) }
    }
    
    func stop() {
        state.withLock { $0.isStopped = true }
    }
}
