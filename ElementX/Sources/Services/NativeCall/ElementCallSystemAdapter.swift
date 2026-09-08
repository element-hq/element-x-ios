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
/// This stays app-side because the provider is process-wide and shared with the web-view call path:
/// the same `CXProvider` and VoIP push registry answer both, so it cannot be handed over.
@MainActor
final class ElementCallSystemAdapter: ElementCallSystemProviding {
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
                // Neither is this port's business. Answering a push is navigation, so the flow
                // coordinator handles it and the call arrives here as an ordinary start; an
                // incoming request only means the system is ringing.
                case .startCall, .receivedIncomingCallRequest:
                    nil
                }
            }
            .eraseToAnyPublisher()
    }
    
    func startCall(roomID: String, displayName: String, isVideo: Bool) async {
        await service.startNativeCallSession(roomID: roomID, roomDisplayName: displayName, isVideo: isVideo)
    }
    
    func reportConnected(roomID: String) {
        service.reportNativeCallConnected(roomID: roomID)
    }
    
    func endCall(roomID: String) {
        service.endNativeCallSession(roomID: roomID)
    }
    
    func setMicrophoneEnabled(_ enabled: Bool, roomID: String) {
        service.setAudioEnabled(enabled, roomID: roomID)
    }
}
