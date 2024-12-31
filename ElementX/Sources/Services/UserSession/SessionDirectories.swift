//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct SessionDirectories: Hashable, Codable {
    let dataDirectory: URL
    let cacheDirectory: URL
    
    var dataPath: String { dataDirectory.path(percentEncoded: false) }
    var cachePath: String { cacheDirectory.path(percentEncoded: false) }
    
    // MARK: Data Management
    
    /// Removes the directories from disk if they have been created.
    func delete() {
        do {
            if FileManager.default.directoryExists(at: dataDirectory) {
                try FileManager.default.removeItem(at: dataDirectory)
            }
        } catch {
            MXLog.failure("Failed deleting the session data: \(error)")
        }
        do {
            if FileManager.default.directoryExists(at: cacheDirectory) {
                try FileManager.default.removeItem(at: cacheDirectory)
            }
        } catch {
            MXLog.failure("Failed deleting the session caches: \(error)")
        }
    }
    
    /// Deletes the Rust state store and event cache data, leaving the crypto store and both
    /// session directories in place along with any other data that may have been written in them.
    func deleteTransientUserData() {
        do {
            let prefix = "matrix-sdk-state"
            try deleteFiles(at: dataDirectory, with: prefix)
        } catch {
            MXLog.failure("Failed clearing state store: \(error)")
        }
        do {
            let prefix = "matrix-sdk-event-cache"
            try deleteFiles(at: cacheDirectory, with: prefix)
        } catch {
            MXLog.failure("Failed clearing event cache store: \(error)")
        }
    }
    
    /// Check that mission critical files (the crypto db) are still in the right place when restoring a session
    /// iOS might decide to move the app with its user defaults and keychain but without
    /// some of the files stored in the shared container e.g. after a device transfer, offloading etc.
    /// If that happens we should fail the session restoration.
    func isNonTransientUserDataValid() -> Bool {
        FileManager.default.fileExists(atPath: dataPath.appending("/matrix-sdk-crypto.sqlite3"))
    }
    
    private func deleteFiles(at url: URL, with prefix: String) throws {
        let sessionDirectoryContents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        for url in sessionDirectoryContents where url.lastPathComponent.hasPrefix(prefix) {
            try FileManager.default.removeItem(at: url)
        }
    }
}

extension SessionDirectories {
    /// Creates a fresh set of session directories for a new user.
    init() {
        let sessionDirectoryName = UUID().uuidString
        dataDirectory = .sessionsBaseDirectory.appending(component: sessionDirectoryName)
        cacheDirectory = .sessionCachesBaseDirectory.appending(component: sessionDirectoryName)
    }
    
    /// Creates the session directories for a user who signed in before the data directory was stored.
    init(userID: String) {
        dataDirectory = .legacySessionDirectory(for: userID)
        cacheDirectory = .sessionCachesBaseDirectory.appending(component: dataDirectory.lastPathComponent)
    }
    
    /// Creates the session directories for a user who has a single session directory stored without a separate caches directory.
    init(dataDirectory: URL) {
        self.dataDirectory = dataDirectory
        cacheDirectory = .sessionCachesBaseDirectory.appending(component: dataDirectory.lastPathComponent)
    }
}

extension SessionDirectories: CustomStringConvertible {
    var description: String {
        "Data: \(dataPath) Caches: \(cachePath)"
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
