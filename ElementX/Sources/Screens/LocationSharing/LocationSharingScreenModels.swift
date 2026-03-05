//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation
import Foundation

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
    case viewStatic(senderID: String?, geoURI: GeoURI)
    
    var canShowAvatar: Bool {
        switch self {
        case .picker, .viewStatic(.some(_), _):
            true
        default:
            false
        }
    }
}

struct LocationSharingScreenViewState: BindableState {
    init(interactionMode: LocationSharingInteractionMode,
         mapURLBuilder: MapTilerURLBuilderProtocol,
         showLiveLocationSharingButton: Bool) {
        self.interactionMode = interactionMode
        self.mapURLBuilder = mapURLBuilder
        self.showLiveLocationSharingButton = showLiveLocationSharingButton
        
        bindings.showsUserLocationMode = switch interactionMode {
        case .picker: .showAndFollow
        case .viewStatic: .show
        }
    }

    let interactionMode: LocationSharingInteractionMode
    let mapURLBuilder: MapTilerURLBuilderProtocol
    let showLiveLocationSharingButton: Bool
    
    var bindings = LocationSharingScreenBindings(showsUserLocationMode: .hide)
 
    /// Indicates whether the user is sharing his current location
    var isSharingUserLocation: Bool {
        bindings.isLocationAuthorized == true && bindings.showsUserLocationMode == .showAndFollow
    }
    
    var initialMapCenter: CLLocationCoordinate2D {
        switch interactionMode {
        case .picker:
            // middle point in Europe, to be used if the users location is not yet known
            return .init(latitude: 49.843, longitude: 9.902056)
        case .viewStatic(_, let geoURI):
            return .init(latitude: geoURI.latitude, longitude: geoURI.longitude)
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

    var showShareAction: Bool {
        switch interactionMode {
        case .picker:
            return false
        case .viewStatic:
            return true
        }
    }
    
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
    
    var shownUserProfile: UserProfileProxy? {
        switch interactionMode {
        case .picker:
            isSharingUserLocation ? userProfile : nil
        case .viewStatic:
            userProfile
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
