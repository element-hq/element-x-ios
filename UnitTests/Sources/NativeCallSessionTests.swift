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

@MainActor
final class NativeCallSessionTests {
    private let session: NativeCallSession
    private var presentations: [NativeCallPresentation] = []
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        session = NativeCallSession(transport: ElementCallFakeTransport(),
                                    system: ElementCallFakeSystem(),
                                    options: ElementCallOptions(),
                                    style: .stock,
                                    logger: nil)
        
        session.actions
            .sink { [weak self] presentation in
                self?.presentations.append(presentation)
            }
            .store(in: &cancellables)
    }
    
    @Test
    func startingACallAsksForItsScreen() {
        session.handleCallRequest(roomProxy: roomProxy(id: "!room:example.com"), isVoiceCall: false)
        
        #expect(presentations == [.present])
        #expect(session.controller.room?.roomID == "!room:example.com")
    }
    
    @Test
    func aCallStartsARoomWithoutOneAndJoinsARoomWithOne() {
        session.handleCallRequest(roomProxy: roomProxy(id: "!empty:example.com", hasOngoingCall: false), isVoiceCall: true)
        // Starting rings the room; joining one already running happens quietly.
        #expect(session.controller.callData?.isStartingCall == true)
        #expect(session.controller.callData?.isAudioCall == true)
        
        session.stop()
        
        let joining = NativeCallSession(transport: ElementCallFakeTransport(),
                                        system: ElementCallFakeSystem(),
                                        options: ElementCallOptions(),
                                        style: .stock,
                                        logger: nil)
        joining.handleCallRequest(roomProxy: roomProxy(id: "!busy:example.com", hasOngoingCall: true), isVoiceCall: true)
        #expect(joining.controller.callData?.isStartingCall == false)
    }
    
    @Test
    func askingForTheCallYouAreAlreadyInRestoresItsScreen() {
        let roomProxy = roomProxy(id: "!room:example.com")
        session.handleCallRequest(roomProxy: roomProxy, isVoiceCall: false)
        presentations.removeAll()
        
        // Reached while the call is still joining, before the service has an ongoing call of its own.
        session.handleCallRequest(roomProxy: roomProxy, isVoiceCall: false)
        
        #expect(presentations == [.restore])
    }
    
    @Test
    func aCallInAnotherRoomWaitsForTheRunningOneToEnd() async throws {
        session.handleCallRequest(roomProxy: roomProxy(id: "!first:example.com"), isVoiceCall: false)
        presentations.removeAll()
        
        // The controller ignores a second call, so this one is queued behind a hang up.
        session.handleCallRequest(roomProxy: roomProxy(id: "!second:example.com"), isVoiceCall: false)
        #expect(session.controller.room?.roomID == "!first:example.com")
        
        try await waitForPresentations([.dismiss, .present])
        #expect(session.controller.room?.roomID == "!second:example.com")
    }
    
    @Test
    func endingACallDismissesItsScreen() async throws {
        session.handleCallRequest(roomProxy: roomProxy(id: "!room:example.com"), isVoiceCall: false)
        presentations.removeAll()
        
        session.controller.hangUp()
        
        try await waitForPresentations([.dismiss])
        #expect(session.controller.room == nil, "The controller is reset so the next call starts clean")
    }
    
    // MARK: - Helpers
    
    private func roomProxy(id: String, hasOngoingCall: Bool = false) -> JoinedRoomProxyMock {
        JoinedRoomProxyMock(.init(id: id, hasOngoingCall: hasOngoingCall))
    }
    
    private func waitForPresentations(_ expected: [NativeCallPresentation]) async throws {
        let deferred = deferFulfillment(session.actions) { [weak self] _ in
            self?.presentations == expected
        }
        
        if presentations == expected {
            return
        }
        
        try await deferred.fulfill()
    }
}
