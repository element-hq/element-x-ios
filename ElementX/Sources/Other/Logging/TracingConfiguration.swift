//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Collections

// This exposes the full Rust side tracing subscriber filter for more flexibility.
// We can filter by level, crate and even file. See more details here:
// https://docs.rs/tracing-subscriber/0.2.7/tracing_subscriber/filter/struct.EnvFilter.html#examples
struct TracingConfiguration {
    enum LogLevel: String, Codable, Hashable, Comparable {
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
        
        static func < (lhs: TracingConfiguration.LogLevel, rhs: TracingConfiguration.LogLevel) -> Bool {
            switch (lhs, rhs) {
            case (.error, _):
                true
            case (.warn, .error):
                false
            case (.warn, _):
                true
            case (.info, .error), (.info, .warn):
                false
            case (.info, _):
                true
            case (.debug, .error), (.debug, .warn), (.debug, .info):
                false
            case (.debug, _):
                true
            case (.trace, _):
                false
            }
        }
    }
    
    enum Target: String {
        case hyper, matrix_sdk_ffi, matrix_sdk_crypto
        
        case matrix_sdk_client = "matrix_sdk::client"
        case matrix_sdk_crypto_account = "matrix_sdk_crypto::olm::account"
        case matrix_sdk_oidc = "matrix_sdk::oidc"
        case matrix_sdk_http_client = "matrix_sdk::http_client"
        case matrix_sdk_sliding_sync = "matrix_sdk::sliding_sync"
        case matrix_sdk_base_sliding_sync = "matrix_sdk_base::sliding_sync"
        case matrix_sdk_ui_timeline = "matrix_sdk_ui::timeline"
    }
    
    // The `common` target is excluded because 3rd-party crates might end up logging user data.
    static let targets: OrderedDictionary<Target, LogLevel> = [
        .hyper: .warn,
        .matrix_sdk_ffi: .info,
        .matrix_sdk_client: .trace,
        .matrix_sdk_crypto: .debug,
        .matrix_sdk_crypto_account: .trace,
        .matrix_sdk_oidc: .trace,
        .matrix_sdk_http_client: .debug,
        .matrix_sdk_sliding_sync: .info,
        .matrix_sdk_base_sliding_sync: .info,
        .matrix_sdk_ui_timeline: .info
    ]
    
    let filter: String
    
    /// The filename that logs should be written to.
    let fileName: String
    /// The file extension to use for log files.
    let fileExtension = "log"
    
    /// Sets the same log level for all Targets
    /// - Parameter logLevel: the desired log level
    /// - Parameter target: the name of the target being configured
    /// - Returns: a custom tracing configuration
    init(logLevel: LogLevel, target: String) {
        fileName = "\(RustTracing.filePrefix)-\(target)"

        let overrides = Self.targets.keys.reduce(into: [Target: LogLevel]()) { partialResult, target in
            // Keep the defaults here
            let ignoredTargets: [Target] = [.hyper]
            
            if ignoredTargets.contains(target) {
                return
            }
            
            guard let defaultTargetLogLevel = Self.targets[target] else {
                return
            }
            
            // Only change the targets that have default values
            // smaller than the desired log level
            if defaultTargetLogLevel < logLevel {
                partialResult[target] = logLevel
            }
        }
        
        var newTargets = Self.targets
        for (target, logLevel) in overrides {
            newTargets.updateValue(logLevel, forKey: target)
        }
        
        var components = newTargets.map { (target: Target, logLevel: LogLevel) in
            guard !target.rawValue.isEmpty else {
                return logLevel.rawValue
            }
            
            return "\(target.rawValue)=\(logLevel.rawValue)"
        }
        
        // With `common` not being used we manually need to specify the log
        // level for passed in targets
        components.append("\(target)=\(logLevel.rawValue)")
        
        filter = components.joined(separator: ",")
    }
}
