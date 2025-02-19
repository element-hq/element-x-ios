//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import ElementX
import MatrixRustSDK

class RestorationTokenTests: XCTestCase {
    func testDecodeFromTokenV1() throws {
        // Given an encoded restoration token in the original format that only contains a Session from the SDK.
        let originalToken = RestorationTokenV1(session: SessionV1(accessToken: "1234",
                                                                  refreshToken: nil,
                                                                  userId: "@user:example.com",
                                                                  deviceId: "D3V1C3",
                                                                  homeserverUrl: "https://matrix.example.com",
                                                                  oidcData: nil,
                                                                  slidingSyncVersion: .proxy(url: "https://sync.example.com")))
        let data = try JSONEncoder().encode(originalToken)
        
        // When decoding the data to the current restoration token format.
        let decodedToken = try JSONDecoder().decode(RestorationToken.self, from: data)
        
        // Then the output should be a valid token with the expected store directories.
        assertEqual(session: decodedToken.session, originalSession: originalToken.session)
        XCTAssertNil(decodedToken.passphrase, "There should not be a passphrase.")
        XCTAssertNil(decodedToken.pusherNotificationClientIdentifier, "There should not be a push notification client ID.")
        XCTAssertEqual(decodedToken.sessionDirectories.dataDirectory, .sessionsBaseDirectory.appending(component: "@user_example.com"),
                       "The session directory should match the original location set by the Rust SDK from our base directory.")
        XCTAssertEqual(decodedToken.sessionDirectories.cacheDirectory, .sessionCachesBaseDirectory.appending(component: "@user_example.com"),
                       "The cache directory should be derived from the session directory but in the caches directory.")
        
        XCTAssertEqual(decodedToken.slidingSyncProxyURLString, "https://sync.example.com",
                       "The original sliding sync URL should be preserved in order to trigger the migration prompt.")
        XCTAssertTrue(decodedToken.needsSlidingSyncMigration, "The migration flag should be set to true.")
    }
    
    func testDecodeFromTokenV4() throws {
        // Given an encoded restoration token in the 4th format that contains a stored session directory.
        let sessionDirectoryName = UUID().uuidString
        let originalToken = RestorationTokenV4(session: SessionV1(accessToken: "1234",
                                                                  refreshToken: "5678",
                                                                  userId: "@user:example.com",
                                                                  deviceId: "D3V1C3",
                                                                  homeserverUrl: "https://matrix.example.com",
                                                                  oidcData: "data-from-mas",
                                                                  slidingSyncVersion: .proxy(url: "https://sync.example.com")),
                                               sessionDirectory: .sessionsBaseDirectory.appending(component: sessionDirectoryName),
                                               passphrase: "passphrase",
                                               pusherNotificationClientIdentifier: "pusher-identifier")
        let data = try JSONEncoder().encode(originalToken)
        
        // When decoding the data to the current restoration token format.
        let decodedToken = try JSONDecoder().decode(RestorationToken.self, from: data)
        
        // Then the output should be a valid token with the expected store directories.
        assertEqual(session: decodedToken.session, originalSession: originalToken.session)
        XCTAssertEqual(decodedToken.passphrase, originalToken.passphrase, "The passphrase should not be changed.")
        XCTAssertEqual(decodedToken.pusherNotificationClientIdentifier, originalToken.pusherNotificationClientIdentifier,
                       "The push notification client identifier should not be changed.")
        XCTAssertEqual(decodedToken.sessionDirectories.dataDirectory, originalToken.sessionDirectory,
                       "The session directory should not be changed.")
        XCTAssertEqual(decodedToken.sessionDirectories.cacheDirectory, .sessionCachesBaseDirectory.appending(component: sessionDirectoryName),
                       "The cache directory should be derived from the session directory but in the caches directory.")
        
        XCTAssertEqual(decodedToken.slidingSyncProxyURLString, "https://sync.example.com",
                       "The original sliding sync URL should be preserved in order to trigger the migration prompt.")
        XCTAssertTrue(decodedToken.needsSlidingSyncMigration, "The migration flag should be set to true.")
    }
    
