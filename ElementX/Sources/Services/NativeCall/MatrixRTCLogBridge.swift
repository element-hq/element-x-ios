//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import ElementCallAll

/// Feeds the Rust RTC core's log records into `MXLog` so they end up in rageshakes next to the SDK's.
nonisolated enum MatrixRTCLogBridge {
    /// Idempotent, must run before any other use of the call package.
    static func install() {
        MatrixRTCLogging.install { record in
            // The core's own position when it has one, its module path otherwise.
            let file = record.file ?? record.target
            let line = Int(record.line ?? 0)
            switch record.level {
            case .error: MXLog.error(record.message, file: file, line: line)
            case .warning: MXLog.warning(record.message, file: file, line: line)
            case .info: MXLog.info(record.message, file: file, line: line)
            case .debug: MXLog.debug(record.message, file: file, line: line)
            case .verbose: MXLog.verbose(record.message, file: file, line: line)
            }
        }
    }
}
