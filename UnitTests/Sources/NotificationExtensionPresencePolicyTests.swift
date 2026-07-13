//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import MatrixRustSDK
import Synchronization
import Testing
import UIKit

struct NotificationExtensionPresencePolicyTests {
    @Test
    func freshForegroundActiveStateSkipsForcingOfflinePresence() {
        let currentSystemUptime: TimeInterval = 100

        #expect(!NotificationExtensionPresencePolicy(sharePresence: true,
                                                     mainAppActivityStateSnapshot: snapshot(lastUpdatedSystemUptime: currentSystemUptime))
                .shouldForceOfflinePresence(currentSystemUptime: currentSystemUptime))
        #expect(!NotificationExtensionPresencePolicy(sharePresence: true,
                                                     mainAppActivityStateSnapshot: snapshot(lastUpdatedSystemUptime: currentSystemUptime - NotificationExtensionPresencePolicy.foregroundActiveMaximumAge))
                .shouldForceOfflinePresence(currentSystemUptime: currentSystemUptime))
    }

    @Test
    func staleForegroundActiveStateForcesOfflinePresence() {
        let currentSystemUptime: TimeInterval = 100
        let staleSystemUptime = currentSystemUptime - NotificationExtensionPresencePolicy.foregroundActiveMaximumAge - 1

        #expect(NotificationExtensionPresencePolicy(sharePresence: true,
                                                    mainAppActivityStateSnapshot: snapshot(lastUpdatedSystemUptime: staleSystemUptime))
                .shouldForceOfflinePresence(currentSystemUptime: currentSystemUptime))
    }

    @Test
    func missingOrFutureForegroundActiveTimestampForcesOfflinePresence() {
        let currentSystemUptime: TimeInterval = 100

        #expect(NotificationExtensionPresencePolicy(sharePresence: true,
                                                    mainAppActivityStateSnapshot: snapshot(lastUpdatedSystemUptime: nil))
                .shouldForceOfflinePresence(currentSystemUptime: currentSystemUptime))
        #expect(NotificationExtensionPresencePolicy(sharePresence: true,
                                                    mainAppActivityStateSnapshot: snapshot(lastUpdatedSystemUptime: currentSystemUptime + 1))
                .shouldForceOfflinePresence(currentSystemUptime: currentSystemUptime))
    }

    @Test
    func nonForegroundActiveStateForcesOfflinePresence() {
        let currentSystemUptime: TimeInterval = 100

        for mainAppActivityState in [MainAppActivityState.inactive, .background, .terminated] {
            #expect(NotificationExtensionPresencePolicy(sharePresence: true,
                                                        mainAppActivityStateSnapshot: snapshot(state: mainAppActivityState,
                                                                                               lastUpdatedSystemUptime: currentSystemUptime))
                    .shouldForceOfflinePresence(currentSystemUptime: currentSystemUptime))
        }
    }

    @Test
    func disabledSharePresenceForcesOfflinePresence() {
        let currentSystemUptime: TimeInterval = 100

        #expect(NotificationExtensionPresencePolicy(sharePresence: false,
                                                    mainAppActivityStateSnapshot: snapshot(lastUpdatedSystemUptime: currentSystemUptime))
                .shouldForceOfflinePresence(currentSystemUptime: currentSystemUptime))
    }

    @Test
    func sharedPresenceStateStoreStoresMainAppActivityStateSnapshot() throws {
        let suiteName = "io.element.elementx.tests.sharedPresenceStateStore.\(UUID().uuidString)"
        let store = try #require(TrackedUserDefaults(suiteName: suiteName))
        defer { store.removePersistentDomain(forName: suiteName) }
        let sharedPresenceStateStore = SharedPresenceStateStore(suiteName: suiteName)

        sharedPresenceStateStore.updateMainAppActivityState(.foregroundActive, systemUptime: 100)

        #expect(sharedPresenceStateStore.mainAppActivityStateSnapshot == .init(state: .foregroundActive, lastUpdatedSystemUptime: 100))
        #expect(store.data(forKey: "mainAppActivityStateSnapshot") != nil)
        #expect(store.object(forKey: "mainAppActivityState") == nil)
        #expect(store.object(forKey: "mainAppActivityStateLastUpdatedSystemUptime") == nil)
    }

    @Test
    func applicationStatesMapToMainAppActivityStates() {
        #expect(UIApplication.State.active.mainAppActivityState == .foregroundActive)
        #expect(UIApplication.State.inactive.mainAppActivityState == .inactive)
        #expect(UIApplication.State.background.mainAppActivityState == .background)
    }

    @Test
    func notificationFetchForcesOfflinePresenceBeforeFetchingWhenPolicyRequiresIt() async throws {
        let result = try await performNotificationFetch(snapshot: .default)

        #expect(result.value == "notification")
        #expect(result.events == [.forceOfflinePresence, .fetch])
    }

    @Test
    func notificationFetchSkipsOfflinePresenceForFreshForegroundMainApp() async throws {
        let currentSystemUptime: TimeInterval = 100
        let result = try await performNotificationFetch(snapshot: snapshot(lastUpdatedSystemUptime: currentSystemUptime),
                                                        currentSystemUptime: currentSystemUptime)

        #expect(result.value == "notification")
        #expect(result.events == [.fetch])
    }

    @Test
    func notificationFetchContinuesWhenOfflinePresenceFails() async throws {
        let result = try await performNotificationFetch(snapshot: .default,
                                                        forceOfflineError: TestError.presenceFailed)

        #expect(result.value == "notification")
        #expect(result.events == [.forceOfflinePresence, .fetch])
    }

    @Test
    func nseNotificationItemProxyForcesOfflinePresenceBeforeFetchingWhenPolicyRequiresIt() async {
        let result = await performNSENotificationFetch(snapshot: .default)

        #expect(result.notificationItemProxy == nil)
        #expect(result.events == [.forceOfflinePresence, .fetch])
    }

    @Test
    func nseNotificationItemProxyFetchesNotificationWhenOfflinePresenceFails() async {
        let result = await performNSENotificationFetch(snapshot: .default,
                                                       forceOfflineError: TestError.presenceFailed)

        #expect(result.notificationItemProxy == nil)
        #expect(result.events == [.forceOfflinePresence, .fetch])
    }

    private func snapshot(state: MainAppActivityState = .foregroundActive,
                          lastUpdatedSystemUptime: TimeInterval?) -> MainAppActivityStateSnapshot {
        MainAppActivityStateSnapshot(state: state, lastUpdatedSystemUptime: lastUpdatedSystemUptime)
    }

    private func performNotificationFetch(snapshot: MainAppActivityStateSnapshot,
                                          sharePresence: Bool = true,
                                          currentSystemUptime: TimeInterval = 100,
                                          forceOfflineError: Error? = nil) async throws -> (value: String, events: [NotificationFetchEvent]) {
        let recorder = NotificationFetchRecorder()
        let policy = NotificationExtensionPresencePolicy(sharePresence: sharePresence,
                                                         mainAppActivityStateSnapshot: snapshot)
        let value = try await policy.performBeforeNotificationFetch(currentSystemUptime: currentSystemUptime) {
            await recorder.record(.forceOfflinePresence)

            if let forceOfflineError {
                throw forceOfflineError
            }
        } fetchNotification: {
            await recorder.record(.fetch)
            return "notification"
        }

        return (value, await recorder.events)
    }

    private func performNSENotificationFetch(snapshot: MainAppActivityStateSnapshot,
                                             sharePresence: Bool = true,
                                             forceOfflineError: Error? = nil) async -> (
        notificationItemProxy: NotificationItemProxyProtocol?,
        events: [NotificationFetchEvent]
    ) {
        let appSettings = AppSettings.volatile()
        appSettings.sharePresence = sharePresence
        let sharedPresenceStateStore = TestSharedPresenceStateStore(snapshot: snapshot)

        let recorder = NotificationFetchRecorder()
        let notificationItemProxy = await NSEUserSession.notificationItemProxy(roomID: "!room:example.com",
                                                                              eventID: "$event",
                                                                              userID: "@alice:example.com",
                                                                              appSettings: appSettings,
                                                                              sharedPresenceStateStore: sharedPresenceStateStore) {
            await recorder.record(.forceOfflinePresence)

            if let forceOfflineError {
                throw forceOfflineError
            }
        } fetchNotification: {
            await recorder.record(.fetch)
            return NotificationStatus.eventNotFound
        }

        return (notificationItemProxy, await recorder.events)
    }

    private enum TestError: Error {
        case presenceFailed
    }

    private enum NotificationFetchEvent: Equatable {
        case forceOfflinePresence
        case fetch
    }

    private actor NotificationFetchRecorder {
        private(set) var events = [NotificationFetchEvent]()

        func record(_ event: NotificationFetchEvent) {
            events.append(event)
        }
    }

    private final class TestSharedPresenceStateStore: SharedPresenceStateStoreProtocol {
        private let snapshot: Mutex<MainAppActivityStateSnapshot>

        init(snapshot: MainAppActivityStateSnapshot = .default) {
            self.snapshot = Mutex(snapshot)
        }

        var mainAppActivityStateSnapshot: MainAppActivityStateSnapshot {
            get { snapshot.withLock { $0 } }
            set { snapshot.withLock { $0 = newValue } }
        }

        func updateMainAppActivityState(_ state: MainAppActivityState, systemUptime: TimeInterval) {
            mainAppActivityStateSnapshot = MainAppActivityStateSnapshot(state: state, lastUpdatedSystemUptime: systemUptime)
        }
    }
}
