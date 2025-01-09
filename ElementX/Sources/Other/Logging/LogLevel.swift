//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum LogLevel: String, Codable, Hashable {
    case error, warn, info, debug, trace
    
    var title: String {
        switch self {
        case .error:
            return "Error"
        case .warn:
            return "Warning"
        case .info:
            return "Info"
        case .debug:
            return "Debug"
        case .trace:
            return "Trace"
        }
    }
    
    var rustLogLevel: MatrixRustSDK.LogLevel {
        switch self {
        case .error:
            .error
        case .warn:
            .warn
        case .info:
            .info
        case .debug:
            .debug
        case .trace:
            .trace
        }
    }
}
