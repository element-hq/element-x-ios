//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import ElementCallAll

/// Serves the call package's system-call port from `ElementCallService`.
///
/// Stays app-side because the same `CXProvider` and VoIP push registry serve the web-view call path
/// too, so ownership can't be handed to the package.
final class NativeCallSystem: ElementCallSystemProviding {
    private let service: ElementCallServiceProtocol
    
    init(service: ElementCallServiceProtocol) {
        self.service = service
    }
    
    var events: AnyPublisher<ElementCallSystemEvent, Never> {
        service.actions
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
                // Both are navigation, handled by the flow coordinator. The call reaches this port
                // later, as an ordinary start.
                case .startCall, .receivedIncomingCallRequest:
                    nil
                }
            }
            .eraseToAnyPublisher()
    }
    
    func startCall(roomID: String, displayName: String, isVideo: Bool) async {
        await service.setupCallSession(roomID: roomID, roomDisplayName: displayName, isVideo: isVideo)
    }
    
    func reportConnected(roomID: String) {
        service.reportCallSessionConnected(roomID: roomID)
    }
    
    func endCall(roomID: String) {
        service.tearDownCallSession(roomID: roomID)
    }
    
    func setMicrophoneEnabled(_ enabled: Bool, roomID: String) {
        service.setAudioEnabled(enabled, roomID: roomID)
    }
}
