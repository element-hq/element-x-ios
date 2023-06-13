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

import Foundation

enum LocationSharingViewError: Hashable {
    case failedSharingLocation
    case mapError(MapLibreError)
}

enum StaticLocationScreenViewModelAction { }

struct StaticLocationScreenViewState: BindableState {
    var bindings = StaticLocationScreenBindings()
}

struct StaticLocationScreenBindings {
    /// Information describing the currently displayed alert.
    var mapError: MapLibreError? {
        get {
            alertInfo?.mapError
        }
        set {
            alertInfo = newValue.map(AlertInfo.init(mapError:))
        }
    }
    
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<LocationSharingViewError>?
}

enum StaticLocationScreenViewAction { }

private extension AlertInfo where T == LocationSharingViewError {
    var mapError: MapLibreError? {
        guard case let .mapError(error) = id else { return nil }
        return error
    }
    
    // we can switch and localize the Map Libre errors
    init(mapError: MapLibreError) {
        self = AlertInfo(id: .mapError(mapError))
    }
}
