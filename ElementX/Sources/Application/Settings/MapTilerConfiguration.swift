//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// All of the configuration necessary to use MapTiler maps.
///
/// The style IDs need to be generated with the account that the API key belongs to. For more information read
/// [FORKING.md](https://github.com/element-hq/element-x-ios/blob/develop/docs/FORKING.md#setup-the-location-sharing)
struct MapTilerConfiguration {
    let baseURL: URL
    /// The API key for fetching map tiles. When not set, location sharing will be disabled and
    /// any received locations will be shown in the timeline with a generic blurred map image.
    let apiKey: String?
    /// A MapLibre style ID for a light-mode map.
    let lightStyleID: String
    /// A MapLibre style ID for a dark-mode map.
    let darkStyleID: String
    
    var isEnabled: Bool {
        apiKey != nil
    }
}
