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

struct OTLPConfiguration {
    let url: String
    let username: String
    let password: String
}

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
        .matrix_sdk_crypto: .info,
        .matrix_sdk_oidc: .trace,
        .matrix_sdk_http_client: .info,
        .matrix_sdk_sliding_sync: .info,
        .matrix_sdk_base_sliding_sync: .info,
        .matrix_sdk_ui_timeline: .info
    ]
    
    let filter: String
    
    /// Sets the same log level for all Targets
    /// - Parameter logLevel: the desired log level
    /// - Returns: a custom tracing configuration
    init(logLevel: LogLevel) {
        if case let .custom(filter) = logLevel {
            self.filter = filter
            return
        }
        
        let overrides = Self.targets.keys.reduce(into: [Target: LogLevel]()) { partialResult, target in
            // Keep the defaults here
            let ignoredTargets: [Target] = [.common, .matrix_sdk_ffi, .hyper, .matrix_sdk_client, .matrix_sdk_oidc]
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

func setupTracing(configuration: TracingConfiguration, otlpConfiguration: OTLPConfiguration?) {
    if let otlpConfiguration {
        setupOtlpTracing(config: .init(clientName: "ElementX-iOS",
                                       user: otlpConfiguration.username,
                                       password: otlpConfiguration.password,
                                       otlpEndpoint: otlpConfiguration.url,
                                       filter: configuration.filter,
                                       writeToStdoutOrSystem: true,
                                       writeToFiles: nil))
    } else {
        setupTracing(config: .init(filter: configuration.filter,
                                   writeToStdoutOrSystem: true,
                                   writeToFiles: nil))
    }
}
