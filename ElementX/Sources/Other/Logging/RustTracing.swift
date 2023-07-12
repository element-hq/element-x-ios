//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Collections
import MatrixRustSDK

// This exposes the full Rust side tracing subscriber filter for more flexibility.
// We can filter by level, crate and even file. See more details here:
// https://docs.rs/tracing-subscriber/0.2.7/tracing_subscriber/filter/struct.EnvFilter.html#examples
struct TracingConfiguration {
    static var release = TracingConfiguration(overrides: [.common: .info])
    
    static var debug = TracingConfiguration(overrides: [.common: .info])
    
    /// Configure tracing with certain overrides in place
    /// - Parameter overrides: the desired overrides
    /// - Returns: a custom tracing configuration
    static func custom(overrides: [Target: LogLevel]) -> TracingConfiguration {
        TracingConfiguration(overrides: overrides)
    }
    
    /// Sets the same log level for all Targets
    /// - Parameter logLevel: the desired log level
    /// - Returns: a custom tracing configuration
    static func custom(logLevel: LogLevel) -> TracingConfiguration {
        let overrides = targets.keys.reduce(into: [Target: LogLevel]()) { partialResult, target in
            partialResult[target] = logLevel
        }

        return TracingConfiguration(overrides: overrides)
    }
    
    enum LogLevel: String { case error, warn, info, debug, trace }
    
    enum Target: String {
        case common = ""
        
        case hyper, matrix_sdk_ffi, matrix_sdk_crypto
        
        case matrix_sdk_http_client = "matrix_sdk::http_client"
        case matrix_sdk_ffi_uniffi_api = "matrix_sdk_ffi::uniffi_api"
        case matrix_sdk_sliding_sync = "matrix_sdk::sliding_sync"
        case matrix_sdk_base_sliding_sync = "matrix_sdk_base::sliding_sync"
        case matrix_sdk_ui_timeline = "matrix_sdk_ui::timeline"
    }
    
    static let targets: OrderedDictionary<Target, LogLevel> = [
        .common: .info,
        .hyper: .warn,
        .matrix_sdk_crypto: .debug,
        .matrix_sdk_http_client: .debug,
        .matrix_sdk_sliding_sync: .trace,
        .matrix_sdk_base_sliding_sync: .trace,
        .matrix_sdk_ui_timeline: .info
    ]
    
    var overrides = [Target: LogLevel]()
    
    var filter: String {
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
        
        return components.joined(separator: ",")
    }
}

func setupTracing(configuration: TracingConfiguration) {
    setupTracing(filter: configuration.filter)
}
