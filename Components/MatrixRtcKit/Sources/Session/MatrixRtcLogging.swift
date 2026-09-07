//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRtc
import Synchronization

public nonisolated enum MatrixRtcLogLevel: Sendable {
    case error, warning, info, debug, verbose
}

/// A log record emitted by the Rust core. Delivered on a dedicated Rust thread, never the main actor.
public nonisolated struct MatrixRtcLogRecord: Sendable {
    public let level: MatrixRtcLogLevel
    public let target: String
    public let message: String
}

/// Routes the Rust core's tracing output into the host app's logger.
///
/// The core installs a process-wide subscriber on first use and refuses a second one, so this
/// must run once, before anything else touches the FFI — `RtcSessionManagerHandle` included.
/// Without it the core is completely silent, errors included.
public nonisolated enum MatrixRtcLogging {
    /// Leaves the per-frame media/livekit flood out while keeping SFU connection and ICE progress
    /// (reported by `livekit` at info) readable.
    public static let defaultFilter = "matrix_rtc_media=debug,matrix_rtc_livekit=debug,livekit=info,libwebrtc=warn,webrtc_sys=warn"
    
    private static let isInstalled = Mutex(false)
    
    /// Installs the log sink. Idempotent; subsequent calls are ignored as the core only takes one subscriber.
    /// - Returns: `false` if the core refused the subscriber (already installed by an earlier call).
    @discardableResult
    public static func install(filter: String = defaultFilter,
                               handler: @escaping @Sendable (MatrixRtcLogRecord) -> Void) -> Bool {
        isInstalled.withLock { isInstalled in
            guard !isInstalled else { return true }
            
            do {
                try setupLogging(config: RtcLogConfig(level: .debug, filter: filter, writeToSystem: false),
                                 sink: Sink(handler: handler))
                isInstalled = true
                return true
            } catch {
                handler(.init(level: .error, target: "matrix_rtc_ffi", message: "Failed installing the log sink: \(error)"))
                return false
            }
        }
    }
    
    private final class Sink: RtcLogSink, Sendable {
        private let handler: @Sendable (MatrixRtcLogRecord) -> Void
        
        init(handler: @escaping @Sendable (MatrixRtcLogRecord) -> Void) {
            self.handler = handler
        }
        
        func log(record: RtcLogRecord) {
            handler(.init(level: .init(record.level), target: record.target, message: record.message))
        }
    }
}

private nonisolated extension MatrixRtcLogLevel {
    init(_ level: RtcLogLevel) {
        switch level {
        case .error: self = .error
        case .warn: self = .warning
        case .info: self = .info
        case .debug: self = .debug
        case .trace: self = .verbose
        }
    }
}
