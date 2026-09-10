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
struct NativeCallOptionsAdapter: ElementCallOptions {
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

/// Sends the call package's own log lines to `MXLog`, so they land in the same place, and the same
/// rageshake, as everything else the app writes.
///
/// This covers only the package's Swift logging. The Rust core's output is installed separately by
/// `MatrixRTCLogBridge`.
struct NativeCallLoggerAdapter: ElementCallLogging {
    /// The record carries the package's own `#fileID` and line, so these read like any other line
    /// the app writes rather than pointing back at this adapter.
    func log(_ record: ElementCallLogRecord) {
        switch record.level {
        case .debug: MXLog.verbose(record.message, file: record.file, line: record.line)
        case .info: MXLog.info(record.message, file: record.file, line: record.line)
        case .warning: MXLog.warning(record.message, file: record.file, line: record.line)
        case .error: MXLog.error(record.message, file: record.file, line: record.line)
        }
    }
}
