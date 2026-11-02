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
    
    /// The rooms of the calls started here and not ended yet, oldest first. The package can start a
    /// call while the previous one's end sound plays, so the last one is the live call.
    private let liveCallRoomIDsSubject: CurrentValueSubject<[String], Never>
    
    /// Set by the stack before each call it starts: the call takes over one answered from CallKit.
    var isAnswering = false
    
    /// Stored so the events keep flowing off the subject itself, without reaching back through the
    /// weak reference on every subscription.
    ///
    /// Hang-ups for any other room are dropped: the package ends whatever call it runs.
    let events: AnyPublisher<ElementCallSystemEvent, Never>
    
    init(service: ElementCallServiceProtocol) {
        let liveCallRoomIDsSubject = CurrentValueSubject<[String], Never>([])
        self.service = service
        self.liveCallRoomIDsSubject = liveCallRoomIDsSubject
        events = service.nativeCallEventsPublisher
            .filter { event in
                guard case let .endCallRequested(roomID) = event else { return true }
                return roomID == liveCallRoomIDsSubject.value.last
            }
            .map { ElementCallSystemEvent($0) }
            .eraseToAnyPublisher()
    }
    
    func startCall(roomID: String, displayName: String, isVideo: Bool) async {
        // Set before the await, as a refusal arrives while the set-up waits.
        liveCallRoomIDsSubject.value.append(roomID)
        await service?.setupCallSession(roomID: roomID, roomDisplayName: displayName, isVideo: isVideo, kind: isAnswering ? .nativeAnswer : .native)
    }
    
    func reportConnected(roomID: String) {
        service?.reportCallSessionConnected(roomID: roomID)
    }
    
    /// Only our own hang-up is an end call action; the rest the system hears as the call ending on
    /// its own, so the call log does not show a declined or unanswered call as one we ended.
    func endCall(roomID: String, reason: ElementCallEndReason) {
        if let index = liveCallRoomIDsSubject.value.firstIndex(of: roomID) {
            liveCallRoomIDsSubject.value.remove(at: index)
        }
        
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
