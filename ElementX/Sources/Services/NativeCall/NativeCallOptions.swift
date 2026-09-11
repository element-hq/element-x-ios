//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import ElementCallAll

/// Serves the call package's settings port from `AppSettings`.
///
/// Every member reads the setting on access rather than capturing it, so a developer flipping a
/// toggle mid-session is seen by the next call without restarting anything.
struct NativeCallOptions: ElementCallOptions {
    let appSettings: AppSettings
    
    /// We hold the background mode entitlement, so minimized video calls always use the system window.
    var isPictureInPictureEnabled: Bool {
        true
    }
    
    /// Pinned rather than a setting: this has to match the other clients in the room, so it isn't a
    /// choice a user can usefully make, and it likely belongs to the call package rather than here.
    var elementCallCompatibility: MatrixRTCElementCallCompat {
        .stateEvents
    }
    
    /// The stats overlay is a developer affordance, so it follows the same option as the rest.
    var areTileStatsAvailable: Bool {
        appSettings.nativeCallEnabled
    }
}
