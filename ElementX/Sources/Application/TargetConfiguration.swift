//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

@MainActor
enum Target: String {
    case mainApp = "elementx"
    case nse
    case shareExtension = "shareextension"
    case tests
    
    private static var isConfigured = false
    
    func configure(logLevel: LogLevel, traceLogPacks: Set<TraceLogPack>, sentryURL: URL?) {
        guard !Self.isConfigured else {
            return
        }
        
        do {
            switch self {
            case .mainApp:
                let tracingConfiguration = Tracing.buildConfiguration(logLevel: logLevel,
                                                                      traceLogPacks: traceLogPacks,
                                                                      currentTarget: rawValue,
                                                                      filePrefix: nil,
                                                                      sentryURL: sentryURL)
                try initPlatform(config: tracingConfiguration, useLightweightTokioRuntime: false)
            case .nse:
                let tracingConfiguration = Tracing.buildConfiguration(logLevel: logLevel,
                                                                      traceLogPacks: traceLogPacks,
                                                                      currentTarget: rawValue,
                                                                      filePrefix: rawValue,
                                                                      sentryURL: sentryURL)
                try initPlatform(config: tracingConfiguration, useLightweightTokioRuntime: true)
            case .shareExtension:
                let tracingConfiguration = Tracing.buildConfiguration(logLevel: logLevel,
                                                                      traceLogPacks: traceLogPacks,
                                                                      currentTarget: rawValue,
                                                                      filePrefix: rawValue,
                                                                      sentryURL: sentryURL)
                try initPlatform(config: tracingConfiguration, useLightweightTokioRuntime: true)
            case .tests:
                let tracingConfiguration = Tracing.buildConfiguration(logLevel: logLevel,
                                                                      traceLogPacks: traceLogPacks,
                                                                      currentTarget: rawValue,
                                                                      filePrefix: rawValue,
                                                                      sentryURL: sentryURL)
                try initPlatform(config: tracingConfiguration, useLightweightTokioRuntime: false)
            }
        } catch {
            fatalError("Failed configuring target \(self) with error: \(error)")
        }
        
        // Setup sentry above but disable it by default. It will be started
        // later together with the analytics service if the user consents.
        enableSentryLogging(enabled: false)
        
        MXLog.configure(currentTarget: rawValue)
        
        Self.isConfigured = true
    }
}
