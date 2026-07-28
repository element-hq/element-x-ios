//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

struct SessionDirectoriesTests {
    let fileManager = FileManager.default
    
    @Test
    func initWithDataDirectory() {
        // Given only a session directory without a caches directory.
        let sessionDirectoryName = UUID().uuidString
        let sessionDirectory = URL.applicationSupportBaseDirectory.appending(component: sessionDirectoryName)
        
        // When creating the session directories using this.
        let sessionDirectories = SessionDirectories(dataDirectory: sessionDirectory)
        
        // Then the data directory should remain unchanged and the caches directory should be generated.
        #expect(sessionDirectories.dataDirectory == sessionDirectory)
        #expect(sessionDirectories.cacheDirectory == .sessionCachesBaseDirectory.appending(component: sessionDirectoryName))
    }
    
    @Test
    func pathOutput() {
        // Given session directories created from paths with spaces in them.
        let originalDataPath = "/Users/John Smith/Data"
        let originalCachePath = "/Users/John Smith/Caches"
        let dataDirectory = URL(filePath: originalDataPath)
        let cacheDirectory = URL(filePath: originalCachePath)
        let sessionDirectories = SessionDirectories(dataDirectory: dataDirectory, cacheDirectory: cacheDirectory)
        
        // When getting the paths from the session directories struct.
        let returnedDataPath = sessionDirectories.dataPath
        let returnedCachePath = sessionDirectories.cachePath
        
        // Then the paths should not be escaped.
        #expect(returnedDataPath == originalDataPath)
        #expect(returnedCachePath == originalCachePath)
    }
    
    @Test
    func deleteDirectories() throws {
        // Given a new set of session directories.
        let sessionDirectories = SessionDirectories()
        try fileManager.createDirectory(at: sessionDirectories.dataDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: sessionDirectories.cacheDirectory, withIntermediateDirectories: true)
        #expect(fileManager.directoryExists(at: sessionDirectories.dataDirectory))
        #expect(fileManager.directoryExists(at: sessionDirectories.cacheDirectory))
        
        // When deleting the directories.
        sessionDirectories.delete()
        
        // Then neither directory should exist on disk.
        #expect(!fileManager.directoryExists(at: sessionDirectories.dataDirectory))
        #expect(!fileManager.directoryExists(at: sessionDirectories.cacheDirectory))
    }
    
    @Test
    func deleteTransientUserData() throws {
        // Given a set of session directories with some databases.
        let sessionDirectories = SessionDirectories()
        try fileManager.createDirectory(at: sessionDirectories.dataDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: sessionDirectories.cacheDirectory, withIntermediateDirectories: true)
        #expect(fileManager.directoryExists(at: sessionDirectories.dataDirectory))
        #expect(fileManager.directoryExists(at: sessionDirectories.cacheDirectory))
        
        sessionDirectories.generateMockData()
        #expect(fileManager.fileExists(atPath: sessionDirectories.mockStateStorePath))
        #expect(fileManager.fileExists(atPath: sessionDirectories.mockCryptoStorePath))
        #expect(fileManager.fileExists(atPath: sessionDirectories.mockEventCachePath))
        #expect(try fileManager.numberOfItems(at: sessionDirectories.dataDirectory) == 6)
        #expect(try fileManager.numberOfItems(at: sessionDirectories.cacheDirectory) == 3)
        
        // When deleting transient user data.
        sessionDirectories.deleteTransientUserData()
        
        // Then the data directory should only contain the crypto store and the cache directory should remain but be empty.
        #expect(fileManager.directoryExists(at: sessionDirectories.dataDirectory))
        #expect(try fileManager.numberOfItems(at: sessionDirectories.dataDirectory) == 3)
        #expect(!fileManager.fileExists(atPath: sessionDirectories.mockStateStorePath))
        #expect(fileManager.fileExists(atPath: sessionDirectories.mockCryptoStorePath))
        
        #expect(fileManager.directoryExists(at: sessionDirectories.cacheDirectory))
        #expect(try fileManager.numberOfItems(at: sessionDirectories.cacheDirectory) == 0)
        #expect(!fileManager.fileExists(atPath: sessionDirectories.mockEventCachePath))
        
        // The tests are done, tidy up these useless directories 🧹
        sessionDirectories.delete()
    }
    
