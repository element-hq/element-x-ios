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
        keychain = KeychainController(service: .tests,
                                      accessGroup: InfoPlistReader.target.appGroupIdentifier)
        keychain.removeAllRestorationTokens()
    }
    
    func testAddRestorationToken() {
        // Given an empty keychain.
        XCTAssertTrue(keychain.restorationTokens().isEmpty, "The keychain should be empty to begin with.")
        
        // When adding an restoration token.
        let username = "@test:example.com"
        let restorationToken = RestorationToken(session: .init(accessToken: "accessToken", refreshToken: "refreshToken", userId: "userId", deviceId: "deviceId", homeserverUrl: "homeserverUrl", isSoftLogout: false))
        keychain.setRestorationToken(restorationToken, forUsername: username)
        
        // Then the restoration token should be stored in the keychain.
        XCTAssertEqual(keychain.restorationTokenForUsername(username), restorationToken, "The retrieved restoration token should match the value that was stored.")
    }
    
    func testRemovingRestorationToken() {
        // Given a keychain with a stored restoration token.
        let username = "@test:example.com"
        let restorationToken = RestorationToken(session: .init(accessToken: "accessToken", refreshToken: "refreshToken", userId: "userId", deviceId: "deviceId", homeserverUrl: "homeserverUrl", isSoftLogout: false))
        keychain.setRestorationToken(restorationToken, forUsername: username)
        XCTAssertEqual(keychain.restorationTokens().count, 1, "The keychain should have 1 restoration token.")
        XCTAssertEqual(keychain.restorationTokenForUsername(username), restorationToken, "The initial restoration token should match the value that was stored.")
        
        // When deleting the restoration token.
        keychain.removeRestorationTokenForUsername(username)
        
        // Then the keychain should be empty.
        XCTAssertTrue(keychain.restorationTokens().isEmpty, "The keychain should be empty after deleting the token.")
        XCTAssertNil(keychain.restorationTokenForUsername(username), "There restoration token should not be returned after removal.")
    }
    
    func testRemovingAllRestorationTokens() {
        // Given a keychain with 5 stored restoration tokens.
        for index in 0..<5 {
            let restorationToken = RestorationToken(session: .init(accessToken: "accessToken", refreshToken: "refreshToken", userId: "userId", deviceId: "deviceId", homeserverUrl: "homeserverUrl", isSoftLogout: false))
            keychain.setRestorationToken(restorationToken, forUsername: "@test\(index):example.com")
        }
        XCTAssertEqual(keychain.restorationTokens().count, 5, "The keychain should have 5 restoration tokens.")
        
        // When deleting all of the restoration tokens.
        keychain.removeAllRestorationTokens()
        
        // Then the keychain should be empty.
        XCTAssertTrue(keychain.restorationTokens().isEmpty, "The keychain should be empty after deleting the token.")
    }
    
    func testRemovingSingleRestorationTokens() {
        // Given a keychain with 5 stored restoration tokens.
        for index in 0..<5 {
            let restorationToken = RestorationToken(session: .init(accessToken: "accessToken", refreshToken: "refreshToken", userId: "userId", deviceId: "deviceId", homeserverUrl: "homeserverUrl", isSoftLogout: false))
            keychain.setRestorationToken(restorationToken, forUsername: "@test\(index):example.com")
        }
        XCTAssertEqual(keychain.restorationTokens().count, 5, "The keychain should have 5 restoration tokens.")
        
        // When deleting one of the restoration tokens.
        keychain.removeRestorationTokenForUsername("@test2:example.com")
        
        // Then the other 4 items should remain untouched.
        XCTAssertEqual(keychain.restorationTokens().count, 4, "The keychain have 4 remaining restoration tokens.")
        XCTAssertNotNil(keychain.restorationTokenForUsername("@test0:example.com"), "The restoration token should not have been deleted.")
        XCTAssertNotNil(keychain.restorationTokenForUsername("@test1:example.com"), "The restoration token should not have been deleted.")
        XCTAssertNil(keychain.restorationTokenForUsername("@test2:example.com"), "The restoration token should have been deleted.")
        XCTAssertNotNil(keychain.restorationTokenForUsername("@test3:example.com"), "The restoration token should not have been deleted.")
        XCTAssertNotNil(keychain.restorationTokenForUsername("@test4:example.com"), "The restoration token should not have been deleted.")
    }
}
