//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

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
    
    init() {
        AppSettings.resetAllSettings()
    }
    
    deinit {
        AppSettings.resetAllSettings()
    }
    
    // MARK: - startLiveLocation
    
    @Test
    func startLiveLocationWithNoExistingSession() async throws {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        
        let result = await manager.startLiveLocation(roomID: "!room:matrix.org", duration: .seconds(300))
        
        try result.get()
        #expect(roomProxy.startLiveLocationShareDurationCalled)
        #expect(!roomProxy.stopLiveLocationShareCalled)
        #expect(appSettings.liveLocationSharingTimeoutDatesByRoomID["!room:matrix.org"] != nil)
        #expect(locationManagerMock.startUpdatingLocationCalled)
    }
    
    @Test
    func startLiveLocationWithExistingSessionStopsItFirst() async throws {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        appSettings.liveLocationSharingTimeoutDatesByRoomID["!room:matrix.org"] = Date().addingTimeInterval(300)
        
        var callOrder: [String] = []
        roomProxy.stopLiveLocationShareClosure = {
            callOrder.append("stop")
            return .success(())
        }
        roomProxy.startLiveLocationShareDurationClosure = { _ in
            callOrder.append("start")
            return .success(())
        }
        
        let result = await manager.startLiveLocation(roomID: "!room:matrix.org", duration: .seconds(600))
        
        try result.get()
        #expect(callOrder == ["stop", "start"])
        #expect(appSettings.liveLocationSharingTimeoutDatesByRoomID["!room:matrix.org"] != nil)
    }
    
    @Test
    func startLiveLocationDoesNotStopSessionForOtherRoom() async {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room1:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        
        appSettings.liveLocationSharingTimeoutDatesByRoomID["!room2:matrix.org"] = Date().addingTimeInterval(300)
        
        _ = await manager.startLiveLocation(roomID: "!room1:matrix.org", duration: .seconds(300))
        
        #expect(!roomProxy.stopLiveLocationShareCalled)
        #expect(appSettings.liveLocationSharingTimeoutDatesByRoomID["!room2:matrix.org"] != nil)
    }
    
    @Test
    func startLiveLocationWhenRoomNotJoined() async {
        setUp()
        clientProxy.roomForIdentifierClosure = { _ in nil }
        
        let result = await manager.startLiveLocation(roomID: "!room:matrix.org", duration: .seconds(300))
        
        #expect(throws: LiveLocationManagerError.roomNotJoined) { try result.get() }
        #expect(appSettings.liveLocationSharingTimeoutDatesByRoomID["!room:matrix.org"] == nil)
    }
    
    @Test
    func startLiveLocationWhenStartShareFails() async {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        roomProxy.startLiveLocationShareDurationReturnValue = .failure(.sdkError(RoomProxyMockError.generic))
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        
        let result = await manager.startLiveLocation(roomID: "!room:matrix.org", duration: .seconds(300))
        
        #expect(throws: LiveLocationManagerError.startFailed) { try result.get() }
        #expect(appSettings.liveLocationSharingTimeoutDatesByRoomID["!room:matrix.org"] == nil)
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
        
        let storedTimeout = appSettings.liveLocationSharingTimeoutDatesByRoomID["!room:matrix.org"]
        let expectedMinTimeout = beforeStart.addingTimeInterval(TimeInterval(duration.seconds))
        let expectedMaxTimeout = afterStart.addingTimeInterval(TimeInterval(duration.seconds))
        
        try #expect((expectedMinTimeout...expectedMaxTimeout).contains(#require(storedTimeout)))
    }
    
    // MARK: - stopLiveLocation
    
    @Test
    func stopLiveLocationWhenSessionExists() async {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        appSettings.liveLocationSharingTimeoutDatesByRoomID["!room:matrix.org"] = Date().addingTimeInterval(300)
        
        await manager.stopLiveLocation(roomID: "!room:matrix.org")
        
        #expect(roomProxy.stopLiveLocationShareCalled)
        #expect(appSettings.liveLocationSharingTimeoutDatesByRoomID["!room:matrix.org"] == nil)
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
        appSettings.liveLocationSharingTimeoutDatesByRoomID["!room1:matrix.org"] = Date().addingTimeInterval(300)
        appSettings.liveLocationSharingTimeoutDatesByRoomID["!room2:matrix.org"] = Date().addingTimeInterval(300)
        
        await manager.stopLiveLocation(roomID: "!room1:matrix.org")
        
        #expect(appSettings.liveLocationSharingTimeoutDatesByRoomID["!room1:matrix.org"] == nil)
        #expect(appSettings.liveLocationSharingTimeoutDatesByRoomID["!room2:matrix.org"] != nil)
    }
    
    // MARK: - Reduced accuracy
    
    @Test
    func startLiveLocationInReducedAccuracyMode() async throws {
        setUp(accuracyAuthorization: .reducedAccuracy)
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        
        let result = await manager.startLiveLocation(roomID: "!room:matrix.org", duration: .seconds(300))
        try result.get()
        
        #expect(locationManagerMock.startUpdatingLocationCalled)
        #expect(locationManagerMock.desiredAccuracy == kCLLocationAccuracyReduced)
        
        await manager.stopLiveLocation(roomID: "!room:matrix.org")
        
        #expect(locationManagerMock.stopUpdatingLocationCalled)
    }
    
    // MARK: - Private
    
    private func makeRoomProxy(roomID: String) -> JoinedRoomProxyMock {
        let roomProxy = JoinedRoomProxyMock(.init(id: roomID))
        roomProxy.startLiveLocationShareDurationReturnValue = .success(())
        roomProxy.stopLiveLocationShareReturnValue = .success(())
        return roomProxy
    }
    
    private func setUp(accuracyAuthorization: CLAccuracyAuthorization = .fullAccuracy) {
        appSettings = AppSettings()
        clientProxy = ClientProxyMock(.init())
        locationManagerMock = CLLocationManagerMock(.init(accuracyAuthorization: accuracyAuthorization))
        manager = LiveLocationManager(clientProxy: clientProxy, appSettings: appSettings, locationManager: locationManagerMock)
    }
}
