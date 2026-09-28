//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
struct MapLibreLoaderTests {
    /// The shim is embedded but not linked, if it ever stops being copied into the app (or
    /// the class is renamed) the interactive map would silently stop working.
    @Test
    func loadsTheShim() {
        #expect(MapLibreLoader.shim != nil)
    }
}
