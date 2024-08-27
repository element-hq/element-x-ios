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
