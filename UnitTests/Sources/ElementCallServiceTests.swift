//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import ElementCall
@testable import ElementX
import MatrixRustSDK
import MatrixRustSDKMocks
import Testing

final class ElementCallServiceTests {
    private let appSettings = AppSettings.volatile()
    private let clientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org"))
    private let roomProxy = JoinedRoomProxyMock(.init(id: "!room:example.com", hasOngoingCall: true, ownUserID: "@alice:matrix.org"))
    private let roomInfoSubject = CurrentValueSubject<RoomInfoProxyProtocol, Never>(RoomInfoProxyMock(.init(id: "!room:example.com", hasOngoingCall: true)))
    private let service: ElementCallService
    
    init() {
        roomProxy.infoPublisher = roomInfoSubject.asCurrentValuePublisher()
        roomProxy.subscribeToCallDeclineEventsRtcNotificationEventIDListenerReturnValue = .success(TaskHandleSDKMock())
        roomProxy.declineCallNotificationIDReturnValue = .success(())
        clientProxy.roomForIdentifierClosure = { [roomProxy] _ in .joined(roomProxy) }
        
        service = ElementCallService(clientProxy: clientProxy,
                                     mediaProvider: MediaProviderMock(.init()),
                                     userSettings: appSettings.userSettings(for: clientProxy.userID),
                                     nativeCallPermissions: ElementCallFakeMediaPermissions())
    }
    
    // MARK: - Ringing call
    
    @Test("The caller hanging up ends the ringing")
    func remoteHangUp() async throws {
        await service.observeIncomingCall(roomID: "!room:example.com", rtcNotificationID: "$000")
        
        let deferred = deferFulfillment(service.actionsPublisher) { $0 == .incomingCallEnded(roomID: "!room:example.com", reason: .remoteEnded) }
        roomInfoSubject.send(RoomInfoProxyMock(.init(id: "!room:example.com", hasOngoingCall: false)))
        try await deferred.fulfill()
    }
    
    @Test("Joining the call on another device ends the ringing")
    func joinElsewhere() async throws {
        await service.observeIncomingCall(roomID: "!room:example.com", rtcNotificationID: "$000")
        
        let deferred = deferFulfillment(service.actionsPublisher) { $0 == .incomingCallEnded(roomID: "!room:example.com", reason: .answeredElsewhere) }
        roomInfoSubject.send(RoomInfoProxyMock(.init(id: "!room:example.com", hasOngoingCall: true, activeRoomCallParticipants: ["@alice:matrix.org"])))
        try await deferred.fulfill()
    }
    
    @Test("Our own decline on another device ends the ringing, another member's doesn't")
    func declineElsewhere() async throws {
        await service.observeIncomingCall(roomID: "!room:example.com", rtcNotificationID: "$000")
        let listener = try #require(roomProxy.subscribeToCallDeclineEventsRtcNotificationEventIDListenerReceivedArguments?.listener)
        #expect(roomProxy.subscribeToCallDeclineEventsRtcNotificationEventIDListenerReceivedArguments?.rtcNotificationEventID == "$000")
        
        let deferredFailure = deferFailure(service.actionsPublisher, timeout: .milliseconds(100)) { _ in true }
        listener.call(declinerUserId: "@bob:matrix.org")
        try await deferredFailure.fulfill()
        
        let deferred = deferFulfillment(service.actionsPublisher) { $0 == .incomingCallEnded(roomID: "!room:example.com", reason: .declinedElsewhere) }
        listener.call(declinerUserId: "@alice:matrix.org")
        try await deferred.fulfill()
    }
    
    @Test("A stopped watch ignores the room's updates")
    func stopWatching() async throws {
        await service.observeIncomingCall(roomID: "!room:example.com", rtcNotificationID: "$000")
        service.stopObservingIncomingCall()
        
        let deferredFailure = deferFailure(service.actionsPublisher, timeout: .milliseconds(100)) { _ in true }
        roomInfoSubject.send(RoomInfoProxyMock(.init(id: "!room:example.com", hasOngoingCall: false)))
        try await deferredFailure.fulfill()
    }
    
    @Test("Declining a call sends the decline to its room")
    func declineCall() async {
        await service.declineCall(roomID: "!room:example.com", rtcNotificationID: "$000")
        
        #expect(clientProxy.roomForIdentifierReceivedIdentifier == "!room:example.com")
        #expect(roomProxy.declineCallNotificationIDReceivedNotificationID == "$000")
    }
    
