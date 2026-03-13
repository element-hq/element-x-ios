//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation
import Foundation
import MatrixRustSDK

enum LocationSharingViewError: Error, Hashable {
    case missingAuthorization
    case mapError(MapLibreError)
}

enum LocationSharingScreenViewModelAction {
    case close
    case openSystemSettings
}

enum LocationSharingInteractionMode: Hashable {
    case picker
    case viewStatic(StaticLocationData)
}

struct LocationSharingScreenViewState: BindableState {
    init(interactionMode: LocationSharingInteractionMode,
         mapURLBuilder: MapTilerURLBuilderProtocol,
         showLiveLocationSharingButton: Bool,
         ownUserID: String) {
        self.interactionMode = interactionMode
        self.mapURLBuilder = mapURLBuilder
        self.showLiveLocationSharingButton = showLiveLocationSharingButton
        self.ownUserID = ownUserID
        
        bindings.showsUserLocationMode = switch interactionMode {
        case .picker: .showAndFollow
        case .viewStatic: .show
        }
    }

    let interactionMode: LocationSharingInteractionMode
    let mapURLBuilder: MapTilerURLBuilderProtocol
    let showLiveLocationSharingButton: Bool
    let ownUserID: String
    
    var bindings = LocationSharingScreenBindings(showsUserLocationMode: .hide)
 
    /// Indicates whether the user is sharing his current location
    var isSharingUserLocation: Bool {
        bindings.isLocationAuthorized == true && bindings.showsUserLocationMode == .showAndFollow
    }
    
    var initialMapCenter: CLLocationCoordinate2D {
        switch interactionMode {
        case .picker:
            // middle point in Europe, to be used if the users location is not yet known
            .init(latitude: 49.843, longitude: 9.902056)
        case .viewStatic(let location):
            .init(latitude: location.geoURI.latitude, longitude: location.geoURI.longitude)
        }
    }

    var isLocationPickerMode: Bool {
        switch interactionMode {
        case .picker:
            true
        default:
            false
        }
    }
    
    /// Returns true if the user's location has not yet been determined, while location permissions are given or not yet set
    /// Does not work as intended on simulator.
    var isLocationLoading: Bool {
        !bindings.hasLoadedUserLocation && bindings.isLocationAuthorized != false
    }

    var zoomLevel: Double {
        15.0
    }
    
    var initialZoomLevel: Double {
        switch interactionMode {
        case .picker:
            return 2.7
        case .viewStatic:
            return 15.0
        }
    }
    
    var userProfile: UserProfileProxy?
    
    var locationMarkerUserProfile: UserProfileProxy? {
        switch interactionMode {
        case .picker:
            isSharingUserLocation ? userProfile : nil
        case .viewStatic(let location):
            location.kind == .sender ? userProfile : nil
        }
    }
}

struct LocationSharingScreenBindings {
    var mapCenterLocation: CLLocationCoordinate2D?
    var geolocationUncertainty: CLLocationAccuracy?
    var showsUserLocationMode: ShowUserLocationMode
    var hasLoadedUserLocation = false
    var isLocationAuthorized: Bool?
    
    /// Information describing the currently displayed alert.
    var mapError: MapLibreError? {
        get {
            if case let .mapError(error) = alertInfo?.id {
                return error
            }
            return nil
        }
        set {
            alertInfo = newValue.map { AlertInfo(locationSharingViewError: .mapError($0)) }
        }
    }
    
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<LocationSharingViewError>?

    var showShareSheet = false
}

enum LocationSharingScreenViewAction {
    case close
    case selectLocation
    case centerToUser
    case userDidPan
}

extension AlertInfo where T == LocationSharingViewError {
    init(locationSharingViewError error: LocationSharingViewError,
         primaryButton: AlertButton = AlertButton(title: L10n.actionOk, action: nil),
         secondaryButton: AlertButton? = nil) {
        switch error {
        case .missingAuthorization:
            self.init(id: error,
                      title: L10n.dialogAllowAccess,
                      message: L10n.dialogPermissionLocationDescriptionIos(InfoPlistReader.main.bundleDisplayName),
                      primaryButton: primaryButton,
                      secondaryButton: secondaryButton)
        case .mapError(.failedLoadingMap):
            self.init(id: error,
                      title: L10n.errorFailedLoadingMap(InfoPlistReader.main.bundleDisplayName),
                      primaryButton: primaryButton,
                      secondaryButton: secondaryButton)
        case .mapError(.failedLocatingUser):
            self.init(id: error,
                      title: L10n.errorFailedLocatingUser(InfoPlistReader.main.bundleDisplayName),
                      primaryButton: primaryButton,
                      secondaryButton: secondaryButton)
        }
    }
}
