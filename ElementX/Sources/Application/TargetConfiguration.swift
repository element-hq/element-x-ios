//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

enum Target: String {
    case mainApp = "elementx"
    case nse
    case shareExtension = "shareextension"
    case tests
    
    private static var isConfigured = false
    
    func configure(logLevel: LogLevel) {
        guard !Self.isConfigured else {
            return
        }
        
        switch self {
        case .mainApp:
            let tracingConfiguration = Tracing.buildConfiguration(logLevel: logLevel, currentTarget: rawValue, filePrefix: nil)
            initPlatform(config: tracingConfiguration, useLightweightTokioRuntime: false)
        case .nse:
            let tracingConfiguration = Tracing.buildConfiguration(logLevel: logLevel, currentTarget: rawValue, filePrefix: rawValue)
            initPlatform(config: tracingConfiguration, useLightweightTokioRuntime: true)
        case .shareExtension:
            let tracingConfiguration = Tracing.buildConfiguration(logLevel: logLevel, currentTarget: rawValue, filePrefix: rawValue)
            initPlatform(config: tracingConfiguration, useLightweightTokioRuntime: true)
        case .tests:
            let tracingConfiguration = Tracing.buildConfiguration(logLevel: logLevel, currentTarget: rawValue, filePrefix: rawValue)
            initPlatform(config: tracingConfiguration, useLightweightTokioRuntime: false)
        }
        
        MXLog.configure(currentTarget: rawValue)
        
        Self.isConfigured = true
    }
}
