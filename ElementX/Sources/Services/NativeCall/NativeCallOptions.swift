//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import ElementCallAll

/// Serves the call package's settings port from `AppSettings`, reading on access so that a toggle
/// flipped mid-session is picked up by the next call.
struct NativeCallOptions: ElementCallOptions {
    let appSettings: AppSettings
    
    /// We hold the background mode entitlement, so minimized video calls always use the system window.
    var isPictureInPictureEnabled: Bool {
        true
    }
    
    /// Pinned rather than a setting: it has to match the other clients in the room.
    var elementCallCompatibility: MatrixRTCElementCallCompat {
        .stateEvents
    }
    
    /// The stats overlay is a developer affordance, so it follows the same option as the rest.
    var areTileStatsAvailable: Bool {
        appSettings.nativeCallEnabled
    }
}
