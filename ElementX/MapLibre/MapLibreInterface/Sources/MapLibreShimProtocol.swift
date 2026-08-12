//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// Implemented by MapLibreShim's entry point, which the app instantiates after
/// `dlopen`-ing the framework.
public protocol MapLibreShimProtocol {
    /// Routes MapLibre's logs into the app's logger. Call once after loading the shim.
    func configureLogging(_ handler: @escaping @Sendable (MapLogSeverity, String) -> Void)
    
    /// Builds the interactive map view. The app-side `MapLibreMapView` forwards every
    /// body evaluation here so SwiftUI updates flow through to the underlying map.
    func makeMapView(configuration: MapViewConfiguration) -> AnyView
}
