//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import CoreLocation
import Foundation

enum LocationSharingViewError: Error, Hashable {
    case missingAuthorization
    case mapError(MapLibreError)
}

enum StaticLocationScreenViewModelAction {
    case close
    case openSystemSettings
    case sendLocation(GeoURI, isUserLocation: Bool)
}

enum StaticLocationInteractionMode: Hashable {
    case picker
    case viewOnly(geoURI: GeoURI, description: String? = nil)
}

struct StaticLocationScreenViewState: BindableState {
    init(interactionMode: StaticLocationInteractionMode) {
        self.interactionMode = interactionMode
        switch interactionMode {
        case .picker:
            bindings.showsUserLocationMode = .showAndFollow
        case .viewOnly:
            bindings.showsUserLocationMode = .show
        }
    }

    let interactionMode: StaticLocationInteractionMode
    /// Indicates whether the user is sharing his current location
    var isSharingUserLocation: Bool {
        bindings.isLocationAuthorized == true && bindings.showsUserLocationMode == .showAndFollow
    }
    
    var bindings = StaticLocationScreenBindings(showsUserLocationMode: .hide)
 
    var initialMapCenter: CLLocationCoordinate2D {
        switch interactionMode {
        case .picker:
            // middle point in Europe, to be used if the users location is not yet known
            return .init(latitude: 49.843, longitude: 9.902056)
        case .viewOnly(let geoURI, _):
            return .init(latitude: geoURI.latitude, longitude: geoURI.longitude)
        }
    }

    var isLocationPickerMode: Bool {
        interactionMode == .picker
    }

    var navigationTitle: String {
        switch interactionMode {
        case .picker:
            return L10n.screenShareLocationTitle
        case .viewOnly:
            return L10n.screenViewLocationTitle
        }
    }

    var showShareAction: Bool {
        switch interactionMode {
        case .picker:
            return false
        case .viewOnly:
            return true
        }
    }

    var zoomLevel: Double {
        15.0
    }
    
    var initialZoomLevel: Double {
        switch interactionMode {
        case .picker:
            return 2.7
        case .viewOnly:
            return 15.0
        }
    }

    var locationDescription: String? {
        switch interactionMode {
        case .picker:
            return nil
        case .viewOnly(_, let description):
            return description
        }
    }
}

struct StaticLocationScreenBindings {
    var mapCenterLocation: CLLocationCoordinate2D?
    var geolocationUncertainty: CLLocationAccuracy?

    var showsUserLocationMode: ShowUserLocationMode
    
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

enum StaticLocationScreenViewAction {
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
                      title: L10n.dialogPermissionLocationTitleIos(InfoPlistReader.main.bundleDisplayName),
                      message: L10n.dialogPermissionLocationDescriptionIos,
                      primaryButton: primaryButton,
                      secondaryButton: secondaryButton)
        case .mapError(.failedLoadingMap):
            self.init(id: error,
                      title: "",
                      message: L10n.errorFailedLoadingMap(InfoPlistReader.main.bundleDisplayName),
                      primaryButton: primaryButton,
                      secondaryButton: secondaryButton)
        case .mapError(.failedLocatingUser):
            self.init(id: error,
                      title: "",
                      message: L10n.errorFailedLocatingUser(InfoPlistReader.main.bundleDisplayName),
                      primaryButton: primaryButton,
                      secondaryButton: secondaryButton)
        }
    }
}
