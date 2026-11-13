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
    private let clock = ManualClock()
    /// Whole seconds, so the expiry delays the service works out are exact.
    private var currentDate = Date(timeIntervalSinceReferenceDate: 800_000_000)
    
    // MARK: - startLiveLocation
    
    @Test("Starting a share stops any share from another device first, then waits for the server's echo")
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
    
    @Test("Starting a share in a room that's already sharing stops the old share first")
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
    
    @Test("Starting a share leaves the shares in other rooms alone")
    func startLiveLocationDoesNotStopSessionForOtherRoom() async {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room1:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        
        userSettings.account.liveLocationSharingSessionsByRoomID["!room2:matrix.org"] = LiveLocationSession(eventID: "$event:matrix.org", expirationDate: Date().addingTimeInterval(300))
        
        _ = await service.startLiveLocation(roomID: "!room1:matrix.org", duration: .seconds(300))
        
        #expect(roomProxy.stopLiveLocationShareCalled)
        #expect(userSettings.account.liveLocationSharingSessionsByRoomID["!room2:matrix.org"] != nil)
    }
    
    @Test("Starting a share fails when the room isn't joined")
    func startLiveLocationWhenRoomNotJoined() async {
        setUp()
        clientProxy.roomForIdentifierClosure = { _ in nil }
        
        let result = await service.startLiveLocation(roomID: "!room:matrix.org", duration: .seconds(300))
        
        #expect(throws: LiveLocationServiceError.roomNotJoined) { try result.get() }
        #expect(userSettings.account.liveLocationSharingSessionsByRoomID["!room:matrix.org"] == nil)
    }
    
    @Test("Starting a share fails when the room can't start it")
    func startLiveLocationWhenStartShareFails() async {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        roomProxy.startLiveLocationShareDurationReturnValue = .failure(.sdkError(RoomProxyMockError.generic))
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        
        let result = await service.startLiveLocation(roomID: "!room:matrix.org", duration: .seconds(300))
        
        #expect(throws: LiveLocationServiceError.startFailed) { try result.get() }
        #expect(userSettings.account.liveLocationSharingSessionsByRoomID["!room:matrix.org"] == nil)
    }
    
    @Test("A started share remembers its event and when it expires")
    func startLiveLocationStoresTimeoutDate() async throws {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        
        _ = await service.startLiveLocation(roomID: "!room:matrix.org", duration: .seconds(300))
        
        try await simulateBeaconEcho(roomID: "!room:matrix.org", eventID: "$event:matrix.org")
        
        let storedSession = try #require(userSettings.account.liveLocationSharingSessionsByRoomID["!room:matrix.org"])
        #expect(storedSession.expirationDate == currentDate.addingTimeInterval(300))
        #expect(storedSession.eventID == "$event:matrix.org")
    }
    
    // MARK: - stopLiveLocation
    
    @Test("Stopping a share sends the stop and forgets the share")
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
    
    @Test("Stopping a room without a local share still sends the stop")
    func stopLiveLocationWhenNoSession() async {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        
        await service.stopLiveLocation(roomID: "!room:matrix.org")
        
        #expect(roomProxy.stopLiveLocationShareCalled)
    }
    
    @Test("Stopping a share leaves the shares in other rooms alone")
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
    
    @Test("A new share from another device stops the active share")
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
    
    @Test("A stop from another device stops the active share")
    func beaconInfoStopFromAnotherDeviceRemovesActiveSession() async throws {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        
        try await service.startLiveLocation(roomID: "!room:matrix.org", duration: .seconds(300)).get()
        try await simulateBeaconEcho(roomID: "!room:matrix.org", eventID: "$event:matrix.org")
        
        let deferred = deferFulfillment(userSettings.account.liveLocationSharingSessionsByRoomIDPublisher) { $0["!room:matrix.org"] == nil }
        beaconInfoSubject.send(LiveLocationOwnInfoUpdate(roomID: "!room:matrix.org", eventID: "$stop_event:matrix.org", isLive: false))
        try await deferred.fulfill()
        
        #expect(!service.isSharingPublisher.value)
    }
    
    @Test("Sync sending the active share's beacon info again keeps it sharing")
    func beaconInfoResendKeepsActiveSession() async throws {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        
        try await service.startLiveLocation(roomID: "!room:matrix.org", duration: .seconds(300)).get()
        try await simulateBeaconEcho(roomID: "!room:matrix.org", eventID: "$event:matrix.org")
        
        let deferred = deferFailure(userSettings.account.liveLocationSharingSessionsByRoomIDPublisher, timeout: .milliseconds(300)) { $0["!room:matrix.org"] == nil }
        beaconInfoSubject.send(LiveLocationOwnInfoUpdate(roomID: "!room:matrix.org", eventID: "$event:matrix.org", isLive: true))
        try await deferred.fulfill()
        
        #expect(userSettings.account.liveLocationSharingSessionsByRoomID["!room:matrix.org"]?.eventID == "$event:matrix.org")
        #expect(service.isSharingPublisher.value)
    }
    
    // MARK: - Sharing
    
    @Test("Shares stored before launch count as sharing")
    func sharesStoredBeforeLaunchAreShared() {
        let userSettings = UserSettings.mock()
        userSettings.account.liveLocationSharingSessionsByRoomID["!room:matrix.org"] = LiveLocationSession(eventID: "$event:matrix.org", expirationDate: .distantFuture)
        
        setUp(userSettings: userSettings)
        
        #expect(service.isSharingPublisher.value)
    }
    
    @Test("Location updates are sent to the shared rooms")
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
    
    @Test("Stopping all shares stops every share")
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
    
    // MARK: - Expiry
    
    @Test("A share stops when it expires, even without location updates")
    func aShareStopsWhenItExpiresWithoutLocationUpdates() async {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        userSettings.account.liveLocationSharingSessionsByRoomID["!room:matrix.org"] = LiveLocationSession(eventID: "$event:matrix.org", expirationDate: currentDate.addingTimeInterval(60))
        #expect(await clock.waitForScheduledSleep() == .seconds(60))
        
        await waitForConfirmation("Wait for the share to stop") { confirm in
            roomProxy.stopLiveLocationShareClosure = {
                confirm()
                return .success(())
            }
            advanceTime(by: 60)
        }
        
        #expect(userSettings.account.liveLocationSharingSessionsByRoomID.isEmpty)
        #expect(!service.isSharingPublisher.value)
    }
    
    @Test("A share still stops when the wall clock lags behind the timer")
    func aShareStillStopsWhenTheWallClockLagsBehindTheTimer() async {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        userSettings.account.liveLocationSharingSessionsByRoomID["!room:matrix.org"] = LiveLocationSession(eventID: "$event:matrix.org", expirationDate: currentDate.addingTimeInterval(60))
        #expect(await clock.waitForScheduledSleep() == .seconds(60))
        
        currentDate = currentDate.addingTimeInterval(59)
        clock.advance(by: .seconds(60))
        
        #expect(await clock.waitForScheduledSleep() == .seconds(1))
        #expect(service.isSharingPublisher.value)
        
        await waitForConfirmation("Wait for the share to stop") { confirm in
            roomProxy.stopLiveLocationShareClosure = {
                confirm()
                return .success(())
            }
            advanceTime(by: 1)
        }
        
        #expect(userSettings.account.liveLocationSharingSessionsByRoomID.isEmpty)
    }
    
    @Test("Only the expired share stops")
    func onlyTheExpiredShareStops() async {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room1:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        userSettings.account.liveLocationSharingSessionsByRoomID = [
            "!room1:matrix.org": LiveLocationSession(eventID: "$event1:matrix.org", expirationDate: currentDate.addingTimeInterval(60)),
            "!room2:matrix.org": LiveLocationSession(eventID: "$event2:matrix.org", expirationDate: currentDate.addingTimeInterval(120))
        ]
        #expect(await clock.waitForScheduledSleep() == .seconds(60))
        
        await waitForConfirmation("Wait for the first share to stop") { confirm in
            roomProxy.stopLiveLocationShareClosure = {
                confirm()
                return .success(())
            }
            advanceTime(by: 60)
        }
        
        #expect(Array(userSettings.account.liveLocationSharingSessionsByRoomID.keys) == ["!room2:matrix.org"])
        #expect(service.isSharingPublisher.value)
        #expect(await clock.waitForScheduledSleep() == .seconds(60))
        
        await waitForConfirmation("Wait for the second share to stop") { confirm in
            roomProxy.stopLiveLocationShareClosure = {
                confirm()
                return .success(())
            }
            advanceTime(by: 60)
        }
        
        #expect(userSettings.account.liveLocationSharingSessionsByRoomID.isEmpty)
        #expect(!service.isSharingPublisher.value)
    }
    
    @Test("Shares that expired before launch are stopped")
    func sharesThatExpiredBeforeLaunchAreStopped() async {
        let userSettings = UserSettings.mock()
        userSettings.account.liveLocationSharingSessionsByRoomID["!room:matrix.org"] = LiveLocationSession(eventID: "$event:matrix.org", expirationDate: currentDate.addingTimeInterval(-60))
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        
        await waitForConfirmation("Wait for the share to stop") { confirm in
            roomProxy.stopLiveLocationShareClosure = {
                confirm()
                return .success(())
            }
            setUp(userSettings: userSettings)
            clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
            
            #expect(!service.isSharingPublisher.value)
        }
        
        #expect(userSettings.account.liveLocationSharingSessionsByRoomID.isEmpty)
    }
    
    @Test("Stopping the last share cancels its expiry timer")
    func stoppingTheLastShareCancelsItsExpiry() async {
        setUp()
        let roomProxy = makeRoomProxy(roomID: "!room:matrix.org")
        clientProxy.roomForIdentifierClosure = { _ in .joined(roomProxy) }
        userSettings.account.liveLocationSharingSessionsByRoomID["!room:matrix.org"] = LiveLocationSession(eventID: "$event:matrix.org", expirationDate: currentDate.addingTimeInterval(60))
        await clock.waitForScheduledSleep()
        
        await service.stopLiveLocation(roomID: "!room:matrix.org")
        
        #expect(!clock.hasPendingSleep)
    }
    
    // MARK: - Authorization
    
    @Test("The authorization status follows the manager")
    func authorizationStatusFollowsTheManager() {
        setUp()
        
        service.authorizationStatusChanged(to: .authorizedAlways)
        
        #expect(service.authorizationStatus.value == .authorizedAlways)
    }
    
    @Test("Always authorization is requested until the manager remembers the request")
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
        service = LiveLocationService(clientProxy: clientProxy,
                                      userSettings: userSettings,
                                      timeProvider: TimeProvider(clock: clock) { self.currentDate })
    }
    
    private func advanceTime(by seconds: TimeInterval) {
        currentDate = currentDate.addingTimeInterval(seconds)
        clock.advance(by: .seconds(seconds))
    }
    
    private func simulateBeaconEcho(roomID: String, eventID: String) async throws {
        let deferred = deferFulfillment(userSettings.account.liveLocationSharingSessionsByRoomIDPublisher) { $0[roomID] != nil }
        beaconInfoSubject.send(LiveLocationOwnInfoUpdate(roomID: roomID, eventID: eventID, isLive: true))
        try await deferred.fulfill()
    }
}
