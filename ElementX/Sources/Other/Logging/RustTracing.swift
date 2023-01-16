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

import MatrixRustSDK

// This exposes the full Rust side tracing subscriber filter for more flexibility.
// We can filter by level, crate and even file. See more details here:
// https://docs.rs/tracing-subscriber/0.2.7/tracing_subscriber/filter/struct.EnvFilter.html#examples
struct TracingConfiguration {
    static var release = TracingConfiguration(common: .info)
    static var debug = TracingConfiguration()
    static var full = TracingConfiguration(common: .info,
                                           targets: [
                                               .hyper: .warn,
                                               .sled: .warn,
                                               .matrix_sdk_sled: .warn,
                                               .matrix_sdk_http_client: .trace,
                                               .matrix_sdk_ffi_uniffi_api: .warn,
                                               .matrix_sdk_ffi: .warn,
                                               .matrix_sdk_sliding_sync: .warn,
                                               .matrix_sdk_base_sliding_sync: .warn
                                               .matrix_sdk_crypto: .trace,
                                           ])
    
    enum Target: String {
        case hyper, sled, matrix_sdk_sled, matrix_sdk_ffi
        case matrix_sdk_http_client = "matrix_sdk::http_client"
        case matrix_sdk_ffi_uniffi_api = "matrix_sdk_ffi::uniffi_api"
        case matrix_sdk_sliding_sync = "matrix_sdk::sliding_sync"
        case matrix_sdk_base_sliding_sync = "matrix_sdk_base::sliding_sync"
        case matrix_sdk_crypto
        case matrix_sdk_crypto_sync = "matrix_sdk_crypto::machine[receive_sync_changes]"
    }
    
    enum LogLevel: String { case error, warn, info, debug, trace }
    
    var common = LogLevel.warn
    var targets: [Target: LogLevel] = [
        .hyper: .warn,
        .sled: .warn,
        .matrix_sdk_sled: .warn
        .matrix_sdk_crypto: .debug,
        .matrix_sdk_crypto_sync: .trace,
    ]
    
    var filter: String {
        "\(common),\(targets.map { "\($0.key.rawValue)=\($0.value.rawValue)" }.joined(separator: ","))"
    }
}

func setupTracing(configuration: TracingConfiguration) {
    setupTracing(filter: configuration.filter)
}
