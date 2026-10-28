//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import ElementCall

/// Serves the call package's system-call port from `ElementCallService`.
///
/// Stays app-side because the same `CXProvider` and VoIP push registry serve the web-view call path
/// too, so ownership can't be handed to the package.
final class NativeCallSystem: ElementCallSystemProvidingProtocol {
    /// Weak because the service owns the call stack, which owns the controller holding this port.
    private weak var service: ElementCallServiceProtocol?
    
    /// Stored so the events keep flowing off the subject itself, without reaching back through the
    /// weak reference on every subscription.
    let events: AnyPublisher<ElementCallSystemEvent, Never>
    
    init(service: ElementCallServiceProtocol) {
        self.service = service
        events = service.nativeCallEventsPublisher
            .map { ElementCallSystemEvent($0) }
            .eraseToAnyPublisher()
    }
    
    func startCall(roomID: String, displayName: String, isVideo: Bool) async {
        await service?.setupCallSession(roomID: roomID, roomDisplayName: displayName, isVideo: isVideo, kind: .native)
    }
    
    func reportConnected(roomID: String) {
        service?.reportCallSessionConnected(roomID: roomID)
    }
    
    /// Only our own hang-up is an end call action; the rest the system hears as the call ending on
    /// its own, so the call log does not show a declined or unanswered call as one we ended.
    func endCall(roomID: String, reason: ElementCallEndReason) {
        switch reason {
        case .local:
            service?.tearDownCallSession(roomID: roomID)
        case .remoteEnded:
            service?.reportCallSessionEnded(roomID: roomID, reason: .remoteEnded)
        case .unanswered:
            service?.reportCallSessionEnded(roomID: roomID, reason: .unanswered)
        case .failed:
            service?.reportCallSessionEnded(roomID: roomID, reason: .failed)
        }
    }
    
    func setMicrophoneEnabled(_ enabled: Bool, roomID: String) {
        service?.setAudioEnabled(enabled, roomID: roomID)
    }
}

private extension ElementCallSystemEvent {
    init(_ event: NativeCallEvent) {
        self = switch event {
        case .audioSessionActivated:
            .audioSessionActivated
        case .audioSessionDeactivated:
            .audioSessionDeactivated
        case .microphoneMuteChanged(let isMuted):
            .microphoneMuteChanged(isMuted: isMuted)
        case .endCallRequested(let roomID):
            .endCallRequested(roomID: roomID)
        }
    }
}
