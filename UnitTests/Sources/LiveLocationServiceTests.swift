//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import CoreLocation
@testable import ElementX
import Foundation
import Testing

@MainActor
final class LiveLocationServiceTests {
    private var clientProxy: ClientProxyMock!
    private var service: LiveLocationService!
    private var userSettings: UserSettings!
    private var beaconInfoSubject: PassthroughSubject<LiveLocationOwnInfoUpdate, Never>!
    
    // MARK: - startLiveLocation
    
    @Test
    func startLiveLocationWithNoExistingLocalSession() async throws {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        
        var callOrder: [String] = []
        roomProxy.stopLiveLocationShareClosure = {
            callOrder.append("stop")
            return .success(())
        }
        roomProxy.startLiveLocationShareDurationClosure = { _ in
            callOrder.append("start")
            return .success("$event:matrix.org")
        }
        
        let result = await service.startLiveLocation(roomID: "!room:matrix.org", duration: .seconds(300))
        
        try result.get()
        #expect(callOrder == ["stop", "start"])
        #expect(userSettings.account.liveLocationSharingSessionsByRoomID["!room:matrix.org"] == nil)
        #expect(!service.isSharingPublisher.value)
        
        try await simulateBeaconEcho(roomID: "!room:matrix.org", eventID: "$event:matrix.org")
        
        #expect(userSettings.account.liveLocationSharingSessionsByRoomID["!room:matrix.org"] != nil)
        #expect(service.isSharingPublisher.value)
    }
    
    @Test
    func startLiveLocationWithExistingSessionStopsItFirst() async throws {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        userSettings.account.liveLocationSharingSessionsByRoomID["!room:matrix.org"] = LiveLocationSession(eventID: "$old_event:matrix.org", expirationDate: Date().addingTimeInterval(300))
        
        var callOrder: [String] = []
        roomProxy.stopLiveLocationShareClosure = {
            callOrder.append("stop")
            return .success(())
        }
        roomProxy.startLiveLocationShareDurationClosure = { _ in
            callOrder.append("start")
            return .success("$event:matrix.org")
        }
        
        let result = await service.startLiveLocation(roomID: "!room:matrix.org", duration: .seconds(600))
        
        try result.get()
        #expect(callOrder == ["stop", "start"])
        
        try await simulateBeaconEcho(roomID: "!room:matrix.org", eventID: "$event:matrix.org")
        
        #expect(userSettings.account.liveLocationSharingSessionsByRoomID["!room:matrix.org"] != nil)
    }
    
    @Test
    func startLiveLocationDoesNotStopSessionForOtherRoom() async {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room1:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        
        userSettings.account.liveLocationSharingSessionsByRoomID["!room2:matrix.org"] = LiveLocationSession(eventID: "$event:matrix.org", expirationDate: Date().addingTimeInterval(300))
        
        _ = await service.startLiveLocation(roomID: "!room1:matrix.org", duration: .seconds(300))
        
        #expect(roomProxy.stopLiveLocationShareCalled)
        #expect(userSettings.account.liveLocationSharingSessionsByRoomID["!room2:matrix.org"] != nil)
    }
    
    @Test
    func startLiveLocationWhenRoomNotJoined() async {
        setUp()
        clientProxy.roomForIdentifierClosure = { _ in nil }
        
        let result = await service.startLiveLocation(roomID: "!room:matrix.org", duration: .seconds(300))
        
        #expect(throws: LiveLocationServiceError.roomNotJoined) { try result.get() }
        #expect(userSettings.account.liveLocationSharingSessionsByRoomID["!room:matrix.org"] == nil)
    }
    
    @Test
    func startLiveLocationWhenStartShareFails() async {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        roomProxy.startLiveLocationShareDurationReturnValue = .failure(.sdkError(RoomProxyMockError.generic))
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        
        let result = await service.startLiveLocation(roomID: "!room:matrix.org", duration: .seconds(300))
        
        #expect(throws: LiveLocationServiceError.startFailed) { try result.get() }
        #expect(userSettings.account.liveLocationSharingSessionsByRoomID["!room:matrix.org"] == nil)
    }
    
