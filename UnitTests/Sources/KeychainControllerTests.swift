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

@testable import ElementX
import XCTest

class KeychainControllerTests: XCTestCase {
    var keychain: KeychainController!
    
    override func setUp() {
        keychain = KeychainController(identifier: "\(ElementInfoPlist.cfBundleIdentifier).tests")
        keychain.removeAllRestoreTokens()
    }
    
    func testAddRestoreToken() {
        // Given an empty keychain.
        XCTAssertTrue(keychain.restoreTokens().isEmpty, "The keychain should be empty to begin with.")
        
        // When adding an restore token.
        let username = "@test:example.com"
        let restoreToken = UUID().uuidString
        keychain.setRestoreToken(restoreToken, forUsername: username)
        
        // Then the restore token should be stored in the keychain.
        XCTAssertEqual(keychain.restoreTokenForUsername(username), restoreToken, "The retrieved restore token should match the value that was stored.")
    }
    
    func testRemovingRestoreToken() {
        // Given a keychain with a stored restore token.
        let username = "@test:example.com"
        let restoreToken = UUID().uuidString
        keychain.setRestoreToken(restoreToken, forUsername: username)
        XCTAssertEqual(keychain.restoreTokens().count, 1, "The keychain should have 1 restore token.")
        XCTAssertEqual(keychain.restoreTokenForUsername(username), restoreToken, "The initial restore token should match the value that was stored.")
        
        // When deleting the restore token.
        keychain.removeRestoreTokenForUsername(username)
        
        // Then the keychain should be empty.
        XCTAssertTrue(keychain.restoreTokens().isEmpty, "The keychain should be empty after deleting the token.")
        XCTAssertNil(keychain.restoreTokenForUsername(username), "There restore token should not be returned after removal.")
    }
    
    func testRemovingAllRestoreTokens() {
        // Given a keychain with 5 stored restore tokens.
        for index in 0..<5 {
            keychain.setRestoreToken(UUID().uuidString, forUsername: "@test\(index):example.com")
        }
        XCTAssertEqual(keychain.restoreTokens().count, 5, "The keychain should have 5 restore tokens.")
        
        // When deleting all of the restore tokens.
        keychain.removeAllRestoreTokens()
        
        // Then the keychain should be empty.
        XCTAssertTrue(keychain.restoreTokens().isEmpty, "The keychain should be empty after deleting the token.")
    }
    
    func testRemovingSingleRestoreTokens() {
        // Given a keychain with 5 stored restore tokens.
        for index in 0..<5 {
            keychain.setRestoreToken(UUID().uuidString, forUsername: "@test\(index):example.com")
        }
        XCTAssertEqual(keychain.restoreTokens().count, 5, "The keychain should have 5 restore tokens.")
        
        // When deleting one of the restore tokens.
        keychain.removeRestoreTokenForUsername("@test2:example.com")
        
        // Then the other 4 items should remain untouched.
        XCTAssertEqual(keychain.restoreTokens().count, 4, "The keychain have 4 remaining restore tokens.")
        XCTAssertNotNil(keychain.restoreTokenForUsername("@test0:example.com"), "The restore token should not have been deleted.")
        XCTAssertNotNil(keychain.restoreTokenForUsername("@test1:example.com"), "The restore token should not have been deleted.")
        XCTAssertNil(keychain.restoreTokenForUsername("@test2:example.com"), "The restore token should have been deleted.")
        XCTAssertNotNil(keychain.restoreTokenForUsername("@test3:example.com"), "The restore token should not have been deleted.")
        XCTAssertNotNil(keychain.restoreTokenForUsername("@test4:example.com"), "The restore token should not have been deleted.")
    }
}
