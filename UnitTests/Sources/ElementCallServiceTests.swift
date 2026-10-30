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
        
        service = ElementCallService(clientProxy: clientProxy, mediaProvider: MediaProviderMock(.init()), appSettings: appSettings)
    }
    
    // MARK: - Ringing call
    
    @Test
    func remoteHangUpEndsRinging() async throws {
        await service.observeIncomingCall(roomID: "!room:example.com", rtcNotificationID: "$000")
        
        let deferred = deferFulfillment(service.actionsPublisher) { $0 == .incomingCallEnded(roomID: "!room:example.com", reason: .remoteEnded) }
        roomInfoSubject.send(RoomInfoProxyMock(.init(id: "!room:example.com", hasOngoingCall: false)))
        try await deferred.fulfill()
    }
    
    @Test
    func joinElsewhereEndsRinging() async throws {
        await service.observeIncomingCall(roomID: "!room:example.com", rtcNotificationID: "$000")
        
        let deferred = deferFulfillment(service.actionsPublisher) { $0 == .incomingCallEnded(roomID: "!room:example.com", reason: .answeredElsewhere) }
        roomInfoSubject.send(RoomInfoProxyMock(.init(id: "!room:example.com", hasOngoingCall: true, activeRoomCallParticipants: ["@alice:matrix.org"])))
        try await deferred.fulfill()
    }
    
    @Test
    func declineElsewhereEndsRinging() async throws {
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
    
    @Test
    func stoppedWatchIgnoresRoom() async throws {
        await service.observeIncomingCall(roomID: "!room:example.com", rtcNotificationID: "$000")
        service.stopObservingIncomingCall()
        
        let deferredFailure = deferFailure(service.actionsPublisher, timeout: .milliseconds(100)) { _ in true }
        roomInfoSubject.send(RoomInfoProxyMock(.init(id: "!room:example.com", hasOngoingCall: false)))
        try await deferredFailure.fulfill()
    }
    
    @Test
    func declineCallSendsDecline() async {
        await service.declineCall(roomID: "!room:example.com", rtcNotificationID: "$000")
        
        #expect(clientProxy.roomForIdentifierReceivedIdentifier == "!room:example.com")
        #expect(roomProxy.declineCallNotificationIDReceivedNotificationID == "$000")
    }
    
    // MARK: - Call sessions
    
    @Test(arguments: [false, true])
    func callSetupWaitsForManager(repliesLater: Bool) async {
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
        
        await service.setupCallSession(roomID: "!room:example.com", roomDisplayName: "welcome", isVideo: true, kind: .native)
        order.append("returned")
        
        #expect(order == ["sent", "set up", "returned"])
    }
    
    @Test
    func secondSetupReleasesFirst() async throws {
        var returned: [String] = []
        
        let firstStarted = deferFulfillment(service.actionsPublisher) { $0 == .callSessionStarted(roomID: "!room:example.com", roomDisplayName: "first", isVideo: true, kind: .native) }
        let first = Task {
            await service.setupCallSession(roomID: "!room:example.com", roomDisplayName: "first", isVideo: true, kind: .native)
            returned.append("first")
        }
        try await firstStarted.fulfill()
        
        let secondStarted = deferFulfillment(service.actionsPublisher) { $0 == .callSessionStarted(roomID: "!room:example.com", roomDisplayName: "second", isVideo: true, kind: .native) }
        let second = Task {
            await service.setupCallSession(roomID: "!room:example.com", roomDisplayName: "second", isVideo: true, kind: .native)
            returned.append("second")
        }
        try await secondStarted.fulfill()
        
        await first.value
        #expect(returned == ["first"])
        
        service.callSessionSetUp(roomID: "!room:example.com", isAccepted: true)
        await second.value
        #expect(returned == ["first", "second"])
    }
    
    @Test
    func callScreenReportsReachManager() {
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
    
    @Test
    func ongoingCallIsPublished() {
        service.ongoingCallChanged(roomID: "!room:example.com")
        #expect(service.ongoingCallRoomIDPublisher.value == "!room:example.com")
        
        service.ongoingCallChanged(roomID: nil)
        #expect(service.ongoingCallRoomIDPublisher.value == nil)
    }
    
    // MARK: - Native calls
    
    @Test
    func systemEventsReachNativeCall() async throws {
        let deferred = deferFulfillment(service.nativeCallEventsPublisher) { $0 == .endCallRequested(roomID: "!room:example.com") }
        service.systemEventReceived(.endCallRequested(roomID: "!room:example.com"))
        try await deferred.fulfill()
    }
    
    @Test
    func nativeCallStackNeedsSettingAndEnabling() {
        let service = makeNativeCallService()
        var presentations: [NativeCallPresentation] = []
        let cancellable = service.nativeCallPresentationPublisher.sink { presentations.append($0) }
        defer { cancellable.cancel() }
        
        service.setNativeCallStackEnabled(true)
        #expect(service.nativeCallController == nil, "Enabling alone doesn't build a stack")
        
        service.setNativeCallStackEnabled(false)
        appSettings.nativeCallEnabled = true
        #expect(service.nativeCallController == nil, "The setting alone doesn't build a stack")
        
        service.setNativeCallStackEnabled(true)
        #expect(service.nativeCallController != nil)
        
        service.setNativeCallStackEnabled(false)
        #expect(service.nativeCallController == nil, "Disabling has to release the stack's to-device subscription")
        #expect(presentations == [.dismiss])
    }
    
    @Test
    func settingTurnedOnBuildsEnabledStack() {
        let service = makeNativeCallService()
        service.setNativeCallStackEnabled(true)
        #expect(service.nativeCallController == nil)
        
        // The backend is built on demand, so the setting takes effect without an app restart.
        appSettings.nativeCallEnabled = true
        #expect(service.nativeCallController != nil)
    }
    
    @Test
    func callsFallBackToWebViewWithoutStack() {
        let service = makeNativeCallService()
        let roomProxy = JoinedRoomProxyMock(.init(id: "!room:example.com"))
        
        #expect(!service.handleNativeCallRequest(roomProxy: roomProxy, isVoiceCall: false))
        
        appSettings.nativeCallEnabled = true
        service.setNativeCallStackEnabled(true)
        
        #expect(service.handleNativeCallRequest(roomProxy: roomProxy, isVoiceCall: false))
    }
    
    // MARK: - Helpers
    
    /// Builds a service whose client can serve the native call stack.
    private func makeNativeCallService() -> ElementCallService {
        let clientProxy = ClientProxyMock(.init())
        clientProxy.makeNativeCallBackendReturnValue = ElementCallFakeMatrixBackend()
        return ElementCallService(clientProxy: clientProxy, mediaProvider: MediaProviderMock(.init()), appSettings: appSettings)
    }
}
