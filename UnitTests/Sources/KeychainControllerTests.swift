//
// Copyright 2021 New Vector Ltd
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

class KeychainControllerTests: XCTestCase {
    var keychain: KeychainController!
    
    override func setUp() {
        keychain = KeychainController(identifier: "\(ElementInfoPlist.cfBundleIdentifier).tests")
        keychain.removeAllAccessTokens()
    }
    
    func testAddAccessToken() {
        // Given an empty keychain.
        XCTAssertTrue(keychain.accessTokens().isEmpty, "The keychain should be empty to begin with.")
        
        // When adding an access token.
        let username = "@test:example.com"
        let accessToken = UUID().uuidString
        keychain.setAccessToken(accessToken, forUsername: username)
        
        // Then the access token should be stored in the keychain.
        XCTAssertEqual(keychain.accessTokenForUsername(username), accessToken, "The retrieved access token should match the value that was stored.")
    }
    
    func testRemovingAccessToken() {
        // Given a keychain with a stored access token.
        let username = "@test:example.com"
        let accessToken = UUID().uuidString
        keychain.setAccessToken(accessToken, forUsername: username)
        XCTAssertEqual(keychain.accessTokens().count, 1, "The keychain should have 1 access token.")
        XCTAssertEqual(keychain.accessTokenForUsername(username), accessToken, "The initial access token should match the value that was stored.")
        
        // When deleting the access token.
        keychain.removeAccessTokenForUsername(username)
        
        // Then the keychain should be empty.
        XCTAssertTrue(keychain.accessTokens().isEmpty, "The keychain should be empty after deleting the token.")
        XCTAssertNil(keychain.accessTokenForUsername(username), "There access token should not be returned after removal.")
    }
    
    func testRemovingAllAccessTokens() {
        // Given a keychain with 5 stored access tokens.
        for index in 0..<5 {
            keychain.setAccessToken(UUID().uuidString, forUsername: "@test\(index):example.com")
        }
        XCTAssertEqual(keychain.accessTokens().count, 5, "The keychain should have 5 access tokens.")
        
        // When deleting all of the access tokens.
        keychain.removeAllAccessTokens()
        
        // Then the keychain should be empty.
        XCTAssertTrue(keychain.accessTokens().isEmpty, "The keychain should be empty after deleting the token.")
    }
    
    func testRemovingSingleAccessTokens() {
        // Given a keychain with 5 stored access tokens.
        for index in 0..<5 {
            keychain.setAccessToken(UUID().uuidString, forUsername: "@test\(index):example.com")
        }
        XCTAssertEqual(keychain.accessTokens().count, 5, "The keychain should have 5 access tokens.")
        
        // When deleting one of the access tokens.
        keychain.removeAccessTokenForUsername("@test2:example.com")
        
        // Then the other 4 items should remain untouched.
        XCTAssertEqual(keychain.accessTokens().count, 4, "The keychain have 4 remaining access tokens.")
        XCTAssertNotNil(keychain.accessTokenForUsername("@test0:example.com"), "The access token should not have been deleted.")
        XCTAssertNotNil(keychain.accessTokenForUsername("@test1:example.com"), "The access token should not have been deleted.")
        XCTAssertNil(keychain.accessTokenForUsername("@test2:example.com"), "The access token should have been deleted.")
        XCTAssertNotNil(keychain.accessTokenForUsername("@test3:example.com"), "The access token should not have been deleted.")
        XCTAssertNotNil(keychain.accessTokenForUsername("@test4:example.com"), "The access token should not have been deleted.")
    }
}
