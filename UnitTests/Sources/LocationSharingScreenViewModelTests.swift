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
        let mapError = AlertInfo(locationSharingViewError: .mapError(.failedLoadingMap))
        #expect(mapError.title == L10n.errorFailedLoadingMap(InfoPlistReader.main.bundleDisplayName))
        let locationError = AlertInfo(locationSharingViewError: .mapError(.failedLocatingUser))
        #expect(locationError.title == L10n.errorFailedLocatingUser(InfoPlistReader.main.bundleDisplayName))
        let AuthorizationError = AlertInfo(locationSharingViewError: .missingAuthorization)
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
    func startLiveLocationWithAlwaysAuthorization() {
        setupViewModel(liveLocationManagerConfiguration: .init(authorizationStatus: .authorizedAlways))
        context.send(viewAction: .startLiveLocation)
        #expect(context.alertInfo == nil)
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
}
