//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import XCTest

@MainActor
class StaticLocationScreenViewModelTests: XCTestCase {
    let timelineProxy = TimelineProxyMock(.init())
    
    var viewModel: StaticLocationScreenViewModelProtocol!
    var context: StaticLocationScreenViewModel.Context {
        viewModel.context
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        cancellables.removeAll()
        let viewModel = StaticLocationScreenViewModel(interactionMode: .picker,
                                                      mapURLBuilder: ServiceLocator.shared.settings.mapTilerConfiguration,
                                                      timelineController: MockTimelineController(timelineProxy: timelineProxy),
                                                      analytics: ServiceLocator.shared.analytics,
                                                      userIndicatorController: UserIndicatorControllerMock())
        viewModel.state.bindings.isLocationAuthorized = true
        self.viewModel = viewModel
    }
    
    func testUserDidPan() {
        XCTAssertTrue(context.viewState.isSharingUserLocation)
        XCTAssertEqual(context.showsUserLocationMode, .showAndFollow)
        context.send(viewAction: .userDidPan)
        XCTAssertFalse(context.viewState.isSharingUserLocation)
        XCTAssertEqual(context.showsUserLocationMode, .show)
    }
    
    func testCenterOnUser() {
        XCTAssertTrue(context.viewState.isSharingUserLocation)
        context.showsUserLocationMode = .show
        XCTAssertFalse(context.viewState.isSharingUserLocation)
        context.send(viewAction: .centerToUser)
        XCTAssertTrue(context.viewState.isSharingUserLocation)
        XCTAssertEqual(context.showsUserLocationMode, .showAndFollow)
    }
    
    func testCenterOnUserWithoutAuth() {
        context.showsUserLocationMode = .hide
        context.isLocationAuthorized = nil
        context.send(viewAction: .centerToUser)
        XCTAssertEqual(context.showsUserLocationMode, .showAndFollow)
    }
    
    func testCenterOnUserWithDeniedAuth() {
        context.isLocationAuthorized = false
        context.showsUserLocationMode = .hide
        context.send(viewAction: .centerToUser)
        XCTAssertNotEqual(context.showsUserLocationMode, .showAndFollow)
        XCTAssertNotNil(context.alertInfo)
    }
    
    func testErrorMapping() {
        let mapError = AlertInfo(locationSharingViewError: .mapError(.failedLoadingMap))
        XCTAssertEqual(mapError.message, L10n.errorFailedLoadingMap(InfoPlistReader.main.bundleDisplayName))
        let locationError = AlertInfo(locationSharingViewError: .mapError(.failedLocatingUser))
        XCTAssertEqual(locationError.message, L10n.errorFailedLocatingUser(InfoPlistReader.main.bundleDisplayName))
        let authorizationError = AlertInfo(locationSharingViewError: .missingAuthorization)
        XCTAssertEqual(authorizationError.message, L10n.dialogPermissionLocationDescriptionIos)
    }

    func testSendUserLocation() async throws {
        context.mapCenterLocation = .init(latitude: 0, longitude: 0)
        context.geolocationUncertainty = 10
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .close }
        let expectation = XCTestExpectation(description: "sendLocation")
        timelineProxy.sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeClosure = { _, geoURI, _, _, assetType in
            XCTAssertEqual(geoURI.uncertainty, 10)
            XCTAssertEqual(assetType, .sender)
            expectation.fulfill()
            return .success(())
        }
        
        context.send(viewAction: .selectLocation)
        await fulfillment(of: [expectation], timeout: 1)
        try await deferred.fulfill()
    }

    func testSendPickedLocation() async throws {
        context.mapCenterLocation = .init(latitude: 0, longitude: 0)
        context.isLocationAuthorized = nil
        context.geolocationUncertainty = 10

        let deferred = deferFulfillment(viewModel.actions) { $0 == .close }
        let expectation = XCTestExpectation(description: "sendLocation")
        timelineProxy.sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeClosure = { _, geoURI, _, _, assetType in
            XCTAssertEqual(geoURI.uncertainty, nil)
            XCTAssertEqual(assetType, .pin)
            expectation.fulfill()
            return .success(())
        }
        
        context.send(viewAction: .selectLocation)
        await fulfillment(of: [expectation], timeout: 1)
        try await deferred.fulfill()
    }
}
