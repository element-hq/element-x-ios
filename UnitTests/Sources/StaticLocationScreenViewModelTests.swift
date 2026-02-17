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
struct StaticLocationScreenViewModelTests {
    private let timelineProxy = TimelineProxyMock(.init())
    private var viewModel: StaticLocationScreenViewModelProtocol
    
    private var context: StaticLocationScreenViewModel.Context {
        viewModel.context
    }
    
    init() {
        let viewModel = StaticLocationScreenViewModel(interactionMode: .picker,
                                                      mapURLBuilder: ServiceLocator.shared.settings.mapTilerConfiguration,
                                                      timelineController: MockTimelineController(timelineProxy: timelineProxy),
                                                      analytics: ServiceLocator.shared.analytics,
                                                      userIndicatorController: UserIndicatorControllerMock())
        viewModel.state.bindings.isLocationAuthorized = true
        self.viewModel = viewModel
    }
    
    @Test
    func userDidPan() {
        var testSetup = self
        #expect(testSetup.context.viewState.isSharingUserLocation)
        #expect(testSetup.context.showsUserLocationMode == .showAndFollow)
        testSetup.context.send(viewAction: .userDidPan)
        #expect(!testSetup.context.viewState.isSharingUserLocation)
        #expect(testSetup.context.showsUserLocationMode == .show)
    }
    
    @Test
    func centerOnUser() {
        var testSetup = self
        #expect(testSetup.context.viewState.isSharingUserLocation)
        testSetup.context.showsUserLocationMode = .show
        #expect(!testSetup.context.viewState.isSharingUserLocation)
        testSetup.context.send(viewAction: .centerToUser)
        #expect(testSetup.context.viewState.isSharingUserLocation)
        #expect(testSetup.context.showsUserLocationMode == .showAndFollow)
    }
    
    @Test
    func centerOnUserWithoutAuth() {
        var testSetup = self
        testSetup.context.showsUserLocationMode = .hide
        testSetup.context.isLocationAuthorized = nil
        testSetup.context.send(viewAction: .centerToUser)
        #expect(testSetup.context.showsUserLocationMode == .showAndFollow)
    }
    
    @Test
    func centerOnUserWithDeniedAuth() {
        var testSetup = self
        testSetup.context.isLocationAuthorized = false
        testSetup.context.showsUserLocationMode = .hide
        testSetup.context.send(viewAction: .centerToUser)
        #expect(testSetup.context.showsUserLocationMode != .showAndFollow)
        #expect(testSetup.context.alertInfo != nil)
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