    @Test
    func startLiveLocationStoresTimeoutDate() async throws {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        
        let duration = Duration.seconds(300)
        let beforeStart = Date()
        _ = await service.startLiveLocation(roomID: "!room:matrix.org", duration: duration)
        let afterStart = Date()
        
        try await simulateBeaconEcho(roomID: "!room:matrix.org", eventID: "$event:matrix.org")
        
        let storedSession = try #require(userSettings.account.liveLocationSharingSessionsByRoomID["!room:matrix.org"])
        let expectedMinTimeout = beforeStart.addingTimeInterval(TimeInterval(duration.seconds))
        let expectedMaxTimeout = afterStart.addingTimeInterval(TimeInterval(duration.seconds))
        
        #expect((expectedMinTimeout...expectedMaxTimeout).contains(storedSession.expirationDate))
        #expect(storedSession.eventID == "$event:matrix.org")
    }
    
    // MARK: - stopLiveLocation
    
    @Test
    func stopLiveLocationWhenSessionExists() async {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        userSettings.account.liveLocationSharingSessionsByRoomID["!room:matrix.org"] = LiveLocationSession(eventID: "$event:matrix.org", expirationDate: Date().addingTimeInterval(300))
        
        await service.stopLiveLocation(roomID: "!room:matrix.org")
        
        #expect(roomProxy.stopLiveLocationShareCalled)
        #expect(userSettings.account.liveLocationSharingSessionsByRoomID["!room:matrix.org"] == nil)
        #expect(!service.isSharingPublisher.value)
    }
    
    @Test
    func stopLiveLocationWhenNoSession() async {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        
        await service.stopLiveLocation(roomID: "!room:matrix.org")
        
        #expect(roomProxy.stopLiveLocationShareCalled)
    }
    
    @Test
    func stopLiveLocationDoesNotRemoveOtherSessions() async {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room1:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        userSettings.account.liveLocationSharingSessionsByRoomID["!room1:matrix.org"] = LiveLocationSession(eventID: "$event:matrix.org", expirationDate: Date().addingTimeInterval(300))
        userSettings.account.liveLocationSharingSessionsByRoomID["!room2:matrix.org"] = LiveLocationSession(eventID: "$event:matrix.org", expirationDate: Date().addingTimeInterval(300))
        
        await service.stopLiveLocation(roomID: "!room1:matrix.org")
        
        #expect(userSettings.account.liveLocationSharingSessionsByRoomID["!room1:matrix.org"] == nil)
        #expect(userSettings.account.liveLocationSharingSessionsByRoomID["!room2:matrix.org"] != nil)
    }
    
    // MARK: - Beacon info updates
    
    @Test
    func beaconInfoUpdateFromAnotherDeviceRemovesActiveSession() async throws {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        
        try await service.startLiveLocation(roomID: "!room:matrix.org", duration: .seconds(300)).get()
        try await simulateBeaconEcho(roomID: "!room:matrix.org", eventID: "$event:matrix.org")
        #expect(userSettings.account.liveLocationSharingSessionsByRoomID["!room:matrix.org"] != nil)
        
        let deferred = deferFulfillment(userSettings.account.liveLocationSharingSessionsByRoomIDPublisher) { $0["!room:matrix.org"] == nil }
        beaconInfoSubject.send(LiveLocationOwnInfoUpdate(roomID: "!room:matrix.org", eventID: "$external_event:matrix.org", isLive: true))
        try await deferred.fulfill()
        
        #expect(userSettings.account.liveLocationSharingSessionsByRoomID["!room:matrix.org"] == nil)
    }
    
    // MARK: - Sharing
    