    func testDecodeFromTokenV5() throws {
        // Given an encoded restoration token in the 5th format that contains separate directories for session data and caches.
        let sessionDirectoryName = UUID().uuidString
        let originalToken = RestorationTokenV5(session: SessionV1(accessToken: "1234",
                                                                  refreshToken: "5678",
                                                                  userId: "@user:example.com",
                                                                  deviceId: "D3V1C3",
                                                                  homeserverUrl: "https://matrix.example.com",
                                                                  oidcData: "data-from-mas",
                                                                  slidingSyncVersion: .native),
                                               sessionDirectory: .sessionsBaseDirectory.appending(component: sessionDirectoryName),
                                               cacheDirectory: .sessionCachesBaseDirectory.appending(component: sessionDirectoryName),
                                               passphrase: "passphrase",
                                               pusherNotificationClientIdentifier: "pusher-identifier")
        let data = try JSONEncoder().encode(originalToken)
        
        // When decoding the data.
        let decodedToken = try JSONDecoder().decode(RestorationToken.self, from: data)
        
        // Then the output should be a valid token.
        assertEqual(session: decodedToken.session, originalSession: originalToken.session)
        XCTAssertEqual(decodedToken.passphrase, originalToken.passphrase, "The passphrase should not be changed.")
        XCTAssertEqual(decodedToken.pusherNotificationClientIdentifier, originalToken.pusherNotificationClientIdentifier,
                       "The push notification client identifier should not be changed.")
        XCTAssertEqual(decodedToken.sessionDirectories.dataDirectory, originalToken.sessionDirectory,
                       "The session directory should not be changed.")
        XCTAssertEqual(decodedToken.sessionDirectories.cacheDirectory, originalToken.cacheDirectory,
                       "The cache directory should not be changed.")
        
        XCTAssertNil(decodedToken.slidingSyncProxyURLString, "No sliding sync proxy URL should be decoded for native sliding sync.")
        XCTAssertFalse(decodedToken.needsSlidingSyncMigration, "The migration flag should not be set.")
    }
    
    func testDecodeFromCurrentToken() throws {
        // Given an encoded restoration token in the current format.
        let originalToken = RestorationToken(session: Session(accessToken: "1234",
                                                              refreshToken: "5678",
                                                              userId: "@user:example.com",
                                                              deviceId: "D3V1C3",
                                                              homeserverUrl: "https://matrix.example.com",
                                                              oidcData: "data-from-mas",
                                                              slidingSyncVersion: .native),
                                             sessionDirectories: .init(),
                                             passphrase: "passphrase",
                                             pusherNotificationClientIdentifier: "pusher-identifier",
                                             slidingSyncProxyURLString: nil)
        let data = try JSONEncoder().encode(originalToken)
        
        // When decoding the data.
        let decodedToken = try JSONDecoder().decode(RestorationToken.self, from: data)
        
        // Then the output should be a valid token.
        XCTAssertEqual(decodedToken, originalToken, "The token should remain identical.")
    }
    
    func assertEqual(session: Session, originalSession: SessionV1) {
        XCTAssertEqual(session.accessToken, originalSession.accessToken, "The access token should not be changed.")
        XCTAssertEqual(session.refreshToken, originalSession.refreshToken, "The refresh token should not be changed.")
        XCTAssertEqual(session.userId, originalSession.userId, "The user ID should not be changed.")
        XCTAssertEqual(session.deviceId, originalSession.deviceId, "The device ID should not be changed.")
        XCTAssertEqual(session.homeserverUrl, originalSession.homeserverUrl, "The homeserver URL should not be changed.")
        XCTAssertEqual(session.oidcData, originalSession.oidcData, "The OIDC data should not be changed.")
    }
}

// MARK: - Token formats

struct RestorationTokenV1: Equatable, Codable {
    let session: SessionV1
}

struct RestorationTokenV4: Equatable, Codable {
    let session: SessionV1
    let sessionDirectory: URL
    let passphrase: String?
    let pusherNotificationClientIdentifier: String?
}

struct RestorationTokenV5: Equatable, Codable {
    let session: SessionV1
    let sessionDirectory: URL
    let cacheDirectory: URL
    let passphrase: String?
    let pusherNotificationClientIdentifier: String?
}

// MARK: - Session formats

struct SessionV1: Equatable {
    var accessToken: String
    var refreshToken: String?
    var userId: String
    var deviceId: String
    var homeserverUrl: String
    var oidcData: String?
    var slidingSyncVersion: SlidingSyncVersionV1
}

enum SlidingSyncVersionV1: Equatable {
    case none
    case proxy(url: String)
    case native
    
    var proxyURL: String? {
        guard case let .proxy(url) = self else { return nil }
        return url
    }
}

extension SessionV1: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let slidingSyncProxy = try container.decodeIfPresent(String.self, forKey: .slidingSyncProxy)
        self = try .init(accessToken: container.decode(String.self, forKey: .accessToken),
                         refreshToken: container.decodeIfPresent(String.self, forKey: .refreshToken),
                         userId: container.decode(String.self, forKey: .userId),
                         deviceId: container.decode(String.self, forKey: .deviceId),
                         homeserverUrl: container.decode(String.self, forKey: .homeserverUrl),
                         oidcData: container.decodeIfPresent(String.self, forKey: .oidcData),
                         slidingSyncVersion: slidingSyncProxy.map { .proxy(url: $0) } ?? .native)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(refreshToken, forKey: .refreshToken)
        try container.encode(userId, forKey: .userId)
        try container.encode(deviceId, forKey: .deviceId)
        try container.encode(homeserverUrl, forKey: .homeserverUrl)
        try container.encode(oidcData, forKey: .oidcData)
        try container.encode(slidingSyncVersion.proxyURL, forKey: .slidingSyncProxy)
    }
    
    enum CodingKeys: String, CodingKey {
        case accessToken, refreshToken, userId, deviceId, homeserverUrl, oidcData, slidingSyncProxy
    }
}
