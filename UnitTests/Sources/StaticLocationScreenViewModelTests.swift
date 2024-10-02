//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import XCTest

@testable import ElementX

@MainActor
class StaticLocationScreenViewModelTests: XCTestCase {
    var viewModel: StaticLocationScreenViewModelProtocol!
    
    private var cancellables = Set<AnyCancellable>()
    
    var context: StaticLocationScreenViewModel.Context {
        viewModel.context
    }
    
    override func setUpWithError() throws {
        cancellables.removeAll()
        let viewModel = StaticLocationScreenViewModel(interactionMode: .picker)
        viewModel.state.bindings.isLocationAuthorized = true
        self.viewModel = viewModel
    }
    
    func testUserDidPan() async throws {
        XCTAssertTrue(context.viewState.isSharingUserLocation)
        XCTAssertEqual(context.showsUserLocationMode, .showAndFollow)
        context.send(viewAction: .userDidPan)
        XCTAssertFalse(context.viewState.isSharingUserLocation)
        XCTAssertEqual(context.showsUserLocationMode, .show)
    }
    
    func testCenterOnUser() async throws {
        XCTAssertTrue(context.viewState.isSharingUserLocation)
        context.showsUserLocationMode = .show
        XCTAssertFalse(context.viewState.isSharingUserLocation)
        context.send(viewAction: .centerToUser)
        XCTAssertTrue(context.viewState.isSharingUserLocation)
        XCTAssertEqual(context.showsUserLocationMode, .showAndFollow)
    }
    
    func testCenterOnUserWithoutAuth() async throws {
        context.showsUserLocationMode = .hide
        context.isLocationAuthorized = nil
        context.send(viewAction: .centerToUser)
        XCTAssertEqual(context.showsUserLocationMode, .showAndFollow)
    }
    
    func testCenterOnUserWithDeniedAuth() async throws {
        context.isLocationAuthorized = false
        context.showsUserLocationMode = .hide
        context.send(viewAction: .centerToUser)
        XCTAssertNotEqual(context.showsUserLocationMode, .showAndFollow)
        XCTAssertNotNil(context.alertInfo)
    }
    
    func testErrorMapping() async throws {
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
        
        let deferred = deferFulfillment(viewModel.actions) { action in
            switch action {
            case .sendLocation:
                return true
            default:
                return false
            }
        }
        
        context.send(viewAction: .selectLocation)
        guard case .sendLocation(let geoUri, let isUserLocation) = try await deferred.fulfill() else {
            XCTFail("Sent action should be 'sendLocation'")
            return
        }
        XCTAssertEqual(geoUri.uncertainty, 10)
        XCTAssertTrue(isUserLocation)
    }

    func testSendPickedLocation() async throws {
        context.mapCenterLocation = .init(latitude: 0, longitude: 0)
        context.isLocationAuthorized = nil
        context.geolocationUncertainty = 10

        let deferred = deferFulfillment(viewModel.actions) { action in
            switch action {
            case .sendLocation:
                return true
            default:
                return false
            }
        }
        
        context.send(viewAction: .selectLocation)
        guard case .sendLocation(let geoUri, let isUserLocation) = try await deferred.fulfill() else {
            XCTFail("Sent action should be 'sendLocation'")
            return
        }
        XCTAssertEqual(geoUri.uncertainty, nil)
        XCTAssertFalse(isUserLocation)
    }
}
