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

import Foundation
import MatrixRustSDK

class NSELogger {
    private static var isConfigured = false

    static func configure() {
        guard !isConfigured else {
            return
        }
        isConfigured = true

        let configuration = MXLogConfiguration()
        configuration.subLogName = "nse"

        #if DEBUG
        // This exposes the full Rust side tracing subscriber filter for more flexibility.
        // We can filter by level, crate and even file. See more details here:
        // https://docs.rs/tracing-subscriber/0.2.7/tracing_subscriber/filter/struct.EnvFilter.html#examples
        setupTracing(configuration: "warn,hyper=warn,sled=warn,matrix_sdk_sled=warn")
        configuration.logLevel = .debug
        #else
        setupTracing(configuration: "info,hyper=warn,sled=warn,matrix_sdk_sled=warn")
        configuration.logLevel = .info
        #endif

        // Avoid redirecting NSLogs to files if we are attached to a debugger.
        if isatty(STDERR_FILENO) == 0 {
            configuration.redirectLogsToFiles = true
        }

        MXLog.configure(configuration)
    }
}
