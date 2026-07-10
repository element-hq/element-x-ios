//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
#if IS_MAIN_APP
import MapLibre
#endif
import MatrixRustSDK

nonisolated enum Target: String {
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
    
    var logFilePrefix: String {
        switch self {
        case .mainApp:
            "console"
        default:
            rawValue
        }
    }
    
    /// Configures the target with logging and an appropriate runtime.
    ///
    /// Returns a `ConfigurationResult` which should be stored to
    ///   a) detect whether the platform is already configured.
    ///   b) automatically reconfigure the platform as necessary.
    func configure(logLevel: LogLevel,
                   traceLogPacks: Set<TraceLogPack>,
                   sentryURL: URL?,
                   rageshakeURL: RemotePreference<RageshakeConfiguration>,
                   appHooks: AppHooks) -> ConfigurationResult {
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
        
        configureMapLibreIfAvailable()
        
        let hookCancellable = rageshakeURL.publisher
            .sink { _ in
                appHooks.tracingHook.update(tracingConfiguration, with: rageshakeURL)
            }
        
        return ConfigurationResult(hookCancellable: hookCancellable)
    }
    
    private func configureMapLibreIfAvailable() {
        #if IS_MAIN_APP
        MLNLoggingConfiguration.shared.loggingLevel = .debug
        MLNLoggingConfiguration.shared.handler = { loggingLevel, _, _, message in
            switch loggingLevel {
            case .error:
                MXLog.error(message)
            case .warning:
                MXLog.warning(message)
            case .info:
                MXLog.info(message)
            case .debug:
                MXLog.debug(message)
            case .verbose:
                MXLog.verbose(message)
            default:
                break
            }
        }
        #endif
    }
    
    /// The result of calling ``configure(logLevel:traceLogPacks:sentryURL:)``.
    /// This must be stored - see the docs on the configure method to learn more.
    struct ConfigurationResult {
        private let hookCancellable: AnyCancellable
        
        init(hookCancellable: AnyCancellable) {
            self.hookCancellable = hookCancellable
        }
    }
}
