//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Foundation
import Testing

@MainActor
struct PresenceReporterTests {
    let clientProxy: ClientProxyMock
    let appSettings: AppSettings
    
    /// Every applied `setPresence` call, forwarded off the mock so tests can await individual sends
    /// with `deferFulfillment` rather than sleeping.
    let sendsSubject = PassthroughSubject<(presence: ClientProxyPresence, sendImmediately: Bool), Never>()
    
    init() {
        clientProxy = ClientProxyMock(.init())
        appSettings = AppSettings.volatile()
        
        clientProxy.setPresenceSendImmediatelyClosure = { [sendsSubject] presence, sendImmediately in
            sendsSubject.send((presence, sendImmediately))
            return .success(())
        }
    }
    
    private func makeReporter(isForegroundActive: Bool) -> PresenceReporter {
        PresenceReporter(clientProxy: clientProxy, appSettings: appSettings, isForegroundActive: isForegroundActive)
    }

    @Test
    func becomingActiveWhileSharingReportsOnlineImmediately() async throws {
        appSettings.sharePresence = true
        let reporter = makeReporter(isForegroundActive: false)
        
        let deferred = deferFulfillment(sendsSubject) { $0.presence == .online }
        reporter.applicationDidBecomeActive()
        let send = try await deferred.fulfill()
        
        #expect(send.presence == .online)
        #expect(send.sendImmediately)
        #expect(clientProxy.setPresenceSendImmediatelyReceivedInvocations.filter { $0.presence == .online }.count == 1)
    }

    @Test
    func resigningActiveWhileSharingReportsUnavailableImmediately() async throws {
        appSettings.sharePresence = true
        let reporter = makeReporter(isForegroundActive: true)
        
        let deferred = deferFulfillment(sendsSubject) { $0.presence == .unavailable }
        reporter.applicationWillResignActive()
        let send = try await deferred.fulfill()
        
        #expect(send.presence == .unavailable)
        #expect(send.sendImmediately)
    }
    
    @Test
    func resigningActiveWhileNotSharingReportsOfflineImmediately() async throws {
        appSettings.sharePresence = false
        let reporter = makeReporter(isForegroundActive: true)
        
        let deferred = deferFulfillment(sendsSubject) { $0.presence == .offline }
        reporter.applicationWillResignActive()
        let send = try await deferred.fulfill()
        
        #expect(send.presence == .offline)
        #expect(send.sendImmediately)
    }

    @Test
    func neverReportsOnlineWhileSharingDisabled() async {
        enum Step: CaseIterable { case becomeActive, resignActive, toggleShareOff }
        
        // Every sequence of length ≤ 3 over the lifecycle/toggle steps, always with sharing forced off.
        var sequences: [[Step]] = [[]]
        for _ in 0..<3 {
            sequences += sequences.flatMap { prefix in Step.allCases.map { prefix + [$0] } }
        }
        
        for sequence in sequences {
            appSettings.sharePresence = false
            let reporter = makeReporter(isForegroundActive: false)
            
            for step in sequence {
                switch step {
                case .becomeActive: reporter.applicationDidBecomeActive()
                case .resignActive: reporter.applicationWillResignActive()
                case .toggleShareOff: appSettings.sharePresence = false
                }
            }
            
            // Drain the serialized send chain so any queued send has been applied before we assert.
            await reporter.awaitPendingSendsForTesting()
            
            #expect(!clientProxy.setPresenceSendImmediatelyReceivedInvocations.contains { $0.presence == .online },
                    "Sequence \(sequence) produced an online send with sharing disabled")
            clientProxy.setPresenceSendImmediatelyReceivedInvocations = []
        }
    }

    @Test
    func togglingSharingWhileActiveDrivesOnlineAndOffline() async throws {
        appSettings.sharePresence = false
        let reporter = makeReporter(isForegroundActive: true)
        
        let onlineDeferred = deferFulfillment(sendsSubject) { $0.presence == .online }
        appSettings.sharePresence = true
        let online = try await onlineDeferred.fulfill()
        #expect(online.presence == .online)
        #expect(online.sendImmediately)
        
        let offlineDeferred = deferFulfillment(sendsSubject) { $0.presence == .offline }
        appSettings.sharePresence = false
        let offline = try await offlineDeferred.fulfill()
        #expect(offline.presence == .offline)
        #expect(offline.sendImmediately)
        
        _ = reporter
    }

    @Test
    func repeatingTheSameStateSendsOnlyOnce() async {
        appSettings.sharePresence = true
        let reporter = makeReporter(isForegroundActive: false)
        
        reporter.applicationDidBecomeActive()
        reporter.applicationDidBecomeActive()
        reporter.applicationDidBecomeActive()
        
        await reporter.awaitPendingSendsForTesting()
        
        #expect(clientProxy.setPresenceSendImmediatelyReceivedInvocations.filter { $0.presence == .online }.count == 1)
    }

    @Test
    func newerTransitionWinsWhenAnEarlierSendIsInFlight() async {
        appSettings.sharePresence = true
        
        // Gate the first (.online) send so a newer transition can be enqueued behind it; on release, confirm
        // the server settles on the newest desired value, not the stale in-flight one.
        let gate = AsyncStream<Void>.makeStream()
        clientProxy.setPresenceSendImmediatelyClosure = { [sendsSubject] presence, sendImmediately in
            if presence == .online {
                var iterator = gate.stream.makeAsyncIterator()
                _ = await iterator.next()
            }
            sendsSubject.send((presence, sendImmediately))
            return .success(())
        }
        
        let reporter = makeReporter(isForegroundActive: true)

        reporter.applicationWillResignActive()

        // Release the gate; both sends now drain in order.
        gate.continuation.yield()
        gate.continuation.finish()
        
        await reporter.awaitPendingSendsForTesting()
        
        let applied = clientProxy.setPresenceSendImmediatelyReceivedInvocations.map(\.presence)
        #expect(applied == [.online, .unavailable], "Expected in-order latest-wins drain, got \(applied)")
    }

    @Test
    func reporterSeededActiveWhileSharingReportsOnline() async throws {
        appSettings.sharePresence = true
        
        let deferred = deferFulfillment(sendsSubject) { $0.presence == .online }
        let reporter = makeReporter(isForegroundActive: true)
        let send = try await deferred.fulfill()
        
        #expect(send.presence == .online)
        _ = reporter
    }
    
    @Test
    func reporterSeededBackgroundedSendsNonOnline() async throws {
        appSettings.sharePresence = true
        
        let deferred = deferFulfillment(sendsSubject) { $0.presence != .online }
        let reporter = makeReporter(isForegroundActive: false)
        let send = try await deferred.fulfill()
        
        #expect(send.presence == .unavailable)
        #expect(send.sendImmediately)
        _ = reporter
    }
}
