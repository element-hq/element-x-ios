//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import ElementCall
import Foundation
import PostHog
import Synchronization

/// Forwards the native call's analytics to Element Call's own PostHog project, the one the embedded
/// call reports to, and only while the user consents to analytics, as the embedded call does.
///
/// One for the app, shared by every account's call stack: PostHog keeps one instance per project.
/// `AnalyticsService` pushes the consent in through ``setConsent(_:)``.
final nonisolated class NativeCallAnalytics: ElementCallAnalyticsProtocol {
    private let makeClient: @MainActor () -> NativeCallAnalyticsClientProtocol?
    /// Only while the user consents: an event without one is dropped, never kept for later.
    private let client = Mutex<NativeCallAnalyticsClientProtocol?>(nil)
    
    init(makeClient: @escaping @MainActor () -> NativeCallAnalyticsClientProtocol?) {
        self.makeClient = makeClient
    }
    
    /// Opens the client on consent and stops it when consent is withdrawn, dropping its queued
    /// events and identifiers. Only ever called from the main actor, so the check and the swap
    /// cannot interleave.
    @MainActor
    func setConsent(_ hasConsent: Bool) {
        if hasConsent {
            guard client.withLock({ $0 == nil }) else { return }
            let newClient = makeClient()
            if newClient == nil {
                MXLog.warning("\(NativeCallStack.logPrefix) No PostHog configuration for the call, its analytics are dropped.")
            }
            client.withLock { $0 = newClient }
        } else {
            let oldClient = client.withLock { client in
                defer { client = nil }
                return client
            }
            oldClient?.stop()
        }
    }
    
    func track(_ event: ElementCallAnalyticsEvent) {
        client.withLock { $0?.capture(event) }
    }
}

/// Where ``NativeCallAnalytics`` sends the events it is allowed to.
nonisolated protocol NativeCallAnalyticsClientProtocol: Sendable {
    func capture(_ event: ElementCallAnalyticsEvent)
    /// Clears the identifiers and queued events, then stops.
    func stop()
}

/// A PostHog instance of its own, apart from the app's `PostHogSDK.shared`, with the app's privacy
/// settings. Never opted in or out: the instance only exists while the user consents, so PostHog
/// never stores a consent of its own that could outlive the user's.
final nonisolated class PostHogNativeCallAnalyticsClient: NativeCallAnalyticsClientProtocol, @unchecked Sendable {
    // PostHogSDK is thread-safe but not marked Sendable.
    private let postHog: PostHogSDK
    
    @MainActor
    init?(configuration: AnalyticsConfiguration) {
        guard let config = PostHogConfig.standard(analyticsConfiguration: configuration) else { return nil }
        postHog = PostHogSDK.with(config)
    }
    
    func capture(_ event: ElementCallAnalyticsEvent) {
        let properties = event.properties.mapValues { value -> Any in
            switch value {
            case .string(let string): string
            case .int(let int): int
            }
        }
        postHog.capture(event.name, properties: properties)
    }
    
    func stop() {
        // The order is important here. PostHog ignores the reset once closed.
        postHog.reset()
        postHog.close()
    }
}
