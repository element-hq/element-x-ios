//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRtc

/// The framework's own log lines, routed through the core's subscriber so they land in the same sink
/// (and the same rageshake) as the Rust output.
nonisolated enum MatrixRtcLog {
    static let target = "matrix_rtc_ios"
    
    static func info(_ message: String) {
        logEvent(level: .info, target: target, message: message)
    }
    
    static func warning(_ message: String) {
        logEvent(level: .warn, target: target, message: message)
    }
    
    static func error(_ message: String) {
        logEvent(level: .error, target: target, message: message)
    }
    
    static func debug(_ message: String) {
        logEvent(level: .debug, target: target, message: message)
    }
}
