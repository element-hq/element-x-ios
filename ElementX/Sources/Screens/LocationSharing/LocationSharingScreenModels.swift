//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import CoreLocation
import Foundation

enum LocationSharingViewError: Error, Hashable {
    case failedSharingLocation
    case mapError(MapLibreError)
}

enum StaticLocationScreenViewModelAction {
    case close
    case sendLocation(GeoURI)
}

enum StaticLocationInteractionMode: Hashable {
    case picker
    case viewOnly(GeoURI)
}

struct StaticLocationScreenViewState: BindableState {
    init(interactionMode: StaticLocationInteractionMode, isPinDropSharing: Bool = true, showsUserLocationMode: ShowUserLocationMode = .hide) {
        self.interactionMode = interactionMode
        self.isPinDropSharing = isPinDropSharing
        self.showsUserLocationMode = showsUserLocationMode

        switch interactionMode {
        case .picker:
            bindings = .init()
        case .viewOnly(let geoURI):
            bindings = .init(mapCenterLocation: .init(latitude: geoURI.latitude, longitude: geoURI.longitude))
        }
    }

    let interactionMode: StaticLocationInteractionMode
    /// Indicates whether the user has moved around the map to drop a pin somewhere other than their current location
    var isPinDropSharing = true
    /// Behavior mode of the current user's location, can be hidden, only shown and shown following the user
    var showsUserLocationMode: ShowUserLocationMode = .hide
    
    var bindings = StaticLocationScreenBindings()

    var showBottomToolbar: Bool {
        interactionMode == .picker
    }

    var mapAnnotationCoordinate: CLLocationCoordinate2D? {
        switch interactionMode {
        case .picker:
            return nil
        case .viewOnly(let geoURI):
            return .init(latitude: geoURI.latitude, longitude: geoURI.longitude)
        }
    }

    var showPinInTheCenter: Bool {
        switch interactionMode {
        case .picker:
            return isPinDropSharing
        case .viewOnly:
            return false
        }
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
}

struct StaticLocationScreenBindings {
    var mapCenterLocation: CLLocationCoordinate2D?
    
    /// Information describing the currently displayed alert.
    var mapError: MapLibreError? {
        get {
            if case let .mapError(error) = alertInfo?.id {
                return error
            }
            return nil
        }
        set {
            alertInfo = newValue.map { AlertInfo(id: .mapError($0)) }
        }
    }
    
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<LocationSharingViewError>?
}

enum StaticLocationScreenViewAction {
    case close
    case selectLocation
    case userDidPan
}