    // MARK: - Call sessions
    
    @Test("A call session's set-up returns once the manager has replied", arguments: [false, true])
    func callSetup(repliesLater: Bool) async {
        var order: [String] = []
        let cancellable = service.actionsPublisher.sink { [service] action in
            guard case let .callSessionStarted(roomID, _, _, _) = action else { return }
            order.append("sent")
            
            if repliesLater {
                Task {
                    order.append("set up")
                    service.callSessionSetUp(roomID: roomID, isAccepted: true)
                }
            } else {
                order.append("set up")
                service.callSessionSetUp(roomID: roomID, isAccepted: true)
            }
        }
        defer { cancellable.cancel() }
        
        await service.setupCallSession(roomID: "!room:example.com", roomDisplayName: "welcome", isVideo: true, kind: .native(takesOverAnsweredCall: false))
        order.append("returned")
        
        #expect(order == ["sent", "set up", "returned"])
    }
    
    @Test("A second set-up for a room releases the first")
    func secondCallSetup() async throws {
        var returned: [String] = []
        
        let firstStarted = deferFulfillment(service.actionsPublisher) { $0 == .callSessionStarted(roomID: "!room:example.com", roomDisplayName: "first", isVideo: true, kind: .native(takesOverAnsweredCall: false)) }
        let first = Task {
            await service.setupCallSession(roomID: "!room:example.com", roomDisplayName: "first", isVideo: true, kind: .native(takesOverAnsweredCall: false))
            returned.append("first")
        }
        try await firstStarted.fulfill()
        
        let secondStarted = deferFulfillment(service.actionsPublisher) { $0 == .callSessionStarted(roomID: "!room:example.com", roomDisplayName: "second", isVideo: true, kind: .native(takesOverAnsweredCall: false)) }
        let second = Task {
            await service.setupCallSession(roomID: "!room:example.com", roomDisplayName: "second", isVideo: true, kind: .native(takesOverAnsweredCall: false))
            returned.append("second")
        }
        try await secondStarted.fulfill()
        
        await first.value
        #expect(returned == ["first"])
        
        service.callSessionSetUp(roomID: "!room:example.com", isAccepted: true)
        await second.value
        #expect(returned == ["first", "second"])
    }
    
