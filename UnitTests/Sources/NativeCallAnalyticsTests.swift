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
    private let made = MadeNativeCallAnalyticsClients()
    private let analytics: NativeCallAnalytics
    
    init() {
        analytics = made.makeAnalytics()
    }
    
    @Test("Nothing is sent when tracking an event without consent")
    func trackEventWithoutConsent() {
        analytics.track(event)
        
        #expect(made.clients.isEmpty)
    }
    
    @Test("Events are sent once the user consents")
    func trackEventWithConsent() {
        analytics.setConsent(true)
        analytics.track(event)
        
        #expect(made.clients.map(\.events) == [[event]])
    }
    
    @Test("Withdrawing consent stops the client and drops later events")
    func withdrawConsent() {
        analytics.setConsent(true)
        analytics.setConsent(false)
        analytics.track(event)
        
        #expect(made.clients.map(\.isStopped) == [true])
        #expect(made.clients.map(\.events) == [[]])
    }
    
    @Test("Consenting again opens a new client")
    func consentAgain() {
        analytics.setConsent(true)
        analytics.setConsent(false)
        analytics.setConsent(true)
        analytics.track(event)
        
        #expect(made.clients.map(\.events) == [[], [event]])
    }
    
    @Test("Consenting twice keeps the same client")
    func repeatedConsent() {
        analytics.setConsent(true)
        analytics.setConsent(true)
        
        #expect(made.clients.count == 1)
    }
}

/// Every client a ``NativeCallAnalytics`` made, in order.
@MainActor
final class MadeNativeCallAnalyticsClients {
    var clients: [FakeNativeCallAnalyticsClient] = []
    
    func makeAnalytics() -> NativeCallAnalytics {
        NativeCallAnalytics { [self] in
            let client = FakeNativeCallAnalyticsClient()
            clients.append(client)
            return client
        }
    }
}

final nonisolated class FakeNativeCallAnalyticsClient: NativeCallAnalyticsClientProtocol {
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
