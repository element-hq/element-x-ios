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
    private let serviceActions: AnyPublisher<ElementCallServiceAction, Never>
    
    init(service: ElementCallServiceProtocol) {
        self.service = service
        serviceActions = service.actions
    }
    
    var events: AnyPublisher<ElementCallSystemEvent, Never> {
        serviceActions
            .compactMap { action in
                switch action {
                case .audioSessionActivated:
                    .audioSessionActivated
                case .audioSessionDeactivated:
                    .audioSessionDeactivated
                case .setAudioEnabled(let enabled, _):
                    // The system reports what the microphone should be; the port speaks in mutes.
                    .microphoneMuteChanged(isMuted: !enabled)
                case .endCall(let roomID):
                    .endCallRequested(roomID: roomID)
                // All navigation, handled by the flow coordinator. The call reaches this port later,
                // as an ordinary start.
                case .startCall, .receivedIncomingCallRequest, .nativeCall:
                    nil
                }
            }
            .eraseToAnyPublisher()
    }
    
    func startCall(roomID: String, displayName: String, isVideo: Bool) async {
        await service?.setupCallSession(roomID: roomID, roomDisplayName: displayName, isVideo: isVideo)
    }
    
    func reportConnected(roomID: String) {
        service?.reportCallSessionConnected(roomID: roomID)
    }
    
    func endCall(roomID: String) {
        service?.tearDownCallSession(roomID: roomID)
    }
    
    func setMicrophoneEnabled(_ enabled: Bool, roomID: String) {
        service?.setAudioEnabled(enabled, roomID: roomID)
    }
}
