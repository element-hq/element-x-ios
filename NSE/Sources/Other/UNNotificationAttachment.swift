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
import UserNotifications

extension UNNotificationAttachment {
    static func saveImageToDisk(fileIdentifier: String,
                                data: Data,
                                options: [NSObject: AnyObject]? = nil) throws -> UNNotificationAttachment {
        let folderName = "Attachments"
        let folderURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(folderName, isDirectory: true)

        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        let fileURL = folderURL.appendingPathComponent(fileIdentifier)
        try data.write(to: fileURL, options: [])
        return try UNNotificationAttachment(identifier: fileIdentifier,
                                            url: fileURL,
                                            options: options)
    }
}
