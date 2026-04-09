//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

@MainActor
final class LiveLocationManagerTests {
    private var clientProxy: ClientProxyMock!
    private var manager: LiveLocationManager!
    
    private var appSettings: AppSettings {
        ServiceLocator.shared.settings
    }
    
    init() {
        AppSettings.resetAllSettings()
        clientProxy = ClientProxyMock(.init())
        manager = LiveLocationManager(clientProxy: clientProxy, appSettings: ServiceLocator.shared.settings)
    }
    
    deinit {
        AppSettings.resetAllSettings()
    }
    
    // MARK: - startLiveLocation
    
    @Test
    func startLiveLocationWithNoExistingSession() async {
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        
        let result = await manager.startLiveLocation(roomID: "!room:matrix.org", duration: .seconds(300))
        
        guard case .success = result else {
            Issue.record("Expected success but got \(result)")
            return
        }
        #expect(roomProxy.startLiveLocationShareDurationCalled)
        #expect(!roomProxy.stopLiveLocationShareCalled)
        #expect(appSettings.liveLocationSharingTimeoutDatesByRoomID["!room:matrix.org"] != nil)
    }
    
    @Test
    func startLiveLocationWithExistingSessionStopsItFirst() async {
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
        
        guard case .success = result else {
            Issue.record("Expected success but got \(result)")
            return
        }
        #expect(callOrder == ["stop", "start"])
        #expect(appSettings.liveLocationSharingTimeoutDatesByRoomID["!room:matrix.org"] != nil)
    }
    
    @Test
    func startLiveLocationDoesNotStopSessionForOtherRoom() async {
        let roomProxy = makeRoomProxy(roomID: "!room1:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        
        appSettings.liveLocationSharingTimeoutDatesByRoomID["!room2:matrix.org"] = Date().addingTimeInterval(300)
        
        _ = await manager.startLiveLocation(roomID: "!room1:matrix.org", duration: .seconds(300))
        
        #expect(!roomProxy.stopLiveLocationShareCalled)
        #expect(appSettings.liveLocationSharingTimeoutDatesByRoomID["!room2:matrix.org"] != nil)
    }
    
    @Test
    func startLiveLocationWhenRoomNotJoined() async {
        clientProxy.roomForIdentifierClosure = { _ in nil }
        
        let result = await manager.startLiveLocation(roomID: "!room:matrix.org", duration: .seconds(300))
        
        guard case .failure(.roomNotJoined) = result else {
            Issue.record("Expected roomNotJoined failure but got \(result)")
            return
        }
        #expect(appSettings.liveLocationSharingTimeoutDatesByRoomID["!room:matrix.org"] == nil)
    }
    
    @Test
    func startLiveLocationWhenStartShareFails() async {
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        roomProxy.startLiveLocationShareDurationReturnValue = .failure(.sdkError(RoomProxyMockError.generic))
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        
        let result = await manager.startLiveLocation(roomID: "!room:matrix.org", duration: .seconds(300))
        
        guard case .failure(.startFailed) = result else {
            Issue.record("Expected startFailed failure but got \(result)")
            return
        }
        #expect(appSettings.liveLocationSharingTimeoutDatesByRoomID["!room:matrix.org"] == nil)
    }
    
    @Test
    func startLiveLocationStoresTimeoutDate() async throws {
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        
        let duration = Duration.seconds(300)
        let beforeStart = Date()
        _ = await manager.startLiveLocation(roomID: "!room:matrix.org", duration: duration)
        let afterStart = Date()
        
        let storedTimeout = appSettings.liveLocationSharingTimeoutDatesByRoomID["!room:matrix.org"]
        let expectedMinTimeout = beforeStart.addingTimeInterval(TimeInterval(duration.seconds))
        let expectedMaxTimeout = afterStart.addingTimeInterval(TimeInterval(duration.seconds))
        
        #expect(storedTimeout != nil)
        #expect(try #require(storedTimeout) >= expectedMinTimeout)
        #expect(try #require(storedTimeout) <= expectedMaxTimeout)
    }
    
    // MARK: - stopLiveLocation
    
    @Test
    func stopLiveLocationWhenSessionExists() async {
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        appSettings.liveLocationSharingTimeoutDatesByRoomID["!room:matrix.org"] = Date().addingTimeInterval(300)
        
        await manager.stopLiveLocation(roomID: "!room:matrix.org")
        
        #expect(roomProxy.stopLiveLocationShareCalled)
        #expect(appSettings.liveLocationSharingTimeoutDatesByRoomID["!room:matrix.org"] == nil)
    }
    
    @Test
    func stopLiveLocationWhenNoSession() async {
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        
        await manager.stopLiveLocation(roomID: "!room:matrix.org")
        
        #expect(roomProxy.stopLiveLocationShareCalled)
    }
    
    @Test
    func stopLiveLocationDoesNotRemoveOtherSessions() async {
        let roomProxy = makeRoomProxy(roomID: "!room1:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        appSettings.liveLocationSharingTimeoutDatesByRoomID["!room1:matrix.org"] = Date().addingTimeInterval(300)
        appSettings.liveLocationSharingTimeoutDatesByRoomID["!room2:matrix.org"] = Date().addingTimeInterval(300)
        
        await manager.stopLiveLocation(roomID: "!room1:matrix.org")
        
        #expect(appSettings.liveLocationSharingTimeoutDatesByRoomID["!room1:matrix.org"] == nil)
        #expect(appSettings.liveLocationSharingTimeoutDatesByRoomID["!room2:matrix.org"] != nil)
    }
    
    // MARK: - Private
    
    private func makeRoomProxy(roomID: String) -> JoinedRoomProxyMock {
        let roomProxy = JoinedRoomProxyMock(.init(id: roomID))
        roomProxy.startLiveLocationShareDurationReturnValue = .success(())
        roomProxy.stopLiveLocationShareReturnValue = .success(())
        return roomProxy
    }
}
