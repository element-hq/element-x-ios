//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

struct SystemDiagnosticsProvider: DiagnosticsProviding {
    func collectDiagnostics() async -> DeviceDiagnostics {
        let device = await UIDevice.current
        let processInfo = ProcessInfo.processInfo

        let appVersion = InfoPlistReader.main.bundleShortVersionString
        let buildNumber = InfoPlistReader.main.bundleVersion
        let os = await "\(device.systemName) \(device.systemVersion)"
        let deviceModel = await device.model
        let locale = Locale.current.identifier
        let memoryAvailable = formatBytes(UInt64(processInfo.physicalMemory))
        let diskFree = formatBytes(freeDiskSpace())

        return DeviceDiagnostics(appVersion: appVersion,
                                 buildNumber: buildNumber,
                                 os: os,
                                 device: deviceModel,
                                 locale: locale,
                                 memoryAvailable: memoryAvailable,
                                 diskFree: diskFree)
    }

    // MARK: - Private

    private func freeDiskSpace() -> UInt64 {
        let fileManager = FileManager.default
        guard let attributes = try? fileManager.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let freeSpace = attributes[.systemFreeSize] as? UInt64 else {
            return 0
        }
        return freeSpace
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
