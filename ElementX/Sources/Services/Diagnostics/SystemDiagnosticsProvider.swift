//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

#if !os(OSX)
import DeviceKit
#endif

// MARK: - Interfaces

protocol DiagnosticsProviding {
    @MainActor
    func generateDiagnostics() async -> String
}

// MARK: - Implementations

struct SystemDiagnosticsProvider: DiagnosticsProviding {
    // MARK: - Public Properties

    @MainActor
    func generateDiagnostics() async -> String {
        guard !Task.isCancelled else { return "" }

        var lines: [String] = []

        lines.append("App: \(InfoPlistReader.main.bundleDisplayName)")
        lines.append("App Version: \(InfoPlistReader.main.bundleShortVersionString) (\(InfoPlistReader.main.bundleVersion))")

        #if os(iOS)
        lines.append("OS: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)")
        #if !os(OSX)
        lines.append("Device: \(Device.current.safeDescription)")
        #endif
        #endif

        lines.append("Locale: \(Locale.current.identifier)")
        lines.append("Time Zone: \(TimeZone.current.identifier)")

        return lines.joined(separator: "\n")
    }
}
