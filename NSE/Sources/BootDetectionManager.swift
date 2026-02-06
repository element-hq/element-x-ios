//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum BootDetectionManager {
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
    
    /// The time that the system was booted, as a Unix timestamp.
    static func systemBootTime() -> TimeInterval? {
        var bootTime = timeval()
        var size = MemoryLayout<timeval>.size
        var managementInformationBase: [Int32] = [CTL_KERN, KERN_BOOTTIME]
        
        guard sysctl(&managementInformationBase, 2, &bootTime, &size, nil, 0) == 0 else { return nil }
        
        return TimeInterval(bootTime.tv_sec) + TimeInterval(bootTime.tv_usec) / 1_000_000
    }
}
