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
final class LiveLocationManagerTests {
    private var clientProxy: ClientProxyMock!
    private var locationManagerMock: CLLocationManagerMock!
    private var manager: LiveLocationManager!
    private var appSettings: AppSettings!
    private var beaconInfoSubject: PassthroughSubject<LiveLocationOwnInfoUpdate, Never>!
    
    init() {
        AppSettings.resetAllSettings()
    }
    
    deinit {
        AppSettings.resetAllSettings()
    }
    
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
        
        let result = await manager.startLiveLocation(roomID: "!room:matrix.org", duration: .seconds(300))
        
        try result.get()
        #expect(callOrder == ["stop", "start"])
        #expect(appSettings.liveLocationSharingSessionsByRoomID["!room:matrix.org"] == nil)
        
        try await simulateBeaconEcho(roomID: "!room:matrix.org", eventID: "$event:matrix.org")
        
        #expect(appSettings.liveLocationSharingSessionsByRoomID["!room:matrix.org"] != nil)
        #expect(locationManagerMock.startUpdatingLocationCalled)
    }
    
    @Test
    func startLiveLocationWithExistingSessionStopsItFirst() async throws {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        appSettings.liveLocationSharingSessionsByRoomID["!room:matrix.org"] = LiveLocationSession(eventID: "$old_event:matrix.org", expirationDate: Date().addingTimeInterval(300))
        
        var callOrder: [String] = []
        roomProxy.stopLiveLocationShareClosure = {
            callOrder.append("stop")
            return .success(())
        }
        roomProxy.startLiveLocationShareDurationClosure = { _ in
            callOrder.append("start")
            return .success("$event:matrix.org")
        }
        
        let result = await manager.startLiveLocation(roomID: "!room:matrix.org", duration: .seconds(600))
        
        try result.get()
        #expect(callOrder == ["stop", "start"])
        
        try await simulateBeaconEcho(roomID: "!room:matrix.org", eventID: "$event:matrix.org")
        
        #expect(appSettings.liveLocationSharingSessionsByRoomID["!room:matrix.org"] != nil)
    }
    
    @Test
    func startLiveLocationDoesNotStopSessionForOtherRoom() async {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room1:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        
        appSettings.liveLocationSharingSessionsByRoomID["!room2:matrix.org"] = LiveLocationSession(eventID: "$event:matrix.org", expirationDate: Date().addingTimeInterval(300))
        
        _ = await manager.startLiveLocation(roomID: "!room1:matrix.org", duration: .seconds(300))
        
        #expect(roomProxy.stopLiveLocationShareCalled)
        #expect(appSettings.liveLocationSharingSessionsByRoomID["!room2:matrix.org"] != nil)
    }
    
    @Test
    func startLiveLocationWhenRoomNotJoined() async {
        setUp()
        clientProxy.roomForIdentifierClosure = { _ in nil }
        
        let result = await manager.startLiveLocation(roomID: "!room:matrix.org", duration: .seconds(300))
        
        #expect(throws: LiveLocationManagerError.roomNotJoined) { try result.get() }
        #expect(appSettings.liveLocationSharingSessionsByRoomID["!room:matrix.org"] == nil)
    }
    
    @Test
    func startLiveLocationWhenStartShareFails() async {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        roomProxy.startLiveLocationShareDurationReturnValue = .failure(.sdkError(RoomProxyMockError.generic))
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        
        let result = await manager.startLiveLocation(roomID: "!room:matrix.org", duration: .seconds(300))
        
        #expect(throws: LiveLocationManagerError.startFailed) { try result.get() }
        #expect(appSettings.liveLocationSharingSessionsByRoomID["!room:matrix.org"] == nil)
    }
    
    @Test
    func startLiveLocationStoresTimeoutDate() async throws {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        
        let duration = Duration.seconds(300)
        let beforeStart = Date()
        _ = await manager.startLiveLocation(roomID: "!room:matrix.org", duration: duration)
        let afterStart = Date()
        
        try await simulateBeaconEcho(roomID: "!room:matrix.org", eventID: "$event:matrix.org")
        
        let storedSession = try #require(appSettings.liveLocationSharingSessionsByRoomID["!room:matrix.org"])
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
        appSettings.liveLocationSharingSessionsByRoomID["!room:matrix.org"] = LiveLocationSession(eventID: "$event:matrix.org", expirationDate: Date().addingTimeInterval(300))
        
        await manager.stopLiveLocation(roomID: "!room:matrix.org")
        
        #expect(roomProxy.stopLiveLocationShareCalled)
        #expect(appSettings.liveLocationSharingSessionsByRoomID["!room:matrix.org"] == nil)
        // Setting the timeout date above starts tracking; removing it stops tracking.
        #expect(locationManagerMock.startUpdatingLocationCalled)
        #expect(locationManagerMock.stopUpdatingLocationCalled)
    }
    
    @Test
    func stopLiveLocationWhenNoSession() async {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        
        await manager.stopLiveLocation(roomID: "!room:matrix.org")
        
        #expect(roomProxy.stopLiveLocationShareCalled)
    }
    
    @Test
    func stopLiveLocationDoesNotRemoveOtherSessions() async {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room1:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        appSettings.liveLocationSharingSessionsByRoomID["!room1:matrix.org"] = LiveLocationSession(eventID: "$event:matrix.org", expirationDate: Date().addingTimeInterval(300))
        appSettings.liveLocationSharingSessionsByRoomID["!room2:matrix.org"] = LiveLocationSession(eventID: "$event:matrix.org", expirationDate: Date().addingTimeInterval(300))
        
        await manager.stopLiveLocation(roomID: "!room1:matrix.org")
        
        #expect(appSettings.liveLocationSharingSessionsByRoomID["!room1:matrix.org"] == nil)
        #expect(appSettings.liveLocationSharingSessionsByRoomID["!room2:matrix.org"] != nil)
    }
    
    // MARK: - Beacon info updates

    @Test
    func beaconInfoUpdateFromAnotherDeviceRemovesActiveSession() async throws {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }

        try await manager.startLiveLocation(roomID: "!room:matrix.org", duration: .seconds(300)).get()
        try await simulateBeaconEcho(roomID: "!room:matrix.org", eventID: "$event:matrix.org")
        #expect(appSettings.liveLocationSharingSessionsByRoomID["!room:matrix.org"] != nil)

        let deferred = deferFulfillment(appSettings.$liveLocationSharingSessionsByRoomID) { $0["!room:matrix.org"] == nil }
        beaconInfoSubject.send(LiveLocationOwnInfoUpdate(roomID: "!room:matrix.org", eventID: "$external_event:matrix.org", isLive: true))
        try await deferred.fulfill()

        #expect(appSettings.liveLocationSharingSessionsByRoomID["!room:matrix.org"] == nil)
    }

    // MARK: - Reduced accuracy
    
    @Test
    func startLiveLocationInReducedAccuracyMode() async throws {
        setUp(accuracyAuthorization: .reducedAccuracy)
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        
        let result = await manager.startLiveLocation(roomID: "!room:matrix.org", duration: .seconds(300))
        try result.get()
        
        try await simulateBeaconEcho(roomID: "!room:matrix.org", eventID: "$event:matrix.org")
        
        #expect(locationManagerMock.startUpdatingLocationCalled)
        #expect(locationManagerMock.desiredAccuracy == kCLLocationAccuracyReduced)
        
        await manager.stopLiveLocation(roomID: "!room:matrix.org")
        
        #expect(locationManagerMock.stopUpdatingLocationCalled)
    }
    
    // MARK: - Private
    
    private func makeRoomProxy(roomID: String) -> JoinedRoomProxyMock {
        let roomProxy = JoinedRoomProxyMock(.init(id: roomID))
        roomProxy.startLiveLocationShareDurationReturnValue = .success("$event:matrix.org")
        roomProxy.stopLiveLocationShareReturnValue = .success(())
        return roomProxy
    }
    
    private func setUp(accuracyAuthorization: CLAccuracyAuthorization = .fullAccuracy) {
        appSettings = AppSettings()
        clientProxy = ClientProxyMock(.init())
        beaconInfoSubject = PassthroughSubject<LiveLocationOwnInfoUpdate, Never>()
        clientProxy.liveLocationOwnInfoUpdatesPublisher = beaconInfoSubject.eraseToAnyPublisher()
        locationManagerMock = CLLocationManagerMock(.init(accuracyAuthorization: accuracyAuthorization))
        manager = LiveLocationManager(clientProxy: clientProxy, appSettings: appSettings, locationManager: locationManagerMock)
    }
    
    private func simulateBeaconEcho(roomID: String, eventID: String) async throws {
        let deferred = deferFulfillment(appSettings.$liveLocationSharingSessionsByRoomID) { $0[roomID] != nil }
        beaconInfoSubject.send(LiveLocationOwnInfoUpdate(roomID: roomID, eventID: eventID, isLive: true))
        try await deferred.fulfill()
    }
}
