//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

final class DataProtectionManager {
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