    @Test
    func deleteEventCacheData() throws {
        // Given a set of session directories with all of the databases, plus something in the caches
        // directory that isn't the event cache — without it, dropping the prefix filter and wiping the
        // whole directory would still pass.
        let sessionDirectories = try SessionDirectories.makeForTesting()
        sessionDirectories.generateMockData()
        let bystanderPath = sessionDirectories.cacheDirectory.appending(component: "media.sqlite3").path(percentEncoded: false)
        fileManager.createFile(atPath: bystanderPath, contents: nil)
        
        // When deleting the event cache data.
        try sessionDirectories.deleteEventCacheData()
        
        // Then the event cache and its sidecars should be gone, and every other store left alone.
        #expect(fileManager.fileExists(atPath: bystanderPath))
        #expect(try fileManager.numberOfItems(at: sessionDirectories.cacheDirectory) == 1)
        #expect(try fileManager.numberOfItems(at: sessionDirectories.dataDirectory) == 6)
        #expect(fileManager.fileExists(atPath: sessionDirectories.mockStateStorePath))
        #expect(fileManager.fileExists(atPath: sessionDirectories.mockCryptoStorePath))
        
        sessionDirectories.delete()
    }
    
    @Test
    func deleteEventCacheDataWithoutACachesDirectory() throws {
        // Given a session whose caches directory has never been created.
        let sessionDirectories = SessionDirectories()
        try fileManager.createDirectory(at: sessionDirectories.dataDirectory, withIntermediateDirectories: true)
        #expect(!fileManager.directoryExists(at: sessionDirectories.cacheDirectory))
        
        // When deleting the event cache data, then it should succeed rather than throw, otherwise a
        // session with nothing to delete could never be recorded as covered.
        #expect(throws: Never.self) {
            try sessionDirectories.deleteEventCacheData()
        }
        
        sessionDirectories.delete()
    }
    
    @Test
    func eventCacheStoreDetection() throws {
        // Given a session with empty directories.
        let sessionDirectories = try SessionDirectories.makeForTesting()
        #expect(!sessionDirectories.hasEventCacheStore)
        
        // When the event cache store is created.
        sessionDirectories.generateMockData()
        
        // Then it should be detected.
        #expect(sessionDirectories.hasEventCacheStore)
        
        sessionDirectories.delete()
    }
    
    @Test
    func searchIndexCoverageMarker() throws {
        // Given a session that has never had its coverage recorded.
        let sessionDirectories = try SessionDirectories.makeForTesting()
        #expect(!sessionDirectories.hasSearchIndexCoverageMarker)
        
        // When writing the marker.
        try sessionDirectories.writeSearchIndexCoverageMarker()
        
        // Then it should be readable back, and writing it again shouldn't throw.
        #expect(sessionDirectories.hasSearchIndexCoverageMarker)
        #expect(throws: Never.self) {
            try sessionDirectories.writeSearchIndexCoverageMarker()
        }
        
        sessionDirectories.delete()
    }
    
    @Test
    func searchIndexCoverageMarkerSurvivesClearingTheCaches() throws {
        // Given a session that is recorded as covered.
        let sessionDirectories = try SessionDirectories.makeForTesting()
        sessionDirectories.generateMockData()
        try sessionDirectories.writeSearchIndexCoverageMarker()
        
        // When the user clears the caches.
        sessionDirectories.deleteTransientUserData()
        
        // Then the marker should survive: it is named to dodge the prefixes that sweeps, otherwise
        // clearing the caches would silently re-arm the repair on every launch that followed.
        #expect(sessionDirectories.hasSearchIndexCoverageMarker)
        
        sessionDirectories.delete()
    }
}

extension SessionDirectories {
    /// Creates a fresh set of session directories on disk for a test to work in.
    static func makeForTesting() throws -> SessionDirectories {
        let sessionDirectories = SessionDirectories()
        try FileManager.default.createDirectory(at: sessionDirectories.dataDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: sessionDirectories.cacheDirectory, withIntermediateDirectories: true)
        return sessionDirectories
    }
    
    var mockStateStorePath: String {
        dataDirectory.appending(component: "matrix-sdk-state.sqlite3").path(percentEncoded: false)
    }
    
    var mockCryptoStorePath: String {
        dataDirectory.appending(component: "matrix-sdk-crypto.sqlite3").path(percentEncoded: false)
    }
    
    var mockEventCachePath: String {
        cacheDirectory.appending(component: "matrix-sdk-event-cache.sqlite3").path(percentEncoded: false)
    }
    
    func generateMockData() {
        generateMockDatabase(atPath: mockStateStorePath)
        generateMockDatabase(atPath: mockCryptoStorePath)
        generateMockDatabase(atPath: mockEventCachePath)
    }
    
    private func generateMockDatabase(atPath path: String) {
        FileManager.default.createFile(atPath: path, contents: nil)
        FileManager.default.createFile(atPath: path + "-shm", contents: nil)
        FileManager.default.createFile(atPath: path + "-wal", contents: nil)
    }
}
