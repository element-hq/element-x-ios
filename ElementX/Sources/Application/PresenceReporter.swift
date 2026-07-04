//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

/// Owns the app's presence reporting. It maps the two axes that determine presence — whether the app is
/// foreground-active and whether the user shares presence — onto a single desired `ClientProxyPresence` and
/// pushes it to the server. Sending is deduped and serialised latest-wins so a late background update can never
/// land after a newer foreground one.
final class PresenceReporter {
    private let clientProxy: ClientProxyProtocol
    private let appSettings: AppSettings
    
    private var isForegroundActive: Bool
    private var lastSentPresence: ClientProxyPresence?
    
    /// Chains sends so they never interleave; each reconcile drives the server to the *latest* desired presence.
    private var sendTask: Task<Void, Never>?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(clientProxy: ClientProxyProtocol, appSettings: AppSettings, isForegroundActive: Bool) {
        self.clientProxy = clientProxy
        self.appSettings = appSettings
        self.isForegroundActive = isForegroundActive
        
        appSettings.sharePresencePublisher
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.reportCurrentState()
            }
            .store(in: &cancellables)
        
        reportCurrentState()
    }
    
    func applicationDidBecomeActive() {
        isForegroundActive = true
        reportCurrentState()
    }
    
    func applicationWillResignActive() {
        isForegroundActive = false
        reportCurrentState()
    }
    
    private var desiredPresence: ClientProxyPresence {
        switch (isForegroundActive, appSettings.sharePresence) {
        case (true, true):
            .online
        case (true, false):
            .offline
        case (false, true):
            .unavailable
        case (false, false):
            .offline
        }
    }
    
    private func reportCurrentState() {
        let presence = desiredPresence
        guard presence != lastSentPresence else {
            return
        }
        
        lastSentPresence = presence
        send(presence)
    }
    
    private func send(_ presence: ClientProxyPresence) {
        let previousTask = sendTask
        sendTask = Task { [weak self] in
            await previousTask?.value
            guard let self, !Task.isCancelled else {
                return
            }
            _ = await clientProxy.setPresence(presence, sendImmediately: true)
        }
    }
}

extension PresenceReporter {
    /// Awaits the tail of the serialised send chain so tests can assert on a settled state.
    func awaitPendingSendsForTesting() async {
        await sendTask?.value
    }
}