    @Test("What a call screen reports reaches the manager")
    func callScreenReports() {
        var actions: [ElementCallServiceAction] = []
        let cancellable = service.actionsPublisher.sink { actions.append($0) }
        defer { cancellable.cancel() }
        
        service.reportCallSessionConnected(roomID: "!room:example.com")
        service.tearDownCallSession(roomID: "!room:example.com")
        service.reportCallSessionEnded(roomID: "!room:example.com", reason: .remoteEnded)
        service.setAudioEnabled(false, roomID: "!room:example.com")
        
        #expect(actions == [.callSessionConnected(roomID: "!room:example.com"),
                            .callSessionEnded(roomID: "!room:example.com", reason: nil),
                            .callSessionEnded(roomID: "!room:example.com", reason: .remoteEnded),
                            .audioEnabledChanged(false, roomID: "!room:example.com")])
    }
    
    @Test("The ongoing call's room is published")
    func ongoingCall() {
        service.ongoingCallChanged(roomID: "!room:example.com")
        #expect(service.ongoingCallRoomIDPublisher.value == "!room:example.com")
        
        service.ongoingCallChanged(roomID: nil)
        #expect(service.ongoingCallRoomIDPublisher.value == nil)
    }
    
    // MARK: - Native calls
    
    @Test("System events reach the native call in order")
    func systemEvents() {
        var events: [NativeCallEvent] = []
        let cancellable = service.nativeCallEventsPublisher.sink { events.append($0) }
        defer { cancellable.cancel() }
        
        service.systemEventReceived(.audioSessionActivated)
        service.systemEventReceived(.audioSessionDeactivated)
        service.systemEventReceived(.microphoneMuteChanged(isMuted: true))
        service.systemEventReceived(.audioSessionActivated)
        service.systemEventReceived(.endCallRequested(roomID: "!room:example.com"))
        
        #expect(events == [.audioSessionActivated,
                           .audioSessionDeactivated,
                           .microphoneMuteChanged(isMuted: true),
                           .audioSessionActivated,
                           .endCallRequested(roomID: "!room:example.com")])
    }
    
    @Test("A native call stack built after CallKit activated the audio hears it is active")
    func lateSubscriberWithActiveAudio() {
        #expect(eventsHeardByLateSubscriber(after: [.audioSessionActivated]) == [.audioSessionActivated])
    }
    
    @Test("A native call stack built after the audio session ended hears nothing")
    func lateSubscriberAfterEndedAudio() {
        #expect(eventsHeardByLateSubscriber(after: [.audioSessionActivated, .audioSessionDeactivated]).isEmpty)
    }
    
    @Test("Mutes and hang-ups aren't replayed to a later native call stack")
    func lateSubscriberAfterMuteAndEnd() {
        #expect(eventsHeardByLateSubscriber(after: [.microphoneMuteChanged(isMuted: true), .endCallRequested(roomID: "!room:example.com")]).isEmpty)
    }
    
    @Test("A refused set-up asks the native call to end")
    func refusedSetup() async {
        #expect(await eventsHeardWhileSettingUp(isAccepted: false) == [.endCallRequested(roomID: "!room:example.com")])
    }
    
    @Test("An accepted set-up leaves the native call running")
    func acceptedSetup() async {
        #expect(await eventsHeardWhileSettingUp(isAccepted: true).isEmpty)
    }
    
    @Test("The native call stack follows the native calls setting")
    func nativeCallsSetting() {
        appSettings.nativeCallEnabled = true
        let service = makeNativeCallService()
        #expect(service.nativeCallController != nil, "Built with the service, nothing has to enable it")
        
        var presentations: [NativeCallPresentation] = []
        let cancellable = service.actionsPublisher.sink { action in
            if case .nativeCallPresentation(let presentation) = action {
                presentations.append(presentation)
            }
        }
        defer { cancellable.cancel() }
        
        appSettings.nativeCallEnabled = false
        #expect(service.nativeCallController == nil)
        #expect(presentations == [.dismiss])
        
        // The backend is built on demand, so the setting takes effect without an app restart.
        appSettings.nativeCallEnabled = true
        #expect(service.nativeCallController != nil)
    }
    
    @Test("With native calls off a call falls back to the web view")
    func nativeCallsOff() {
        let service = makeNativeCallService()
        let roomProxy = JoinedRoomProxyMock(.init(id: "!room:example.com"))
        
        #expect(!service.handleNativeCallRequest(roomProxy: roomProxy, isVoiceCall: false, answeredFromCallKit: false))
        
        appSettings.nativeCallEnabled = true
        
        #expect(service.handleNativeCallRequest(roomProxy: roomProxy, isVoiceCall: false, answeredFromCallKit: false))
    }
    
    // MARK: - Helpers
    
    /// Builds a service whose client can serve the native call stack.
    private func makeNativeCallService() -> ElementCallService {
        let clientProxy = ClientProxyMock(.init())
        clientProxy.makeNativeCallBackendReturnValue = ElementCallFakeMatrixBackend()
        return ElementCallService(clientProxy: clientProxy,
                                  mediaProvider: MediaProviderMock(.init()),
                                  userSettings: appSettings.userSettings(for: clientProxy.userID),
                                  nativeCallPermissions: ElementCallFakeMediaPermissions())
    }
    
    /// What a native call stack built after these system events hears, as the replay arrives during `sink`.
    private func eventsHeardByLateSubscriber(after events: [NativeCallEvent]) -> [NativeCallEvent] {
        events.forEach(service.systemEventReceived)
        
        var heardEvents: [NativeCallEvent] = []
        let cancellable = service.nativeCallEventsPublisher.sink { heardEvents.append($0) }
        cancellable.cancel()
        return heardEvents
    }
    
    /// What the native call hears while answering a call whose set-up the manager replies to at once.
    private func eventsHeardWhileSettingUp(isAccepted: Bool) async -> [NativeCallEvent] {
        var heardEvents: [NativeCallEvent] = []
        let eventsCancellable = service.nativeCallEventsPublisher.sink { heardEvents.append($0) }
        let actionsCancellable = service.actionsPublisher.sink { [service] action in
            guard case let .callSessionStarted(roomID, _, _, _) = action else { return }
            service.callSessionSetUp(roomID: roomID, isAccepted: isAccepted)
        }
        defer {
            eventsCancellable.cancel()
            actionsCancellable.cancel()
        }
        
        await service.setupCallSession(roomID: "!room:example.com", roomDisplayName: "Room", isVideo: true, kind: .native(takesOverAnsweredCall: true))
        return heardEvents
    }
}