    @Test
    func sharesStoredBeforeLaunchAreShared() {
        let userSettings = UserSettings.mock()
        userSettings.account.liveLocationSharingSessionsByRoomID["!room:matrix.org"] = LiveLocationSession(eventID: "$event:matrix.org", expirationDate: .distantFuture)
        
        setUp(userSettings: userSettings)
        
        #expect(service.isSharingPublisher.value)
    }
    
    @Test
    func locationUpdatesAreSentToTheSharedRooms() async {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        userSettings.account.liveLocationSharingSessionsByRoomID["!room:matrix.org"] = LiveLocationSession(eventID: "$event:matrix.org", expirationDate: .distantFuture)
        
        await waitForConfirmation("Wait for the location to be sent") { confirm in
            roomProxy.sendLiveLocationGeoURIClosure = { geoURI in
                #expect(geoURI.latitude == 51.5)
                #expect(geoURI.longitude == -0.1)
                confirm()
                return .success(())
            }
            service.locationUpdated(CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1))
        }
    }
    
    @Test
    func stopAllLiveLocationsStopsEveryShare() async {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room1:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        userSettings.account.liveLocationSharingSessionsByRoomID["!room1:matrix.org"] = LiveLocationSession(eventID: "$event1:matrix.org", expirationDate: .distantFuture)
        userSettings.account.liveLocationSharingSessionsByRoomID["!room2:matrix.org"] = LiveLocationSession(eventID: "$event2:matrix.org", expirationDate: .distantFuture)
        
        await service.stopAllLiveLocations()
        
        #expect(roomProxy.stopLiveLocationShareCallsCount == 2)
        #expect(userSettings.account.liveLocationSharingSessionsByRoomID.isEmpty)
        #expect(!service.isSharingPublisher.value)
    }
    
    // MARK: - Authorization
    
    @Test
    func authorizationStatusFollowsTheManager() {
        setUp()
        
        service.authorizationStatusChanged(to: .authorizedAlways)
        
        #expect(service.authorizationStatus.value == .authorizedAlways)
    }
    
    @Test
    func requestingAlwaysAuthorizationAsksTheManagerUntilItRemembersTheRequest() {
        setUp()
        var requestCount = 0
        let cancellable = service.actionsPublisher.sink { action in
            switch action {
            case .requestAlwaysAuthorization:
                requestCount += 1
            }
        }
        
        #expect(service.requestAlwaysAuthorizationIfPossible())
        #expect(requestCount == 1)
        // Remembering the request is the manager's job.
        #expect(!userSettings.app.hasRequestedLocationAlwaysLocationAuthorization)
        
        userSettings.app.hasRequestedLocationAlwaysLocationAuthorization = true
        #expect(!service.requestAlwaysAuthorizationIfPossible())
        #expect(requestCount == 1)
        cancellable.cancel()
    }
    
    // MARK: - Private
    
    private func makeRoomProxy(roomID: String) -> JoinedRoomProxyMock {
        let roomProxy = JoinedRoomProxyMock(.init(id: roomID))
        roomProxy.startLiveLocationShareDurationReturnValue = .success("$event:matrix.org")
        roomProxy.stopLiveLocationShareReturnValue = .success(())
        return roomProxy
    }
    
    private func setUp(userSettings: UserSettings = .mock()) {
        self.userSettings = userSettings
        clientProxy = ClientProxyMock(.init())
        beaconInfoSubject = PassthroughSubject<LiveLocationOwnInfoUpdate, Never>()
        clientProxy.liveLocationOwnInfoUpdatesPublisher = beaconInfoSubject.eraseToAnyPublisher()
        service = LiveLocationService(clientProxy: clientProxy, userSettings: userSettings)
    }
    
    private func simulateBeaconEcho(roomID: String, eventID: String) async throws {
        let deferred = deferFulfillment(userSettings.account.liveLocationSharingSessionsByRoomIDPublisher) { $0[roomID] != nil }
        beaconInfoSubject.send(LiveLocationOwnInfoUpdate(roomID: roomID, eventID: eventID, isLive: true))
        try await deferred.fulfill()
    }
}
