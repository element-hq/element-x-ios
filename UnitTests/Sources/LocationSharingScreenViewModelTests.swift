//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Testing

@MainActor
@Suite
struct LocationSharingScreenViewModelTests {
    private let timelineProxy = TimelineProxyMock(.init())
    private var viewModel: LocationSharingScreenViewModelProtocol
    
    private var context: LocationSharingScreenViewModel.Context {
        viewModel.context
    }
    
    init() {
        let viewModel = LocationSharingScreenViewModel(interactionMode: .picker,
                                                       mapURLBuilder: ServiceLocator.shared.settings.mapTilerConfiguration,
                                                       liveLocationSharingEnabled: true,
                                                       timelineController: MockTimelineController(timelineProxy: timelineProxy),
                                                       analytics: ServiceLocator.shared.analytics,
                                                       userIndicatorController: UserIndicatorControllerMock())
        viewModel.state.bindings.isLocationAuthorized = true
        self.viewModel = viewModel
    }
    
    @Test
    func userDidPan() {
        #expect(context.viewState.isSharingUserLocation)
        #expect(context.showsUserLocationMode == .showAndFollow)
        context.send(viewAction: .userDidPan)
        #expect(!context.viewState.isSharingUserLocation)
        #expect(context.showsUserLocationMode == .show)
    }
    
    @Test
    func centerOnUser() {
        #expect(context.viewState.isSharingUserLocation)
        context.showsUserLocationMode = .show
        #expect(!context.viewState.isSharingUserLocation)
        context.send(viewAction: .centerToUser)
        #expect(context.viewState.isSharingUserLocation)
        #expect(context.showsUserLocationMode == .showAndFollow)
    }
    
    @Test
    func centerOnUserWithoutAuth() {
        context.showsUserLocationMode = .hide
        context.isLocationAuthorized = nil
        context.send(viewAction: .centerToUser)
        #expect(context.showsUserLocationMode == .showAndFollow)
    }
    
    @Test
    func centerOnUserWithDeniedAuth() {
        context.isLocationAuthorized = false
        context.showsUserLocationMode = .hide
        context.send(viewAction: .centerToUser)
        #expect(context.showsUserLocationMode != .showAndFollow)
        #expect(context.alertInfo != nil)
    }
    
    @Test
    func errorMapping() {
        let mapError = AlertInfo(locationSharingViewError: .mapError(.failedLoadingMap))
        #expect(mapError.message == L10n.errorFailedLoadingMap(InfoPlistReader.main.bundleDisplayName))
        let locationError = AlertInfo(locationSharingViewError: .mapError(.failedLocatingUser))
        #expect(locationError.message == L10n.errorFailedLocatingUser(InfoPlistReader.main.bundleDisplayName))
        let authorizationError = AlertInfo(locationSharingViewError: .missingAuthorization)
        #expect(authorizationError.message == L10n.dialogPermissionLocationDescriptionIos)
    }

    @Test
    func sendUserLocation() async throws {
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
}
