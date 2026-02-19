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

@Suite
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
}

private extension SessionDirectories {
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
