//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import CoreLocation
@testable import ElementX
import Testing

@MainActor
final class LocationSharingScreenViewModelTests {
    private var timelineProxy: TimelineProxyMock!
    private var viewModel: LocationSharingScreenViewModel!
    
    private var context: LocationSharingScreenViewModel.Context {
        viewModel.context
    }
    
    init() {
        AppSettings.resetAllSettings()
    }
    
    deinit {
        AppSettings.resetAllSettings()
    }
    
    @Test
    func userDidPan() {
        setupViewModel()
        #expect(context.viewState.isSharingUserLocation)
        #expect(context.showsUserLocationMode == .showAndFollow)
        context.send(viewAction: .userDidPan)
        #expect(!context.viewState.isSharingUserLocation)
        #expect(context.showsUserLocationMode == .show)
    }
    
    @Test
    func centerOnUser() {
        setupViewModel()
        #expect(context.viewState.isSharingUserLocation)
        context.showsUserLocationMode = .show
        #expect(!context.viewState.isSharingUserLocation)
        context.send(viewAction: .centerToUser)
        #expect(context.viewState.isSharingUserLocation)
        #expect(context.showsUserLocationMode == .showAndFollow)
    }
    
    @Test
    func centerOnUserWithoutAuthorization() {
        setupViewModel()
        context.showsUserLocationMode = .hide
        context.isLocationAuthorized = nil
        context.send(viewAction: .centerToUser)
        #expect(context.showsUserLocationMode == .showAndFollow)
    }
    
    @Test
    func centerOnUserWithDeniedAuthorization() {
        setupViewModel()
        context.isLocationAuthorized = false
        context.showsUserLocationMode = .hide
        context.send(viewAction: .centerToUser)
        #expect(context.showsUserLocationMode != .showAndFollow)
        #expect(context.alertInfo != nil)
    }
    
    @Test
    func errorMapping() {
        setupViewModel()
        let mapError = AlertInfo(alertID: .mapError(.failedLoadingMap))
        #expect(mapError.title == L10n.errorFailedLoadingMap(InfoPlistReader.main.bundleDisplayName))
        let locationError = AlertInfo(alertID: .mapError(.failedLocatingUser))
        #expect(locationError.title == L10n.errorFailedLocatingUser(InfoPlistReader.main.bundleDisplayName))
        let AuthorizationError = AlertInfo(alertID: .missingAuthorization)
        #expect(AuthorizationError.message == L10n.dialogPermissionLocationDescriptionIos(InfoPlistReader.main.bundleDisplayName))
    }

    @Test
    func sendUserLocation() async throws {
        setupViewModel()
        context.mapCenterLocation = .init(latitude: 0, longitude: 0)
        context.geolocationUncertainty = 10
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .close }
        
