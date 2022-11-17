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

extension FileManager {
    /// The URL of the primary app group container.
    @objc var appGroupContainerURL: URL {
        guard let url = containerURL(forSecurityApplicationGroupIdentifier: Bundle.appGroupIdentifier) else {
            fatalError("Should always be able to retrieve the container directory")
        }
        return url
    }

    /// The base directory where all session data is stored.
    var sessionsBaseDirectory: URL {
        let url = cacheBaseDirectory
            .appendingPathComponent("Sessions", isDirectory: true)

        try? createDirectoryIfNeeded(at: url)

        return url
    }

    /// The base directory where all cache is stored.
    var cacheBaseDirectory: URL {
        let url = appGroupContainerURL
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Caches", isDirectory: true)

        try? createDirectoryIfNeeded(at: url)

        return url
    }

    func directoryExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        guard fileExists(atPath: url.path(), isDirectory: &isDirectory) else {
            return false
        }
        return isDirectory.boolValue
    }

    func createDirectoryIfNeeded(at url: URL, withIntermediateDirectories: Bool = true) throws {
        guard !directoryExists(at: url) else {
            return
        }
        try createDirectory(at: url, withIntermediateDirectories: withIntermediateDirectories)
    }
}
