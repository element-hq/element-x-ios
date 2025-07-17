//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum Target: String {
    case mainApp = "elementx"
    case nse
    case shareExtension = "shareextension"
    case tests
    
    var useLightweightTokioRuntime: Bool {
        switch self {
        case .mainApp: false
        case .nse: true
        case .shareExtension: true
        case .tests: false
        }
    }
    
    var logFilePrefix: String? {
        switch self {
        case .mainApp: nil
        default: rawValue
        }
    }
    
    /// Configures the target with logging and an appropriate runtime.
    ///
    /// Returns a `Configuration` which should be stored to
    ///   a) detect whether the platform is already configured.
    ///   b) reconfigure the platform if necessary.
    func configure(logLevel: LogLevel, traceLogPacks: Set<TraceLogPack>, sentryURL: URL?) -> Configuration {
        let tracingConfiguration = Tracing.buildConfiguration(logLevel: logLevel,
                                                              traceLogPacks: traceLogPacks,
                                                              currentTarget: rawValue,
                                                              filePrefix: logFilePrefix,
                                                              sentryURL: sentryURL)
        
        do {
            try initPlatform(config: tracingConfiguration, useLightweightTokioRuntime: useLightweightTokioRuntime)
        } catch {
            fatalError("Failed configuring target \(self) with error: \(error)")
        }
        
        // Setup sentry above but disable it by default. It will be started
        // later together with the analytics service if the user consents.
        enableSentryLogging(enabled: false)
        
        MXLog.configure(currentTarget: rawValue)
        
        return Configuration(tracingConfiguration: tracingConfiguration)
    }
    
    /// Represents the configuration that was applied by ``configure(logLevel:traceLogPacks:sentryURL:)``.
    struct Configuration {
        /// The configuration applied when calling ``configure(logLevel:traceLogPacks:sentryURL:)``.
        ///
        /// **Note:** This is immutable and won't be updated to reflect further changes.
        let tracingConfiguration: TracingConfiguration
    }
}
