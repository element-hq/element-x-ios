//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
