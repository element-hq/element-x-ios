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

extension URL {
    init(staticString: StaticString) {
        guard let url = URL(string: "\(staticString)") else {
            fatalError("The static string used to create this URL is invalid")
        }
        
        self = url
    }

    /// The URL of the primary app group container.
    static var appGroupContainerDirectory: URL {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: InfoPlistReader.main.appGroupIdentifier) else {
            fatalError("Should always be able to retrieve the container directory")
        }
        return url
    }

    /// The base directory where all session data is stored.
    static var sessionsBaseDirectory: URL {
        let cacheSessionsURL = cacheBaseDirectory.appendingPathComponent("Sessions", isDirectory: true)
        let applicationSupportSessionsURL = applicationSupportBaseDirectory.appendingPathComponent("Sessions", isDirectory: true)
        
        #warning("Migration from caches to application support. Remove this in a couple of releases.")
        if FileManager.default.directoryExists(at: cacheSessionsURL) {
            try? FileManager.default.moveItem(at: cacheSessionsURL, to: applicationSupportSessionsURL)
        }

        try? FileManager.default.createDirectoryIfNeeded(at: applicationSupportSessionsURL)

        return applicationSupportSessionsURL
    }

    /// The base directory where all cache is stored.
    static var cacheBaseDirectory: URL {
        let url = appGroupContainerDirectory
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Caches", isDirectory: true)

        try? FileManager.default.createDirectoryIfNeeded(at: url)

        return url
    }
    
    /// The base directory where all application support data is stored.
    static var applicationSupportBaseDirectory: URL {
        var url = appGroupContainerDirectory
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent(InfoPlistReader.main.baseBundleIdentifier, isDirectory: true)

        try? FileManager.default.createDirectoryIfNeeded(at: url)
        
        do {
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try url.setResourceValues(resourceValues)
        } catch {
            MXLog.error("Failed excluding Application Support from backups")
        }

        return url
    }
}
