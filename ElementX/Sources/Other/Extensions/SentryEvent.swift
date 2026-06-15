//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK
import Sentry
import UIKit

extension Event {
    /// A human readable crash log matching the format used by the legacy app.
    /// `nil` for non-crash events (handled errors, transactions, etc.).
    var crashLog: String? {
        guard let exceptions,
              exceptions.contains(where: { $0.mechanism?.handled?.boolValue == false }) else {
            return nil
        }
        
        let reason = exceptions.map { "\($0.type ?? "Unknown"): \($0.value ?? "")" }.joined(separator: "\n")
        let infoPlist = InfoPlistReader.main
        let device = UIDevice.current
        
        return """
        \(reason)
        Application: \(infoPlist.bundleExecutable) (\(infoPlist.bundleIdentifier))
        Application version: \(infoPlist.bundleShortVersionString) (\(infoPlist.bundleVersion))
        Matrix SDK version: \(sdkGitSha())
        \(device.model) \(device.systemVersion)
        """
    }
}
