//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

nonisolated struct SessionDirectories: Hashable, Codable {
    let dataDirectory: URL
    let cacheDirectory: URL
    
    var dataPath: String {
        dataDirectory.path(percentEncoded: false)
    }
    
    var cachePath: String {
        cacheDirectory.path(percentEncoded: false)
    }
    
    /// The file name prefix shared by the event cache store and its write-ahead log sidecars.
    private static let eventCacheStorePrefix = "matrix-sdk-event-cache"
    
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
            try deleteFiles(at: cacheDirectory, with: Self.eventCacheStorePrefix)
        } catch {
            MXLog.failure("Failed clearing event cache store: \(error)")
        }
    }
    
    /// Deletes the Rust event cache store and its write-ahead log sidecars, leaving every other store
    /// in place — including the state store, which `deleteTransientUserData()` also clears.
    ///
    /// Throws rather than logging, because the caller has to know: a search index coverage marker
    /// written over a failed deletion would claim coverage that doesn't exist.
    func deleteEventCacheData() throws {
        guard FileManager.default.directoryExists(at: cacheDirectory) else { return }
        
        let storeFiles = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix(Self.eventCacheStorePrefix) }
        
        // Sidecars first, so an interrupted deletion leaves a merely stale database behind rather than
        // a fresh one next to a replayable write-ahead log.
        for url in storeFiles.filter(\.isSQLiteSidecar) + storeFiles.filter({ !$0.isSQLiteSidecar }) {
            try FileManager.default.removeItem(at: url)
        }
    }
    
    // MARK: Search Index Coverage
    
    /// Whether the event cache store has been created yet. A session without one cannot be holding
    /// history that the search index failed to see.
    ///
    /// Matches exactly what `deleteEventCacheData()` deletes, so that an interrupted deletion — which
    /// leaves the sidecars behind by design — still reads as a store to be swept rather than as a
    /// session with nothing to repair.
    var hasEventCacheStore: Bool {
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: cachePath) else { return false }
        return contents.contains { $0.hasPrefix(Self.eventCacheStorePrefix) }
    }
    
    /// Whether the search index has been recorded as covering everything the event cache holds.
    var hasSearchIndexCoverageMarker: Bool {
        FileManager.default.fileExists(atPath: searchIndexCoverageMarkerURL.path(percentEncoded: false))
    }
    
    /// Records that the search index covers everything the event cache holds.
    func writeSearchIndexCoverageMarker() throws {
        // Accessible after first unlock, matching the other files the app writes here, so that a
        // background launch can read it while the device is locked.
        try Data().write(to: searchIndexCoverageMarkerURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
    
    /// An empty marker file, sibling of the SDK's index rather than inside it — the SDK owns that layout.
    ///
    /// The name deliberately matches neither `matrix-sdk-state` nor `matrix-sdk-event-cache`, the
    /// prefixes `deleteTransientUserData()` sweeps: a marker caught by those would silently re-arm the
    /// heal every time the user cleared the cache.
    private var searchIndexCoverageMarkerURL: URL {
        dataDirectory.appending(component: "search-index.covered")
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

nonisolated extension SessionDirectories {
    /// Creates a fresh set of session directories for a new user.
    init() {
        let sessionDirectoryName = UUID().uuidString
        dataDirectory = .sessionsBaseDirectory.appending(component: sessionDirectoryName)
        cacheDirectory = .sessionCachesBaseDirectory.appending(component: sessionDirectoryName)
    }
    
    /// Creates the session directories for a user who has a single session directory stored without a separate caches directory.
    init(dataDirectory: URL) {
        self.dataDirectory = dataDirectory
        cacheDirectory = .sessionCachesBaseDirectory.appending(component: dataDirectory.lastPathComponent)
    }
}

nonisolated extension SessionDirectories: CustomStringConvertible {
    var description: String {
        "Data: \(dataPath) Caches: \(cachePath)"
    }
}

private nonisolated extension URL {
    /// Whether this is one of SQLite's auxiliary files rather than the database itself.
    var isSQLiteSidecar: Bool {
        lastPathComponent.hasSuffix("-wal") || lastPathComponent.hasSuffix("-shm")
    }
}
