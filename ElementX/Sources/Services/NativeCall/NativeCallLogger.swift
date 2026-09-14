//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import ElementCallAll

/// Sends the call package's log lines to `MXLog`. The Rust core's own output is bridged separately
/// by `MatrixRTCLogBridge`.
struct NativeCallLogger: ElementCallLogging {
    /// Passes the record's file and line through so entries point at the package, not at here.
    func log(_ record: ElementCallLogRecord) {
        switch record.level {
        case .debug: MXLog.debug(record.message, file: record.file, line: record.line)
        case .info: MXLog.info(record.message, file: record.file, line: record.line)
        case .warning: MXLog.warning(record.message, file: record.file, line: record.line)
        case .error: MXLog.error(record.message, file: record.file, line: record.line)
        }
    }
}
