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
import MatrixRustSDK

class RestorationTokenTests: XCTestCase {
    func testDecodeFromTokenV1() throws {
        // Given an encoded restoration token in the original format that only contains a Session from the SDK.
        let originalToken = RestorationTokenV1(session: Session(accessToken: "1234",
                                                                refreshToken: nil,
                                                                userId: "@user:example.com",
                                                                deviceId: "D3V1C3",
                                                                homeserverUrl: "https://matrix.example.com",
                                                                oidcData: nil,
                                                                slidingSyncProxy: "https://sync.example.com"))
        let data = try JSONEncoder().encode(originalToken)
        
        // When decoding the data to the current restoration token format.
        let decodedToken = try JSONDecoder().decode(RestorationToken.self, from: data)
        
        // Then the output should be a valid token with the expected store directories.
        XCTAssertEqual(decodedToken.session, originalToken.session, "The session should not be changed.")
        XCTAssertNil(decodedToken.passphrase, "There should not be a passphrase.")
        XCTAssertNil(decodedToken.pusherNotificationClientIdentifier, "There should not be a push notification client ID.")
        XCTAssertEqual(decodedToken.sessionDirectory, .sessionsBaseDirectory.appending(component: "@user_example.com"),
                       "The session directory should match the original location set by the Rust SDK from our base directory.")
        XCTAssertEqual(decodedToken.cacheDirectory, .cachesBaseDirectory.appending(component: "@user_example.com"),
                       "The cache directory should be derived from the session directory but in the caches directory.")
    }
    
    func testDecodeFromTokenV4() throws {
        // Given an encoded restoration token in the 4th format that contains a stored session directory.
        let sessionDirectoryName = UUID().uuidString
        let originalToken = RestorationTokenV4(session: Session(accessToken: "1234",
                                                                refreshToken: "5678",
                                                                userId: "@user:example.com",
                                                                deviceId: "D3V1C3",
                                                                homeserverUrl: "https://matrix.example.com",
                                                                oidcData: "data-from-mas",
                                                                slidingSyncProxy: "https://sync.example.com"),
                                               sessionDirectory: .sessionsBaseDirectory.appending(component: sessionDirectoryName),
                                               passphrase: "passphrase",
                                               pusherNotificationClientIdentifier: "pusher-identifier")
        let data = try JSONEncoder().encode(originalToken)
        
        // When decoding the data to the current restoration token format.
        let decodedToken = try JSONDecoder().decode(RestorationToken.self, from: data)
        
        // Then the output should be a valid token with the expected store directories.
        XCTAssertEqual(decodedToken.session, originalToken.session, "The session should not be changed.")
        XCTAssertEqual(decodedToken.passphrase, originalToken.passphrase, "The passphrase should not be changed.")
        XCTAssertEqual(decodedToken.pusherNotificationClientIdentifier, originalToken.pusherNotificationClientIdentifier,
                       "The push notification client identifier should not be changed.")
        XCTAssertEqual(decodedToken.sessionDirectory, originalToken.sessionDirectory, "The session directory should not be changed.")
        XCTAssertEqual(decodedToken.cacheDirectory, .cachesBaseDirectory.appending(component: sessionDirectoryName),
                       "The cache directory should be derived from the session directory but in the caches directory.")
    }
    
    func testDecodeFromCurrentToken() throws {
        // Given an encoded restoration token in the current format.
        let sessionDirectoryName = UUID().uuidString
        let originalToken = RestorationToken(session: Session(accessToken: "1234",
                                                              refreshToken: "5678",
                                                              userId: "@user:example.com",
                                                              deviceId: "D3V1C3",
                                                              homeserverUrl: "https://matrix.example.com",
                                                              oidcData: "data-from-mas",
                                                              slidingSyncProxy: nil),
                                             sessionDirectory: .sessionsBaseDirectory.appending(component: sessionDirectoryName),
                                             cacheDirectory: .cachesBaseDirectory.appending(component: sessionDirectoryName),
                                             passphrase: "passphrase",
                                             pusherNotificationClientIdentifier: "pusher-identifier")
        let data = try JSONEncoder().encode(originalToken)
        
        // When decoding the data.
        let decodedToken = try JSONDecoder().decode(RestorationToken.self, from: data)
        
        // Then the output should be a valid token.
        XCTAssertEqual(decodedToken, originalToken, "The token should remain identical.")
    }
}

struct RestorationTokenV1: Equatable, Codable {
    let session: MatrixRustSDK.Session
}

struct RestorationTokenV4: Equatable, Codable {
    let session: MatrixRustSDK.Session
    let sessionDirectory: URL
    let passphrase: String?
    let pusherNotificationClientIdentifier: String?
}
