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
    enum LogLevel: Codable, Hashable {
        case error, warn, info, debug, trace
        case custom(String)
        
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
            case .custom:
                return "Custom"
            }
        }
        
        fileprivate var rawValue: String {
            switch self {
            case .error:
                return "error"
            case .warn:
                return "warn"
            case .info:
                return "info"
            case .debug:
                return "debug"
            case .trace:
                return "trace"
            case .custom(let filter):
                return filter
            }
        }
    }
    
    enum Target: String {
        case common = ""
        
        case elementx
        
        case hyper, matrix_sdk_ffi, matrix_sdk_crypto
        
        case matrix_sdk_client = "matrix_sdk::client"
        case matrix_sdk_crypto_account = "matrix_sdk_crypto::olm::account"
        case matrix_sdk_oidc = "matrix_sdk::oidc"
        case matrix_sdk_http_client = "matrix_sdk::http_client"
        case matrix_sdk_sliding_sync = "matrix_sdk::sliding_sync"
        case matrix_sdk_base_sliding_sync = "matrix_sdk_base::sliding_sync"
        case matrix_sdk_ui_timeline = "matrix_sdk_ui::timeline"
    }
    
    static let targets: OrderedDictionary<Target, LogLevel> = [
        .common: .info,
        .elementx: .info,
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
    init(logLevel: LogLevel, target: String?) {
        fileName = if let target {
            "\(RustTracing.filePrefix)-\(target)"
        } else {
            RustTracing.filePrefix
        }
        
        if case let .custom(filter) = logLevel {
            self.filter = filter
            return
        }
        
        let overrides = Self.targets.keys.reduce(into: [Target: LogLevel]()) { partialResult, target in
            // Keep the defaults here
            let ignoredTargets: [Target] = [.common,
                                            .hyper,
                                            .matrix_sdk_ffi,
                                            .matrix_sdk_oidc,
                                            .matrix_sdk_client,
                                            .matrix_sdk_crypto,
                                            .matrix_sdk_crypto_account,
                                            .matrix_sdk_http_client]
            if ignoredTargets.contains(target) {
                return
            }
            
            partialResult[target] = logLevel
        }
        
        var newTargets = Self.targets
        for (target, logLevel) in overrides {
            newTargets.updateValue(logLevel, forKey: target)
        }
        
        let components = newTargets.map { (target: Target, logLevel: LogLevel) in
            guard !target.rawValue.isEmpty else {
                return logLevel.rawValue
            }
            
            return "\(target.rawValue)=\(logLevel.rawValue)"
        }
        
        filter = components.joined(separator: ",")
    }
}
