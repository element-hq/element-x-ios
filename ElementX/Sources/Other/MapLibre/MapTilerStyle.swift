//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

/// The style for a map.
/// Values should be Map Libre style IDs generated with an account where the API key belongs to.
/// For more information read [FORKING.md](https://github.com/element-hq/element-x-ios/blob/develop/docs/FORKING.md#setup-the-location-sharing).
enum MapTilerStyle: String {
    case light = "9bc819c8-e627-474a-a348-ec144fe3d810"
    case dark = "dea61faf-292b-4774-9660-58fcef89a7f3"
}
