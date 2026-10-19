//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import CoreLocation
@testable import ElementX
import Testing

@MainActor
final class LiveLocationManagerTests {
    private var appSettings: AppSettings!
    private var locationManagerMock: CLLocationManagerMock!
    private var manager: LiveLocationManager!
    
    // MARK: - Location updates
    
    @Test
    func locationUpdatesRunWhileAnyAccountShares() {
        setUp()
        let aliceSharing = CurrentValueSubject<Bool, Never>(false)
        let bobSharing = CurrentValueSubject<Bool, Never>(false)
        manager.add(makeService(userID: "@alice:matrix.org", isSharing: aliceSharing))
        manager.add(makeService(userID: "@bob:matrix.org", isSharing: bobSharing))
        #expect(!locationManagerMock.startUpdatingLocationCalled)
        
        aliceSharing.send(true)
        bobSharing.send(true)
        #expect(locationManagerMock.startUpdatingLocationCallsCount == 1)
        
        aliceSharing.send(false)
        #expect(!locationManagerMock.stopUpdatingLocationCalled)
        
        bobSharing.send(false)
        #expect(locationManagerMock.stopUpdatingLocationCallsCount == 1)
    }
    
    @Test
    func locationsReachOnlyTheSharingAccounts() {
        setUp()
        let alice = makeService(userID: "@alice:matrix.org", isSharing: .init(true))
        let bob = makeService(userID: "@bob:matrix.org")
        manager.add(alice)
        manager.add(bob)
        
        manager.locationManager(CLLocationManager(), didUpdateLocations: [CLLocation(latitude: 51.5, longitude: -0.1)])
        
        #expect(alice.locationUpdatedCallsCount == 1)
        #expect(alice.locationUpdatedReceivedCoordinate?.latitude == 51.5)
        #expect(!bob.locationUpdatedCalled)
    }
    
    @Test
    func anAccountThatStartsSharingGetsTheLatestLocation() {
        setUp()
        let bobSharing = CurrentValueSubject<Bool, Never>(false)
        let bob = makeService(userID: "@bob:matrix.org", isSharing: bobSharing)
        manager.add(makeService(userID: "@alice:matrix.org", isSharing: .init(true)))
        manager.add(bob)
        manager.locationManager(CLLocationManager(), didUpdateLocations: [CLLocation(latitude: 51.5, longitude: -0.1)])
        
        bobSharing.send(true)
        
        #expect(bob.locationUpdatedCallsCount == 1)
        #expect(bob.locationUpdatedReceivedCoordinate?.latitude == 51.5)
    }
    
    @Test
    func removingAnAccountOnlyStopsUpdatesWhenNoOtherAccountShares() {
        setUp()
        manager.add(makeService(userID: "@alice:matrix.org", isSharing: .init(true)))
        manager.add(makeService(userID: "@bob:matrix.org", isSharing: .init(true)))
        
        manager.remove(userID: "@alice:matrix.org")
        #expect(!locationManagerMock.stopUpdatingLocationCalled)
        
        manager.remove(userID: "@bob:matrix.org")
        #expect(locationManagerMock.stopUpdatingLocationCalled)
    }
    
    @Test
    func addingAnAccountAgainReplacesItsService() {
        setUp()
        // E.g. after clearing the cache, the new session's service replaces the old one.
        let oldAlice = makeService(userID: "@alice:matrix.org", isSharing: .init(true))
        let newAlice = makeService(userID: "@alice:matrix.org", isSharing: .init(true))
        manager.add(oldAlice)
        manager.add(newAlice)
        
        manager.locationManager(CLLocationManager(), didUpdateLocations: [CLLocation(latitude: 51.5, longitude: -0.1)])
        
        #expect(!oldAlice.locationUpdatedCalled)
        #expect(newAlice.locationUpdatedCallsCount == 1)
        #expect(!locationManagerMock.stopUpdatingLocationCalled)
    }
    
    @Test
    func reducedAccuracyAuthorizationUsesReducedAccuracy() {
        setUp(accuracyAuthorization: .reducedAccuracy)
        
        #expect(locationManagerMock.desiredAccuracy == kCLLocationAccuracyReduced)
    }
    
    // MARK: - Authorization
    
