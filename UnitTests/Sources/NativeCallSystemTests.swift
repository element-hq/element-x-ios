//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import ElementCall
@testable import ElementX
import Testing

struct NativeCallSystemTests {
    private let service = ElementCallServiceMock(.init())
    private let nativeCallEvents = PassthroughSubject<NativeCallEvent, Never>()
    private let system: NativeCallSystem
    
    init() {
        service.nativeCallEventsPublisher = nativeCallEvents.eraseToAnyPublisher()
        system = NativeCallSystem(service: service)
    }
    
    @Test
    func startCallSetsUpNativeSession() async {
        await system.startCall(roomID: "!room:example.com", displayName: "welcome", isVideo: true)
        
        #expect(service.setupCallSessionRoomIDRoomDisplayNameIsVideoKindReceivedArguments?.kind == .native)
    }
    
    @Test
    func eventsReachCallStack() async {
        var events: [ElementCallSystemEvent] = []
        let cancellable = system.events.sink { events.append($0) }
        defer { cancellable.cancel() }
        
        await system.startCall(roomID: "!room:example.com", displayName: "welcome", isVideo: true)
        nativeCallEvents.send(.audioSessionActivated)
        nativeCallEvents.send(.audioSessionDeactivated)
        nativeCallEvents.send(.microphoneMuteChanged(isMuted: true))
        nativeCallEvents.send(.endCallRequested(roomID: "!room:example.com"))
        
        #expect(events == [.audioSessionActivated,
                           .audioSessionDeactivated,
                           .microphoneMuteChanged(isMuted: true),
                           .endCallRequested(roomID: "!room:example.com")])
    }
    
    @Test("Only the live call hears a hang-up request")
    func endRequestsReachLiveCallOnly() async {
        var events: [ElementCallSystemEvent] = []
        let cancellable = system.events.sink { events.append($0) }
        defer { cancellable.cancel() }
        
        // The manager's refusal arrives while the set-up is waiting.
        service.setupCallSessionRoomIDRoomDisplayNameIsVideoKindClosure = { [nativeCallEvents] roomID, _, _, _ in
            nativeCallEvents.send(.endCallRequested(roomID: roomID))
        }
        
        await system.startCall(roomID: "!room:example.com", displayName: "welcome", isVideo: true)
        nativeCallEvents.send(.endCallRequested(roomID: "!other:example.com"))
        system.endCall(roomID: "!room:example.com", reason: .local)
        nativeCallEvents.send(.endCallRequested(roomID: "!room:example.com"))
        
        #expect(events == [.endCallRequested(roomID: "!room:example.com")])
    }
    
    @Test("A call started while the previous one was ending still hears a hang-up request",
          arguments: ["!other:example.com", "!room:example.com"])
    func endRequestsReachNewerCall(roomID: String) async {
        var events: [ElementCallSystemEvent] = []
        let cancellable = system.events.sink { events.append($0) }
        defer { cancellable.cancel() }
        
        await system.startCall(roomID: "!room:example.com", displayName: "welcome", isVideo: true)
        await system.startCall(roomID: roomID, displayName: "welcome", isVideo: true)
        system.endCall(roomID: "!room:example.com", reason: .local)
        nativeCallEvents.send(.endCallRequested(roomID: roomID))
        
        #expect(events == [.endCallRequested(roomID: roomID)])
    }
    
    @Test
    func localEndTearsDownCall() {
        system.endCall(roomID: "!room:example.com", reason: .local)
        
        #expect(service.tearDownCallSessionRoomIDReceivedRoomID == "!room:example.com")
        #expect(!service.reportCallSessionEndedRoomIDReasonCalled)
    }
    
    @Test(arguments: [(ElementCallEndReason.remoteEnded, CallEndReason.remoteEnded),
                      (.unanswered, .unanswered),
                      (.failed, .failed)])
    func otherEndIsReportedWithReason(reason: ElementCallEndReason, expectedReason: CallEndReason) {
        system.endCall(roomID: "!room:example.com", reason: reason)
        
        #expect(service.reportCallSessionEndedRoomIDReasonReceivedArguments?.roomID == "!room:example.com")
        #expect(service.reportCallSessionEndedRoomIDReasonReceivedArguments?.reason == expectedReason)
        #expect(!service.tearDownCallSessionRoomIDCalled)
    }
}
