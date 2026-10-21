//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CallKit
import Combine
@testable import ElementX
import MatrixRustSDK
import MatrixRustSDKMocks
import Testing

@MainActor
final class ElementCallServiceTests {
    private let clientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org"))
    private let roomProxy = JoinedRoomProxyMock(.init(id: "!room:example.com", hasOngoingCall: true, ownUserID: "@alice:matrix.org"))
    private let roomInfoSubject = CurrentValueSubject<RoomInfoProxyProtocol, Never>(RoomInfoProxyMock(.init(id: "!room:example.com", hasOngoingCall: true)))
    private let service: ElementCallService
    
    init() {
        roomProxy.infoPublisher = roomInfoSubject.asCurrentValuePublisher()
        roomProxy.subscribeToCallDeclineEventsRtcNotificationEventIDListenerReturnValue = .success(TaskHandleSDKMock())
        roomProxy.declineCallNotificationIDReturnValue = .success(())
        clientProxy.roomForIdentifierClosure = { [roomProxy] _ in .joined(roomProxy) }
        service = ElementCallService(clientProxy: clientProxy)
    }
    
    @Test
    func aRemoteHangUpEndsTheRingingCall() async throws {
        await service.observeIncomingCall(roomID: "!room:example.com", rtcNotificationID: "$000")
        
        let deferred = deferFulfillment(service.actionsPublisher) { $0 == .incomingCallEnded(roomID: "!room:example.com", reason: .remoteEnded) }
        roomInfoSubject.send(RoomInfoProxyMock(.init(id: "!room:example.com", hasOngoingCall: false)))
        try await deferred.fulfill()
    }
    
    @Test
    func joiningFromAnotherDeviceEndsTheRingingCall() async throws {
        await service.observeIncomingCall(roomID: "!room:example.com", rtcNotificationID: "$000")
        
        let deferred = deferFulfillment(service.actionsPublisher) { $0 == .incomingCallEnded(roomID: "!room:example.com", reason: .answeredElsewhere) }
        roomInfoSubject.send(RoomInfoProxyMock(.init(id: "!room:example.com", hasOngoingCall: true, activeRoomCallParticipants: ["@alice:matrix.org"])))
        try await deferred.fulfill()
    }
    
    @Test
    func decliningOnAnotherDeviceEndsTheRingingCall() async throws {
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
    func stoppingIgnoresTheRoomFromThenOn() async throws {
        await service.observeIncomingCall(roomID: "!room:example.com", rtcNotificationID: "$000")
        service.stopObservingIncomingCall()
        
        let deferredFailure = deferFailure(service.actionsPublisher, timeout: .milliseconds(100)) { _ in true }
        roomInfoSubject.send(RoomInfoProxyMock(.init(id: "!room:example.com", hasOngoingCall: false)))
        try await deferredFailure.fulfill()
    }
    
    @Test
    func decliningSendsTheDeclineFromThisAccount() async {
        await service.declineCall(roomID: "!room:example.com", rtcNotificationID: "$000")
        
        #expect(clientProxy.roomForIdentifierReceivedIdentifier == "!room:example.com")
        #expect(roomProxy.declineCallNotificationIDReceivedNotificationID == "$000")
    }
}
