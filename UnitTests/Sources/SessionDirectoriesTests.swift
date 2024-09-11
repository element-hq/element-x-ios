//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

class SessionDirectoriesTests: XCTestCase {
    let fileManager = FileManager.default
    
    func testInitWithUserID() {
        // Given only a user ID.
        let userID = "@user:matrix.org"
        
        // When creating the session directories using this.
        let sessionDirectories = SessionDirectories(userID: userID)
        
        // Then the directories should be generated in the correct location, using an escaped version of the user ID
        XCTAssertEqual(sessionDirectories.dataDirectory, .sessionsBaseDirectory.appending(component: "@user_matrix.org"))
        XCTAssertEqual(sessionDirectories.cacheDirectory, .cachesBaseDirectory.appending(component: "@user_matrix.org"))
    }
    
    func testInitWithDataDirectory() {
        // Given only a session directory without a caches directory.
        let sessionDirectoryName = UUID().uuidString
        let sessionDirectory = URL.applicationSupportBaseDirectory.appending(component: sessionDirectoryName)
        
        // When creating the session directories using this.
        let sessionDirectories = SessionDirectories(dataDirectory: sessionDirectory)
        
        // Then the data directory should remain unchanged and the caches directory should be generated.
        XCTAssertEqual(sessionDirectories.dataDirectory, sessionDirectory)
        XCTAssertEqual(sessionDirectories.cacheDirectory, .cachesBaseDirectory.appending(component: sessionDirectoryName))
    }
    
    func testPathOutput() {
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
        XCTAssertEqual(returnedDataPath, originalDataPath)
        XCTAssertEqual(returnedCachePath, originalCachePath)
    }
    
    func testDeleteDirectories() throws {
        // Given a new set of session directories.
        let sessionDirectories = SessionDirectories()
        try fileManager.createDirectory(at: sessionDirectories.dataDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: sessionDirectories.cacheDirectory, withIntermediateDirectories: true)
        XCTAssertTrue(fileManager.directoryExists(at: sessionDirectories.dataDirectory))
        XCTAssertTrue(fileManager.directoryExists(at: sessionDirectories.cacheDirectory))
        
        // When deleting the directories.
        sessionDirectories.delete()
        
        // Then neither directory should exist on disk.
        XCTAssertFalse(fileManager.directoryExists(at: sessionDirectories.dataDirectory))
        XCTAssertFalse(fileManager.directoryExists(at: sessionDirectories.cacheDirectory))
    }
    
    func testDeleteTransientUserData() throws {
        // Given a set of session directories with some databases.
        let sessionDirectories = SessionDirectories()
        try fileManager.createDirectory(at: sessionDirectories.dataDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: sessionDirectories.cacheDirectory, withIntermediateDirectories: true)
        XCTAssertTrue(fileManager.directoryExists(at: sessionDirectories.dataDirectory))
        XCTAssertTrue(fileManager.directoryExists(at: sessionDirectories.cacheDirectory))
        
        sessionDirectories.generateMockData()
        XCTAssertTrue(fileManager.fileExists(atPath: sessionDirectories.mockStateStorePath))
        XCTAssertTrue(fileManager.fileExists(atPath: sessionDirectories.mockCryptoStorePath))
        XCTAssertTrue(fileManager.fileExists(atPath: sessionDirectories.mockEventCachePath))
        XCTAssertEqual(try fileManager.numberOfItems(at: sessionDirectories.dataDirectory), 6)
        XCTAssertEqual(try fileManager.numberOfItems(at: sessionDirectories.cacheDirectory), 3)
        
        // When deleting transient user data.
        sessionDirectories.deleteTransientUserData()
        
        // Then the data directory should only contain the crypto store and the cache directory should remain but be empty.
        XCTAssertTrue(fileManager.directoryExists(at: sessionDirectories.dataDirectory))
        XCTAssertEqual(try fileManager.numberOfItems(at: sessionDirectories.dataDirectory), 3)
        XCTAssertFalse(fileManager.fileExists(atPath: sessionDirectories.mockStateStorePath))
        XCTAssertTrue(fileManager.fileExists(atPath: sessionDirectories.mockCryptoStorePath))
        
        XCTAssertTrue(fileManager.directoryExists(at: sessionDirectories.cacheDirectory))
        XCTAssertEqual(try fileManager.numberOfItems(at: sessionDirectories.cacheDirectory), 0)
        XCTAssertFalse(fileManager.fileExists(atPath: sessionDirectories.mockEventCachePath))
        
        // The tests are done, tidy up these useless directories 🧹
        sessionDirectories.delete()
    }
}

private extension SessionDirectories {
    var mockStateStorePath: String { dataDirectory.appending(component: "matrix-sdk-state.sqlite3").path(percentEncoded: false) }
    var mockCryptoStorePath: String { dataDirectory.appending(component: "matrix-sdk-crypto.sqlite3").path(percentEncoded: false) }
    var mockEventCachePath: String { cacheDirectory.appending(component: "matrix-sdk-event-cache.sqlite3").path(percentEncoded: false) }
    
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
