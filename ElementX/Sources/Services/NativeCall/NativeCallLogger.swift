//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import ElementCallAll

/// Sends the call package's own log lines to `MXLog`, so they land in the same rageshake as
/// everything else the app writes. The Rust core's output is installed separately by
/// `MatrixRTCLogBridge`.
struct NativeCallLogger: ElementCallLogging {
    /// The record carries the package's own `#fileID` and line, so these read like any other line
    /// the app writes rather than pointing back at here.
    func log(_ record: ElementCallLogRecord) {
        switch record.level {
        case .debug: MXLog.debug(record.message, file: record.file, line: record.line)
        case .info: MXLog.info(record.message, file: record.file, line: record.line)
        case .warning: MXLog.warning(record.message, file: record.file, line: record.line)
        case .error: MXLog.error(record.message, file: record.file, line: record.line)
        }
    }
}
