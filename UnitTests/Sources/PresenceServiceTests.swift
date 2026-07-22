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
import UIKit

@MainActor
struct PresenceServiceTests {
    let clientProxy: ClientProxyMock
    let appSettings: AppSettings
    let notificationCenter: NotificationCenter
    
    let sendsSubject = PassthroughSubject<(presence: ClientProxyPresence, sendImmediately: Bool), Never>()
    
    init() {
        clientProxy = ClientProxyMock(.init())
        appSettings = AppSettings.volatile()
        notificationCenter = NotificationCenter()
        
        clientProxy.configurePresenceSendImmediatelyClosure = { [sendsSubject] presence, sendImmediately in
            sendsSubject.send((presence, sendImmediately))
            return .success(())
        }
    }
    
    private func makeService(initialApplicationState: UIApplication.State) -> PresenceService {
        PresenceService(clientProxy: clientProxy,
                        appSettings: appSettings,
                        notificationCenter: notificationCenter,
                        initialApplicationState: initialApplicationState)
    }
    
    @Test
    func serviceSeededActiveWhileSharingReportsOnline() async throws {
        appSettings.sharePresence = true
        
        let deferred = deferFulfillment(sendsSubject) { $0.presence == .online }
        let service = makeService(initialApplicationState: .active)
        let send = try await deferred.fulfill()
        
        #expect(send.presence == .online)
        #expect(send.sendImmediately)
        #expect(clientProxy.configurePresenceSendImmediatelyReceivedInvocations.filter { $0.presence == .online }.count == 1)
        _ = service
    }
    
    @Test
    func serviceSeededBackgroundedWhileSharingReportsUnavailable() async throws {
        appSettings.sharePresence = true
        
        let deferred = deferFulfillment(sendsSubject) { $0.presence == .unavailable }
        let service = makeService(initialApplicationState: .background)
        let send = try await deferred.fulfill()
        
        #expect(send.presence == .unavailable)
        #expect(send.sendImmediately)
        _ = service
    }
    
    @Test
    func serviceSeededActiveWhileNotSharingReportsOffline() async throws {
        appSettings.sharePresence = false
        
        let deferred = deferFulfillment(sendsSubject) { $0.presence == .offline }
        let service = makeService(initialApplicationState: .active)
        let send = try await deferred.fulfill()
        
        #expect(send.presence == .offline)
        #expect(send.sendImmediately)
        _ = service
    }
    
    @Test
    func becomingActiveNotificationWhileSharingReportsOnlineImmediately() async throws {
        appSettings.sharePresence = true
        let service = makeService(initialApplicationState: .inactive)
        
        let deferred = deferFulfillment(sendsSubject) { $0.presence == .online }
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        let send = try await deferred.fulfill()
        
        #expect(send.presence == .online)
        #expect(send.sendImmediately)
        _ = service
    }
    
    @Test
    func resigningActiveNotificationWhileSharingReportsUnavailableImmediately() async throws {
        appSettings.sharePresence = true
        let initialDeferred = deferFulfillment(sendsSubject) { $0.presence == .online }
        let service = makeService(initialApplicationState: .active)
        _ = try await initialDeferred.fulfill()
        
        let deferred = deferFulfillment(sendsSubject) { $0.presence == .unavailable }
        notificationCenter.post(name: UIApplication.willResignActiveNotification, object: nil)
        let send = try await deferred.fulfill()
        
        #expect(send.presence == .unavailable)
        #expect(send.sendImmediately)
        _ = service
    }
    
    @Test
    func togglingSharingWhileActiveDrivesOnlineAndOffline() async throws {
        appSettings.sharePresence = false
        let initialDeferred = deferFulfillment(sendsSubject) { $0.presence == .offline }
        let service = makeService(initialApplicationState: .active)
        _ = try await initialDeferred.fulfill()
        
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
        
        _ = service
    }
    
    @Test
    func repeatingTheSameStateSendsOnlyOnce() async throws {
        appSettings.sharePresence = true
        
        let initialDeferred = deferFulfillment(sendsSubject) { $0.presence == .online }
        let service = makeService(initialApplicationState: .active)
        _ = try await initialDeferred.fulfill()
        await Task.yield()
        
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        await Task.yield()
        
        #expect(clientProxy.configurePresenceSendImmediatelyReceivedInvocations.map(\.presence) == [.online])
        _ = service
    }
    
