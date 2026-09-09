//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import ElementCall
import ElementCallKit

/// Serves the call package's settings port from `AppSettings`.
///
/// Every member reads the setting on access rather than capturing it, so a developer flipping a
/// toggle mid-session is seen by the next call without restarting anything.
struct ElementCallOptionsAdapter: ElementCallOptions {
    let appSettings: AppSettings
    
    /// We hold the background mode entitlement, so minimized video calls always use the system window.
    var isPictureInPictureEnabled: Bool {
        true
    }
    
    var elementCallCompatibility: MatrixRtcElementCallCompat {
        switch appSettings.nativeCallElementCallCompat {
        case .off: .off
        case .stickyEvents: .stickyEvents
        case .stateEvents: .stateEvents
        }
    }
    
    /// The stats overlay is a developer affordance, so it follows the same option as the rest.
    var areTileStatsAvailable: Bool {
        appSettings.nativeCallEnabled
    }
}

/// Sends the call package's own log lines to `MXLog`, so they land in the same place, and the same
/// rageshake, as everything else the app writes.
///
/// This covers only the package's Swift logging. The Rust core's output is installed separately by
/// `MatrixRtcLogBridge`.
struct ElementCallLoggerAdapter: ElementCallLogging {
    func log(_ level: ElementCallLogLevel, _ message: String) {
        switch level {
        case .debug: MXLog.verbose("ElementCall: \(message)")
        case .info: MXLog.info("ElementCall: \(message)")
        case .warning: MXLog.warning("ElementCall: \(message)")
        case .error: MXLog.error("ElementCall: \(message)")
        }
    }
}
