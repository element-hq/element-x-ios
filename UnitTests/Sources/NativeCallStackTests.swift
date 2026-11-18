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
final class NativeCallStackTests {
    private let service = ElementCallServiceMock(.init())
    private let system: NativeCallSystem
    private let stack: NativeCallStack
    private var presentations: [NativeCallPresentation] = []
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        system = NativeCallSystem(service: service)
        stack = NativeCallStack(backend: ElementCallFakeMatrixBackend(),
                                system: system,
                                options: ElementCallOptions(),
                                style: .stock,
                                permissions: ElementCallFakeMediaPermissions())
        
        stack.actions
            .sink { [weak self] presentation in
                self?.presentations.append(presentation)
            }
            .store(in: &cancellables)
    }
    
    @Test("Starting a call asks for its screen")
    func startCall() {
        stack.handleCallRequest(roomProxy: roomProxy(id: "!room:example.com"), isVoiceCall: false, answeredFromCallKit: false)
        
        #expect(presentations == [.present])
        #expect(stack.controller.room?.roomID == "!room:example.com")
    }
    
    @Test("A call starts a room without one and joins a room with one")
    func startOrJoinCall() {
        stack.handleCallRequest(roomProxy: roomProxy(id: "!empty:example.com", hasOngoingCall: false), isVoiceCall: true, answeredFromCallKit: false)
        // Starting rings the room; joining one already running happens quietly.
        #expect(stack.controller.callData?.isStartingCall == true)
        #expect(stack.controller.callData?.isAudioCall == true)
        
        stack.endCall()
        
        let joining = NativeCallStack(backend: ElementCallFakeMatrixBackend(),
                                      system: NativeCallSystem(service: service),
                                      options: ElementCallOptions(),
                                      style: .stock,
                                      permissions: ElementCallFakeMediaPermissions())
        joining.handleCallRequest(roomProxy: roomProxy(id: "!busy:example.com", hasOngoingCall: true), isVoiceCall: true, answeredFromCallKit: false)
        #expect(joining.controller.callData?.isStartingCall == false)
    }
    
    @Test("Asking for the call you are already in restores its screen")
    func restoreRunningCall() {
        let roomProxy = roomProxy(id: "!room:example.com")
        stack.handleCallRequest(roomProxy: roomProxy, isVoiceCall: false, answeredFromCallKit: false)
        presentations.removeAll()
        
        // Reached while the call is still joining, before the service has an ongoing call of its own.
        stack.handleCallRequest(roomProxy: roomProxy, isVoiceCall: false, answeredFromCallKit: false)
        
        #expect(presentations == [.restore])
    }
    
    @Test("A call in another room waits for the running one to end")
    func queueCallInAnotherRoom() async throws {
        stack.handleCallRequest(roomProxy: roomProxy(id: "!first:example.com"), isVoiceCall: false, answeredFromCallKit: false)
        presentations.removeAll()
        
        // The controller ignores a second call, so this one is queued behind a hang up.
        stack.handleCallRequest(roomProxy: roomProxy(id: "!second:example.com"), isVoiceCall: false, answeredFromCallKit: false)
        #expect(stack.controller.room?.roomID == "!first:example.com")
        
        try await waitForPresentations([.dismiss, .present])
        #expect(stack.controller.room?.roomID == "!second:example.com")
    }
    
    @Test("An answered call queued behind a running one still starts as an answer")
    func queueAnsweredCall() async throws {
        stack.handleCallRequest(roomProxy: roomProxy(id: "!first:example.com"), isVoiceCall: false, answeredFromCallKit: false)
        presentations.removeAll()
        
        stack.handleCallRequest(roomProxy: roomProxy(id: "!second:example.com"), isVoiceCall: false, answeredFromCallKit: true)
        try await waitForPresentations([.dismiss, .present])
        
        #expect(system.answeredFromCallKit)
    }
    
    @Test("A call that ends dismisses its screen")
    func hangUp() async throws {
        stack.handleCallRequest(roomProxy: roomProxy(id: "!room:example.com"), isVoiceCall: false, answeredFromCallKit: false)
        presentations.removeAll()
        
        stack.controller.hangUp()
        
        try await waitForPresentations([.dismiss])
        #expect(stack.controller.room == nil, "The controller is reset so the next call starts clean")
    }
    
    @Test("Ending the call drops the one queued behind it")
    func endCallWithQueuedCall() async throws {
        stack.handleCallRequest(roomProxy: roomProxy(id: "!first:example.com"), isVoiceCall: false, answeredFromCallKit: false)
        stack.handleCallRequest(roomProxy: roomProxy(id: "!second:example.com"), isVoiceCall: false, answeredFromCallKit: false)
        presentations.removeAll()
        
        let dismissed = deferFulfillment(stack.actions) { $0 == .dismiss }
        stack.endCall()
        try await dismissed.fulfill()
        
        let nothingElse = deferFailure(stack.actions, timeout: .milliseconds(100)) { _ in true }
        try await nothingElse.fulfill()
        #expect(presentations == [.dismiss])
    }
    
    // MARK: - Helpers
    
    private func roomProxy(id: String, hasOngoingCall: Bool = false) -> JoinedRoomProxyMock {
        JoinedRoomProxyMock(.init(id: id, hasOngoingCall: hasOngoingCall))
    }
    
    private func waitForPresentations(_ expected: [NativeCallPresentation]) async throws {
        let deferred = deferFulfillment(stack.actions) { [weak self] _ in
            self?.presentations == expected
        }
        
        if presentations == expected {
            return
        }
        
        try await deferred.fulfill()
    }
}
