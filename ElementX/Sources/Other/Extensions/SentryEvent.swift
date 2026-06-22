//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK
import Sentry

extension Event {
    /// A human readable crash log matching the format used by the legacy app.
    /// `nil` for non-crash events (handled errors, transactions, etc.).
    ///
    /// Device values must be read on the main thread and passed in. `beforeSend`
    /// runs on a background queue and touching `UIDevice.current` there traps libdispatch.
    nonisolated func crashLog(deviceModel: String, systemVersion: String) -> String? {
        guard let exceptions,
              exceptions.contains(where: { $0.mechanism?.handled?.boolValue == false }) else {
            return nil
        }
        
        let reason = exceptions.map { "\($0.type ?? "Unknown"): \($0.value ?? "")" }.joined(separator: "\n")
        let infoPlist = InfoPlistReader.main
        
        return """
        \(reason)
        Application: \(infoPlist.bundleExecutable) (\(infoPlist.bundleIdentifier))
        Application version: \(infoPlist.bundleShortVersionString) (\(infoPlist.bundleVersion))
        Matrix SDK version: \(sdkGitSha())
        \(deviceModel) \(systemVersion)
        """
    }
}
