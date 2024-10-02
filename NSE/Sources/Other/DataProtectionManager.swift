//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum DataProtectionManager {
    /// Detects after reboot, before unlocked state. Does this by trying to write a file to the filesystem (to the Caches directory) and read it back.
    /// - Parameter containerURL: Container url to write the file.
    /// - Returns: true if the state detected
    static func isDeviceLockedAfterReboot(containerURL: URL) -> Bool {
        let dummyString = ProcessInfo.processInfo.globallyUniqueString
        guard let dummyData = dummyString.data(using: .utf8) else {
            return true
        }

        do {
            //  add a unique filename
            let url = containerURL.appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString)

            try dummyData.write(to: url, options: .completeFileProtectionUntilFirstUserAuthentication)
            let readData = try Data(contentsOf: url)
            let readString = String(data: readData, encoding: .utf8)
            try FileManager.default.removeItem(at: url)
            if readString != dummyString {
                return true
            }
        } catch {
            return true
        }
        return false
    }
}
