//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

class SessionDirectoriesTests: XCTestCase {
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
}
