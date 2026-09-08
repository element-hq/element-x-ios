//
// Copyright 2026 Element Creations Ltd.
// Copyright 2026 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import ElementCallKit
import Foundation

/// Feeds the Rust RTC core's log records into `MXLog` so they end up in rageshakes next to the SDK's.
nonisolated enum MatrixRtcLogBridge {
    /// Idempotent, must run before any other use of the call package.
    static func install() {
        MatrixRtcLogging.install { record in
            let message = "[\(record.target)] \(record.message)"
            switch record.level {
            case .error: MXLog.error(message)
            case .warning: MXLog.warning(message)
            case .info: MXLog.info(message)
            case .debug: MXLog.debug(message)
            case .verbose: MXLog.verbose(message)
            }
        }
    }
}
