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
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: InfoPlistReader.target.appGroupIdentifier) else {
            fatalError("Should always be able to retrieve the container directory")
        }
        return url
    }

    /// The base directory where all session data is stored.
    static var sessionsBaseDirectory: URL {
        let url = cacheBaseDirectory
            .appendingPathComponent("Sessions", isDirectory: true)

        try? FileManager.default.createDirectoryIfNeeded(at: url)

        return url
    }

    /// The base directory where all cache is stored.
    static var cacheBaseDirectory: URL {
        let url = appGroupContainerDirectory
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Caches", isDirectory: true)

        try? FileManager.default.createDirectoryIfNeeded(at: url)

        return url
    }
}
