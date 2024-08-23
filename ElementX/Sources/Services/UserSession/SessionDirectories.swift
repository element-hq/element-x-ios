//
// Copyright 2024 New Vector Ltd
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

struct SessionDirectories: Hashable, Codable {
    let dataDirectory: URL
    let cacheDirectory: URL
    
    var dataPath: String { dataDirectory.path(percentEncoded: false) }
    var cachePath: String { cacheDirectory.path(percentEncoded: false) }
}

extension SessionDirectories {
    /// Creates a fresh set of session directories for a new user.
    init() {
        let sessionDirectoryName = UUID().uuidString
        dataDirectory = .sessionsBaseDirectory.appending(component: sessionDirectoryName)
        cacheDirectory = .cachesBaseDirectory.appending(component: sessionDirectoryName)
    }
    
    /// Creates the session directories for a user who signed in before the data directory was stored.
    init(userID: String) {
        dataDirectory = .legacySessionDirectory(for: userID)
        cacheDirectory = .cachesBaseDirectory.appending(component: dataDirectory.lastPathComponent)
    }
    
    /// Creates the session directories for a user who has a single session directory stored without a separate caches directory.
    init(dataDirectory: URL) {
        self.dataDirectory = dataDirectory
        cacheDirectory = .cachesBaseDirectory.appending(component: dataDirectory.lastPathComponent)
    }
}

// MARK: Migrations

private extension URL {
    /// Gets the store directory of a legacy session that hasn't been migrated to the new token format.
    ///
    /// This should only be used to fill in the missing value when restoring a token as older versions of
    /// the SDK set the session directory for us, based on the user's ID. Newer sessions now use a UUID,
    /// which is generated app side during authentication.
    static func legacySessionDirectory(for userID: String) -> URL {
        // Rust sanitises the user ID replacing invalid characters with an _
        let sanitisedUserID = userID.replacingOccurrences(of: ":", with: "_")
        return .sessionsBaseDirectory.appendingPathComponent(sanitisedUserID)
    }
}
