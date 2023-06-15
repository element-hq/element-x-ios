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

/*
 Behavior mode of the current user's location, can be hidden, only shown and shown following the user
 */
enum ShowUserLocationMode {
    /// this mode will show the user pin in map and track him, panning the map automatically
    case follow
    /// this mode will show the user pin in map
    case show
    /// this mode will not show the user pin in map
    case hide
}

enum MapTilerStyle {
    case light
    case dark
}

enum MapLibreError: Error {
    case failedLoadingMap
    case failedLocatingUser
    case invalidLocationAuthorization
}

enum MapTilerGeocodingError: Error {
    case wrongGeocodingURL
    case geocodingFailed
}
