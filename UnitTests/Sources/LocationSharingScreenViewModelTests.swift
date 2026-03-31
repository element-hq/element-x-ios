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
struct LocationSharingScreenViewModelTests {
    var timelineProxy: TimelineProxyMock!
    var viewModel: LocationSharingScreenViewModel!
    
    var context: LocationSharingScreenViewModel.Context {
        viewModel.context
    }
    
    init() {
        AppSettings.resetAllSettings()
    }
    
    @Test
    mutating func userDidPan() {
        setupViewModel()
        #expect(context.viewState.isSharingUserLocation)
        #expect(context.showsUserLocationMode == .showAndFollow)
        context.send(viewAction: .userDidPan)
        #expect(!context.viewState.isSharingUserLocation)
        #expect(context.showsUserLocationMode == .show)
    }
    
    @Test
    mutating func centerOnUser() {
        setupViewModel()
        #expect(context.viewState.isSharingUserLocation)
        context.showsUserLocationMode = .show
        #expect(!context.viewState.isSharingUserLocation)
        context.send(viewAction: .centerToUser)
        #expect(context.viewState.isSharingUserLocation)
        #expect(context.showsUserLocationMode == .showAndFollow)
    }
    
    @Test
    mutating func centerOnUserWithoutAuth() {
        setupViewModel()
        context.showsUserLocationMode = .hide
        context.isLocationAuthorized = nil
        context.send(viewAction: .centerToUser)
        #expect(context.showsUserLocationMode == .showAndFollow)
    }
    
    @Test
    mutating func centerOnUserWithDeniedAuth() {
        setupViewModel()
        context.isLocationAuthorized = false
        context.showsUserLocationMode = .hide
        context.send(viewAction: .centerToUser)
        #expect(context.showsUserLocationMode != .showAndFollow)
        #expect(context.alertInfo != nil)
    }
    
    @Test
    mutating func errorMapping() {
        setupViewModel()
        let mapError = AlertInfo(locationSharingViewError: .mapError(.failedLoadingMap))
        #expect(mapError.title == L10n.errorFailedLoadingMap(InfoPlistReader.main.bundleDisplayName))
        let locationError = AlertInfo(locationSharingViewError: .mapError(.failedLocatingUser))
        #expect(locationError.title == L10n.errorFailedLocatingUser(InfoPlistReader.main.bundleDisplayName))
        let authorizationError = AlertInfo(locationSharingViewError: .missingAuthorization)
        #expect(authorizationError.message == L10n.dialogPermissionLocationDescriptionIos(InfoPlistReader.main.bundleDisplayName))
    }

    @Test
    mutating func sendUserLocation() async throws {
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
    mutating func sendPickedLocation() async throws {
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
    mutating func startLiveLocationWithDeniedAuth() {
        setupViewModel(liveLocationManagerConfiguration: .init(authorizationStatus: .denied))
        context.send(viewAction: .startLiveLocation)
        #expect(context.alertInfo?.id == .missingAlwaysAuthorization)
    }
    
    @Test
    mutating func startLiveLocationWithRestrictedAuth() {
        setupViewModel(liveLocationManagerConfiguration: .init(authorizationStatus: .restricted))
        context.send(viewAction: .startLiveLocation)
        #expect(context.alertInfo?.id == .missingAlwaysAuthorization)
    }
    
    @Test
    mutating func startLiveLocationWithAlwaysAuth() {
        setupViewModel(liveLocationManagerConfiguration: .init(authorizationStatus: .authorizedAlways))
        context.send(viewAction: .startLiveLocation)
        #expect(context.alertInfo == nil)
    }
    
    @Test
    mutating func startLiveLocationWithWhenInUseAuthAlreadyRequested() {
        setupViewModel(liveLocationManagerConfiguration: .init(authorizationStatus: .authorizedWhenInUse,
                                                               requestAlwaysAuthorizationIfPossibleReturnValue: false))
        context.send(viewAction: .startLiveLocation)
        #expect(context.alertInfo?.id == .missingAlwaysAuthorization)
    }
    
    @Test
    mutating func startLiveLocationWithWhenInUseAuthNotYetRequested() {
        setupViewModel(liveLocationManagerConfiguration: .init(authorizationStatus: .authorizedWhenInUse,
                                                               requestAlwaysAuthorizationIfPossibleReturnValue: true))
        context.send(viewAction: .startLiveLocation)
        // The request can be made, so no alert should be shown — it waits for the user to respond to the system prompt
        #expect(context.alertInfo == nil)
    }
    
    @Test
    mutating func startLiveLocationWithNotDeterminedAuthTransitionsToWhenInUse() async {
        let authorizationStatusSubject = CurrentValueSubject<CLAuthorizationStatus, Never>(.notDetermined)
        let liveLocationManagerMock = LiveLocationManagerMock()
        liveLocationManagerMock.underlyingAuthorizationStatus = .init(authorizationStatusSubject)
        liveLocationManagerMock.requestAlwaysAuthorizationIfPossibleReturnValue = true
        setupViewModel(liveLocationManagerMock: liveLocationManagerMock)
        
        context.send(viewAction: .startLiveLocation)
        
        // No alert yet — waiting for MapLibre to resolve the status to whenInUse
        #expect(context.alertInfo == nil)
        
        // Simulate MapLibre resolving the authorization to whenInUse, and confirm that the ViewModel
        // recurses and calls requestAlwaysAuthorizationIfPossible as a result
        await waitForConfirmation { confirmation in
            liveLocationManagerMock.requestAlwaysAuthorizationIfPossibleClosure = {
                confirmation()
                return true
            }
            authorizationStatusSubject.send(.authorizedWhenInUse)
        }
        
        // The request was made, so no alert — waiting for the always authorization prompt response
        #expect(context.alertInfo == nil)
    }
    
    // MARK: - Private
    
    private mutating func setupViewModel(liveLocationManagerConfiguration: LiveLocationManagerMock.Configuration = .init()) {
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
    
    private mutating func setupViewModel(liveLocationManagerMock: LiveLocationManagerMock) {
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
}