    @Test
    func addingAnAccountSharesTheAuthorizationStatus() {
        setUp(authorizationStatus: .authorizedAlways)
        let alice = makeService(userID: "@alice:matrix.org")
        
        manager.add(alice)
        
        #expect(alice.authorizationStatusChangedToReceivedStatus == .authorizedAlways)
    }
    
    @Test
    func addingAnAccountWithoutAlwaysAuthorizationStopsItsShares() async {
        setUp(authorizationStatus: .authorizedWhenInUse)
        let alice = makeService(userID: "@alice:matrix.org", isSharing: .init(true))
        
        await waitForConfirmation("Wait for the shares to stop") { confirm in
            alice.stopAllLiveLocationsClosure = { confirm() }
            manager.add(alice)
        }
    }
    
    @Test
    func losingAlwaysAuthorizationStopsEveryAccountsShares() async {
        setUp(authorizationStatus: .authorizedAlways)
        let alice = makeService(userID: "@alice:matrix.org", isSharing: .init(true))
        let bob = makeService(userID: "@bob:matrix.org", isSharing: .init(true))
        manager.add(alice)
        manager.add(bob)
        
        locationManagerMock.authorizationStatus = .denied
        await waitForConfirmation("Wait for the shares to stop", expectedCount: 2) { confirm in
            alice.stopAllLiveLocationsClosure = { confirm() }
            bob.stopAllLiveLocationsClosure = { confirm() }
            manager.locationManagerDidChangeAuthorization(CLLocationManager())
        }
        
        #expect(alice.authorizationStatusChangedToReceivedStatus == .denied)
        #expect(bob.authorizationStatusChangedToReceivedStatus == .denied)
    }
    
    @Test
    func requestingAlwaysAuthorizationAsksTheLocationManager() {
        setUp()
        let actions = PassthroughSubject<LiveLocationServiceAction, Never>()
        manager.add(makeService(userID: "@alice:matrix.org", actions: actions))
        
        actions.send(.requestAlwaysAuthorization)
        
        #expect(locationManagerMock.requestAlwaysAuthorizationCalled)
        #expect(appSettings.hasRequestedLocationAlwaysLocationAuthorization)
    }
    
    // MARK: - Errors
    
    @Test
    func notFindingTheLocationYetKeepsTheShares() async {
        setUp()
        let alice = makeService(userID: "@alice:matrix.org", isSharing: .init(true))
        manager.add(alice)
        
        await waitForConfirmation("The shares keep running", expectedCount: 0, timeout: .milliseconds(500)) { confirm in
            alice.stopAllLiveLocationsClosure = { confirm() }
            manager.locationManager(CLLocationManager(), didFailWithError: CLError(.locationUnknown))
        }
    }
    
    @Test
    func otherLocationErrorsStopEveryAccountsShares() async {
        setUp()
        let alice = makeService(userID: "@alice:matrix.org", isSharing: .init(true))
        let bob = makeService(userID: "@bob:matrix.org", isSharing: .init(true))
        manager.add(alice)
        manager.add(bob)
        
        await waitForConfirmation("Wait for the shares to stop", expectedCount: 2) { confirm in
            alice.stopAllLiveLocationsClosure = { confirm() }
            bob.stopAllLiveLocationsClosure = { confirm() }
            manager.locationManager(CLLocationManager(), didFailWithError: CLError(.denied))
        }
    }
    
    // MARK: - Private
    
    private func setUp(authorizationStatus: CLAuthorizationStatus = .authorizedAlways,
                       accuracyAuthorization: CLAccuracyAuthorization = .fullAccuracy) {
        locationManagerMock = CLLocationManagerMock(.init(authorizationStatus: authorizationStatus, accuracyAuthorization: accuracyAuthorization))
        appSettings = AppSettings.volatile()
        manager = LiveLocationManager(appSettings: appSettings, locationManager: locationManagerMock)
    }
    
    private func makeService(userID: String,
                             isSharing: CurrentValueSubject<Bool, Never> = .init(false),
                             actions: PassthroughSubject<LiveLocationServiceAction, Never> = .init()) -> LiveLocationServiceMock {
        let service = LiveLocationServiceMock(.init(userID: userID))
        service.isSharingPublisher = isSharing.asCurrentValuePublisher()
        service.actionsPublisher = actions.eraseToAnyPublisher()
        return service
    }
}