        try await confirmation { confirmation in
            timelineProxy.sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeClosure = { _, geoURI, _, _, assetType in
                #expect(geoURI.uncertainty == 10)
                #expect(assetType == .sender)
                confirmation()
                return .success(())
            }
            
            context.send(viewAction: .selectLocation)
            
            try await deferred.fulfill()
        }
    }

    @Test
    func sendPickedLocation() async throws {
        setupViewModel()
        context.mapCenterLocation = .init(latitude: 0, longitude: 0)
        context.isLocationAuthorized = nil
        context.geolocationUncertainty = 10

        let deferred = deferFulfillment(viewModel.actions) { $0 == .close }
        
        try await confirmation { confirmation in
            timelineProxy.sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeClosure = { _, geoURI, _, _, assetType in
                #expect(geoURI.uncertainty == nil)
                #expect(assetType == .pin)
                confirmation()
                return .success(())
            }
            
            context.send(viewAction: .selectLocation)
            
            try await deferred.fulfill()
        }
    }
    
    // MARK: - Live Location Authorization Tests
    
    @Test
    func startLiveLocationWithDeniedAuthorization() {
        setupViewModel(liveLocationManagerConfiguration: .init(authorizationStatus: .denied))
        context.send(viewAction: .startLiveLocation)
        #expect(context.alertInfo?.id == .missingAlwaysAuthorization)
    }
    
    @Test
    func startLiveLocationWithRestrictedAuthorization() {
        setupViewModel(liveLocationManagerConfiguration: .init(authorizationStatus: .restricted))
        context.send(viewAction: .startLiveLocation)
        #expect(context.alertInfo?.id == .missingAlwaysAuthorization)
    }
    
    @Test
    func startLiveLocationWithWhenInUseAuthorizationAlreadyRequested() {
        setupViewModel(liveLocationManagerConfiguration: .init(authorizationStatus: .authorizedWhenInUse,
                                                               requestAlwaysAuthorizationIfPossibleReturnValue: false))
        context.send(viewAction: .startLiveLocation)
        #expect(context.alertInfo?.id == .missingAlwaysAuthorization)
    }
    
    @Test
    func startLiveLocationWithWhenInUseAuthorizationNotYetRequested() {
        setupViewModel(liveLocationManagerConfiguration: .init(authorizationStatus: .authorizedWhenInUse,
                                                               requestAlwaysAuthorizationIfPossibleReturnValue: true))
        context.send(viewAction: .startLiveLocation)
        // The request can be made, so no alert should be shown — it waits for the user to respond to the system prompt
        #expect(context.alertInfo == nil)
    }
    
    @Test
    func startLiveLocationWithNotDeterminedAuthorizationTransitionsToWhenInUse() async {
        let authorizationStatusSubject = CurrentValueSubject<CLAuthorizationStatus, Never>(.notDetermined)
        let liveLocationManagerMock = LiveLocationManagerMock()
        liveLocationManagerMock.underlyingAuthorizationStatus = .init(authorizationStatusSubject)
        liveLocationManagerMock.requestAlwaysAuthorizationIfPossibleReturnValue = true
        setupViewModel(liveLocationManagerMock: liveLocationManagerMock)
        
        context.send(viewAction: .startLiveLocation)
        
        // No alert yet — waiting for MapLibre to resolve the status to whenInUse
        #expect(context.alertInfo == nil)
        
        // Simulate MapLibre resolving the Authorization to whenInUse, and confirm that the ViewModel
        // recurses and calls requestAlwaysAuthorizationIfPossible as a result
        await waitForConfirmation { confirmation in
            liveLocationManagerMock.requestAlwaysAuthorizationIfPossibleClosure = {
                confirmation()
                return true
            }
            authorizationStatusSubject.send(.authorizedWhenInUse)
        }
        
        // The request was made, so no alert — waiting for the always Authorization prompt response
        #expect(context.alertInfo == nil)
    }
    
    // MARK: - Live Location Start Flow Tests

    @Test
    func startLiveLocationShowsDisclaimer() {
        setupViewModel(liveLocationManagerConfiguration: .init(authorizationStatus: .authorizedAlways))
        context.send(viewAction: .startLiveLocation)
        #expect(context.alertInfo?.id == .liveLocationDisclaimer)
    }

    @Test
    func startLiveLocationDisclaimerDeclineSkipsStart() {
        let liveLocationManagerMock = LiveLocationManagerMock(.init(authorizationStatus: .authorizedAlways))
        setupViewModel(liveLocationManagerMock: liveLocationManagerMock)
        context.send(viewAction: .startLiveLocation)
        context.alertInfo?.primaryButton.action?()
        #expect(!liveLocationManagerMock.startLiveLocationRoomIDDurationCalled)
    }

    @Test
    func startLiveLocationDisclaimerAcceptShowsDurationPicker() async throws {
        setupViewModel(liveLocationManagerConfiguration: .init(authorizationStatus: .authorizedAlways))
        context.send(viewAction: .startLiveLocation)
        #expect(context.alertInfo?.id == .liveLocationDisclaimer)
        let deferred = deferFulfillment(context.observe(\.alertInfo)) { $0?.id == .liveLocationDurationSelection }
        context.alertInfo?.secondaryButton?.action?()
        try await deferred.fulfill()
    }

    @Test
    func startLiveLocationDurationPickerCancelSkipsStart() async throws {
        let liveLocationManagerMock = LiveLocationManagerMock(.init(authorizationStatus: .authorizedAlways))
        setupViewModel(liveLocationManagerMock: liveLocationManagerMock)
        context.send(viewAction: .startLiveLocation)
        let deferred = deferFulfillment(context.observe(\.alertInfo)) { $0?.id == .liveLocationDurationSelection }
        context.alertInfo?.secondaryButton?.action?()
        try await deferred.fulfill()
        context.alertInfo?.primaryButton.action?()
        #expect(!liveLocationManagerMock.startLiveLocationRoomIDDurationCalled)
    }

    @Test
    func startLiveLocationSuccess() async throws {
        let liveLocationManagerMock = LiveLocationManagerMock(.init(authorizationStatus: .authorizedAlways))
        setupViewModel(liveLocationManagerMock: liveLocationManagerMock)
        context.send(viewAction: .startLiveLocation)
        let durationPicker = deferFulfillment(context.observe(\.alertInfo)) { $0?.id == .liveLocationDurationSelection }
        context.alertInfo?.secondaryButton?.action?()
        try await durationPicker.fulfill()

        let deferred = deferFulfillment(viewModel.actions) { $0 == .close }
        context.alertInfo?.verticalButtons?.first?.action?()
        try await deferred.fulfill()

        #expect(liveLocationManagerMock.startLiveLocationRoomIDDurationCalled)
        let arguments = try #require(liveLocationManagerMock.startLiveLocationRoomIDDurationReceivedArguments)
        #expect(arguments.duration == .seconds(60 * 15))
    }

    @Test
    func startLiveLocationFailureDoesNotClose() async throws {
        let liveLocationManagerMock = LiveLocationManagerMock(.init(authorizationStatus: .authorizedAlways))
        liveLocationManagerMock.startLiveLocationRoomIDDurationReturnValue = .failure(.startFailed)
        setupViewModel(liveLocationManagerMock: liveLocationManagerMock)
        context.send(viewAction: .startLiveLocation)
        let durationPicker = deferFulfillment(context.observe(\.alertInfo)) { $0?.id == .liveLocationDurationSelection }
        context.alertInfo?.secondaryButton?.action?()
        try await durationPicker.fulfill()

        let deferredFailure = deferFailure(viewModel.actions, timeout: .seconds(1)) { $0 == .close }
        context.alertInfo?.verticalButtons?.first?.action?()
        try await deferredFailure.fulfill()
    }

    // MARK: - Live Location Share Update Tests

    @Test
    func viewLiveInitialSenderShownCorrectly() {
        let aliceShare = makeLiveLocationShare(userID: "@alice:matrix.org", latitude: 51.5, longitude: -0.1)
        let sender = TimelineItemSender(id: "@alice:matrix.org", displayName: "Alice")
        let liveLocationsSubject = CurrentValueSubject<[LiveLocationShare], Never>([aliceShare])

        setupViewModelForViewLive(sender: sender, initialShare: aliceShare, liveLocationsSubject: liveLocationsSubject)

        // Initial state is synchronously set from the interaction mode before the async subscription runs.
        let annotations = context.viewState.annotations
        #expect(annotations.count == 1)
        let annotation = annotations.first
        #expect(annotation?.id == "@alice:matrix.org")
        #expect(annotation?.coordinate.latitude == 51.5)
        #expect(annotation?.coordinate.longitude == -0.1)
        #expect(annotation?.kind == .liveUser(.init(userID: "@alice:matrix.org", displayName: "Alice")))
    }

    @Test
    func viewLiveReceivesAdditionalLocationUpdates() async throws {
        let aliceShare = makeLiveLocationShare(userID: "@alice:matrix.org", latitude: 51.5, longitude: -0.1)
        let sender = TimelineItemSender(id: "@alice:matrix.org", displayName: "Alice")
        let liveLocationsSubject = CurrentValueSubject<[LiveLocationShare], Never>([aliceShare])

        setupViewModelForViewLive(sender: sender, initialShare: aliceShare, liveLocationsSubject: liveLocationsSubject)

        let bobShare = makeLiveLocationShare(userID: "@bob:matrix.org", latitude: 48.8, longitude: 2.3)
        let charlieShare = makeLiveLocationShare(userID: "@charlie:matrix.org", latitude: 40.7, longitude: -74.0)

        let deferred = deferFulfillment(context.observe(\.viewState.annotations)) { $0.count == 3 }
        liveLocationsSubject.send([aliceShare, bobShare, charlieShare])
        try await deferred.fulfill()

        let annotations = context.viewState.annotations
        #expect(annotations.count == 3)
        let annotationIDs = Set(annotations.map(\.id))
        #expect(annotationIDs == ["@alice:matrix.org", "@bob:matrix.org", "@charlie:matrix.org"])
        #expect(annotations.first { $0.id == "@alice:matrix.org" }?.coordinate.latitude == 51.5)
        #expect(annotations.first { $0.id == "@bob:matrix.org" }?.coordinate.latitude == 48.8)
        #expect(annotations.first { $0.id == "@charlie:matrix.org" }?.coordinate.latitude == 40.7)
    }

    @Test
    func viewLiveProfilesResolvedFromRoomMembers() async throws {
        let aliceShare = makeLiveLocationShare(userID: "@alice:matrix.org", latitude: 51.5, longitude: -0.1)
        let sender = TimelineItemSender(id: "@alice:matrix.org", displayName: "Alice")
        let liveLocationsSubject = CurrentValueSubject<[LiveLocationShare], Never>([aliceShare])

        setupViewModelForViewLive(sender: sender, initialShare: aliceShare, liveLocationsSubject: liveLocationsSubject)

        let bobShare = makeLiveLocationShare(userID: "@bob:matrix.org", latitude: 48.8, longitude: 2.3)
        let charlieShare = makeLiveLocationShare(userID: "@charlie:matrix.org", latitude: 40.7, longitude: -74.0)

        let deferred = deferFulfillment(context.observe(\.viewState.annotations)) { $0.count == 3 }
        liveLocationsSubject.send([aliceShare, bobShare, charlieShare])
        try await deferred.fulfill()

        // Annotation marker kinds should carry profiles resolved from room members.
        let annotations = context.viewState.annotations
        #expect(annotations.first { $0.id == "@alice:matrix.org" }?.kind == .liveUser(.init(userID: "@alice:matrix.org", displayName: "Alice")))
        #expect(annotations.first { $0.id == "@bob:matrix.org" }?.kind == .liveUser(.init(userID: "@bob:matrix.org", displayName: "Bob")))
        #expect(annotations.first { $0.id == "@charlie:matrix.org" }?.kind == .liveUser(.init(userID: "@charlie:matrix.org", displayName: "Charlie")))
    }

    // MARK: - Private

    private func setupViewModel(liveLocationManagerConfiguration: LiveLocationManagerMock.Configuration = .init()) {
        timelineProxy = TimelineProxyMock(.init())
        viewModel = LocationSharingScreenViewModel(interactionMode: .picker,
                                                   mapURLBuilder: ServiceLocator.shared.settings.mapTilerConfiguration,
                                                   liveLocationSharingEnabled: true,
                                                   roomProxy: JoinedRoomProxyMock(.init()),
                                                   timelineController: MockTimelineController(timelineProxy: timelineProxy),
                                                   liveLocationManager: LiveLocationManagerMock(liveLocationManagerConfiguration),
                                                   analytics: ServiceLocator.shared.analytics,
                                                   userIndicatorController: UserIndicatorControllerMock(),
                                                   mediaProvider: MediaProviderMock(configuration: .init()))
        viewModel.state.bindings.isLocationAuthorized = true
    }
    
    private func setupViewModel(liveLocationManagerMock: LiveLocationManagerMock) {
        timelineProxy = TimelineProxyMock(.init())
        viewModel = LocationSharingScreenViewModel(interactionMode: .picker,
                                                   mapURLBuilder: ServiceLocator.shared.settings.mapTilerConfiguration,
                                                   liveLocationSharingEnabled: true,
                                                   roomProxy: JoinedRoomProxyMock(.init()),
                                                   timelineController: MockTimelineController(timelineProxy: timelineProxy),
                                                   liveLocationManager: liveLocationManagerMock,
                                                   analytics: ServiceLocator.shared.analytics,
                                                   userIndicatorController: UserIndicatorControllerMock(),
                                                   mediaProvider: MediaProviderMock(configuration: .init()))
        viewModel.state.bindings.isLocationAuthorized = true
    }

    private func setupViewModelForViewLive(sender: TimelineItemSender,
                                           initialShare: LiveLocationShare,
                                           liveLocationsSubject: CurrentValueSubject<[LiveLocationShare], Never>,
                                           members: [RoomMemberProxyMock] = .allMembers) {
        let liveLocationServiceMock = RoomLiveLocationServiceMock()
        liveLocationServiceMock.liveLocationsPublisher = liveLocationsSubject.eraseToAnyPublisher()

        let roomProxyMock = JoinedRoomProxyMock(.init(members: members))
        roomProxyMock.makeLiveLocationServiceReturnValue = liveLocationServiceMock

        viewModel = LocationSharingScreenViewModel(interactionMode: .viewLive(sender: sender, initialLiveLocationShare: initialShare),
                                                   mapURLBuilder: ServiceLocator.shared.settings.mapTilerConfiguration,
                                                   liveLocationSharingEnabled: true,
                                                   roomProxy: roomProxyMock,
                                                   timelineController: MockTimelineController(timelineProxy: TimelineProxyMock(.init())),
                                                   liveLocationManager: LiveLocationManagerMock(.init()),
                                                   analytics: ServiceLocator.shared.analytics,
                                                   userIndicatorController: UserIndicatorControllerMock(),
                                                   mediaProvider: MediaProviderMock(configuration: .init()))
    }

    private func makeLiveLocationShare(userID: String, latitude: Double = 0.0, longitude: Double = 0.0) -> LiveLocationShare {
        LiveLocationShare(userID: userID,
                          geoURI: .init(latitude: latitude, longitude: longitude),
                          timestamp: .distantPast,
                          timeoutDate: .distantFuture)
    }
}