    @Test
    func failedImmediateSendIsNotRetriedUntilTheDesiredPresenceChanges() async throws {
        appSettings.sharePresence = true
        clientProxy.configurePresenceSendImmediatelyClosure = { [sendsSubject] presence, sendImmediately in
            sendsSubject.send((presence, sendImmediately))
            return presence == .online ? .failure(.forbiddenAccess) : .success(())
        }
        
        let initialDeferred = deferFulfillment(sendsSubject) { $0.presence == .online }
        let service = makeService(initialApplicationState: .active)
        _ = try await initialDeferred.fulfill()
        await Task.yield()
        
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        await Task.yield()
        #expect(clientProxy.configurePresenceSendImmediatelyReceivedInvocations.map(\.presence) == [.online])
        
        let transitionDeferred = deferFulfillment(sendsSubject) { $0.presence == .unavailable }
        notificationCenter.post(name: UIApplication.willResignActiveNotification, object: nil)
        _ = try await transitionDeferred.fulfill()
        
        #expect(clientProxy.configurePresenceSendImmediatelyReceivedInvocations.map(\.presence) == [.online, .unavailable])
        _ = service
    }
    
    @Test
    func newerTransitionWinsWhenAnEarlierSendIsInFlight() async throws {
        appSettings.sharePresence = true
        
        let onlineStarted = PassthroughSubject<Void, Never>()
        let gate = AsyncStream<Void>.makeStream()
        clientProxy.configurePresenceSendImmediatelyClosure = { [sendsSubject, onlineStarted] presence, sendImmediately in
            if presence == .online {
                onlineStarted.send(())
                var iterator = gate.stream.makeAsyncIterator()
                _ = await iterator.next()
            }
            
            sendsSubject.send((presence, sendImmediately))
            return .success(())
        }
        
        let onlineStartedDeferred = deferFulfillment(onlineStarted) { _ in true }
        let service = makeService(initialApplicationState: .active)
        try await onlineStartedDeferred.fulfill()
        
        let unavailableDeferred = deferFulfillment(sendsSubject) { $0.presence == .unavailable }
        notificationCenter.post(name: UIApplication.willResignActiveNotification, object: nil)
        
        gate.continuation.yield()
        gate.continuation.finish()
        try await unavailableDeferred.fulfill()
        
        let applied = clientProxy.configurePresenceSendImmediatelyReceivedInvocations.map(\.presence)
        #expect(applied == [.online, .unavailable], "Expected in-order latest-wins drain, got \(applied)")
        _ = service
    }
    
    @Test
    func deinitCancelsPendingSend() async throws {
        appSettings.sharePresence = true
        
        let onlineStarted = AsyncStream.makeStream(of: Void.self)
        let onlineCancelled = AsyncStream.makeStream(of: Void.self)
        let onlineCompleted = AsyncStream.makeStream(of: Void.self)
        let gate = AsyncStream.makeStream(of: Void.self)
        let gateContinuation = gate.continuation
        let onlineCancelledContinuation = onlineCancelled.continuation
        let onlineCompletedContinuation = onlineCompleted.continuation
        
        clientProxy.configurePresenceSendImmediatelyClosure = { presence, _ in
            guard presence == .online else {
                return .success(())
            }
            
            onlineStarted.continuation.yield()
            let result: Result<Void, ClientProxyError> = await withTaskCancellationHandler {
                var iterator = gate.stream.makeAsyncIterator()
                _ = await iterator.next()
                return .success(())
            } onCancel: {
                gateContinuation.finish()
                onlineCancelledContinuation.yield()
                onlineCancelledContinuation.finish()
            }
            onlineCompletedContinuation.yield()
            onlineCompletedContinuation.finish()
            
            return result
        }
        
        let onlineStartedDeferred = deferFulfillment(onlineStarted.stream) { _ in true }
        var service: PresenceService? = makeService(initialApplicationState: .active)
        #expect(service != nil)
        try await onlineStartedDeferred.fulfill()
        
        notificationCenter.post(name: UIApplication.willResignActiveNotification, object: nil)
        
        let onlineCancelledDeferred = deferFulfillment(onlineCancelled.stream) { _ in true }
        let onlineCompletedDeferred = deferFulfillment(onlineCompleted.stream) { _ in true }
        service = nil
        try await onlineCancelledDeferred.fulfill()
        try await onlineCompletedDeferred.fulfill()
        
        let applied = clientProxy.configurePresenceSendImmediatelyReceivedInvocations.map(\.presence)
        #expect(applied == [.online], "Expected deinit to cancel the queued unavailable send, got \(applied)")
    }
}
