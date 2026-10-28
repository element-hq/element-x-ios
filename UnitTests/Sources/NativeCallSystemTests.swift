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
    
    @Test
    func startingACallSetsUpANativeSession() async {
        let system = NativeCallSystem(service: service)
        
        await system.startCall(roomID: "!room:example.com", displayName: "welcome", isVideo: true)
        
        #expect(service.setupCallSessionRoomIDRoomDisplayNameIsVideoKindReceivedArguments?.kind == .native)
    }
    
    @Test
    func nativeCallEventsReachTheCallStack() {
        let nativeCallEvents = PassthroughSubject<NativeCallEvent, Never>()
        service.nativeCallEventsPublisher = nativeCallEvents.eraseToAnyPublisher()
        let system = NativeCallSystem(service: service)
        
        var events: [ElementCallSystemEvent] = []
        let cancellable = system.events.sink { events.append($0) }
        defer { cancellable.cancel() }
        
        nativeCallEvents.send(.audioSessionActivated)
        nativeCallEvents.send(.audioSessionDeactivated)
        nativeCallEvents.send(.microphoneMuteChanged(isMuted: true))
        nativeCallEvents.send(.endCallRequested(roomID: "!room:example.com"))
        
        #expect(events == [.audioSessionActivated,
                           .audioSessionDeactivated,
                           .microphoneMuteChanged(isMuted: true),
                           .endCallRequested(roomID: "!room:example.com")])
    }
    
    @Test
    func ourHangUpTearsTheCallDown() {
        let system = NativeCallSystem(service: service)
        
        system.endCall(roomID: "!room:example.com", reason: .local)
        
        #expect(service.tearDownCallSessionRoomIDReceivedRoomID == "!room:example.com")
        #expect(!service.reportCallSessionEndedRoomIDReasonCalled)
    }
    
    @Test(arguments: [(ElementCallEndReason.remoteEnded, CallEndReason.remoteEnded),
                      (.unanswered, .unanswered),
                      (.failed, .failed)])
    func aCallThatEndedWithoutUsIsReportedWithItsReason(reason: ElementCallEndReason, expectedReason: CallEndReason) {
        let system = NativeCallSystem(service: service)
        
        system.endCall(roomID: "!room:example.com", reason: reason)
        
        #expect(service.reportCallSessionEndedRoomIDReasonReceivedArguments?.roomID == "!room:example.com")
        #expect(service.reportCallSessionEndedRoomIDReasonReceivedArguments?.reason == expectedReason)
        #expect(!service.tearDownCallSessionRoomIDCalled)
    }
}
