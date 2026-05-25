//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// The map tile settings used to build interactive and static map URLs.
///
/// Either resolves to a locally-bundled MapTiler configuration, or to a remote
/// `style.json` URL advertised by the homeserver through the matrix client well-known
/// (`tile_server.map_style_url`). When the override URL is present it fully replaces
/// the bundled configuration and is used regardless of light/dark appearance.
enum MapTilerSettings: Equatable {
    /// All of the configuration necessary to use MapTiler maps.
    ///
    /// The style IDs need to be generated with the account that the API key belongs to. For more information read
    /// [FORKING.md](https://github.com/element-hq/element-x-ios/blob/develop/docs/FORKING.md#setup-the-location-sharing)
    struct Configuration: Equatable {
        let baseURL: URL
        /// The API key for fetching map tiles. When not set, location sharing will be disabled and
        /// any received locations will be shown in the timeline with a generic blurred map image.
        let apiKey: String?
        /// A MapLibre style ID for a light-mode map.
        let lightStyleID: String
        /// A MapLibre style ID for a dark-mode map.
        let darkStyleID: String
    }

    case configuration(Configuration)
    case url(URL)

    var isEnabled: Bool {
        switch self {
        case .configuration(let configuration): configuration.apiKey != nil
        case .url: true
        }
    }
}
