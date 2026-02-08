//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol DiagnosticsProviding: Sendable {
    func collectDiagnostics() async -> DeviceDiagnostics
}

struct DeviceDiagnostics: Equatable, Sendable {
    let appVersion: String
    let buildNumber: String
    let os: String
    let device: String
    let locale: String
    let memoryAvailable: String
    let diskFree: String
}

extension DeviceDiagnostics {
    var formattedString: String {
        """
        App Version: \(appVersion) (\(buildNumber))
        OS: \(os)
        Device: \(device)
        Locale: \(locale)
        Memory Available: \(memoryAvailable)
        Disk Free: \(diskFree)
        """
    }
}
