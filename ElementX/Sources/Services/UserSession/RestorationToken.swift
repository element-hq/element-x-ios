//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct RestorationToken: Equatable {
    let session: MatrixRustSDK.Session
    let sessionDirectories: SessionDirectories
    let passphrase: String?
    let pusherNotificationClientIdentifier: String?
    
    /// The sliding sync proxy URL that was previously encoded in the Session.
    /// This is temporary to help make a nicer user migration flow. In the future
    /// we will throw when decoding sessions with a sliding sync proxy URL.
    let slidingSyncProxyURLString: String?
    /// Whether the token is for a session that is using the now unsupported sliding sync proxy.
    var needsSlidingSyncMigration: Bool { slidingSyncProxyURLString != nil }
    
    enum CodingKeys: CodingKey {
        case session
        case sessionDirectory
        case cacheDirectory
        case passphrase
        case pusherNotificationClientIdentifier
    }
}

extension RestorationToken: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let sessionWrapper = try container.decode(SessionWrapper.self, forKey: .session)
        let dataDirectory = try container.decodeIfPresent(URL.self, forKey: .sessionDirectory)
        let cacheDirectory = try container.decodeIfPresent(URL.self, forKey: .cacheDirectory)
        
        let sessionDirectories = if let dataDirectory {
            if let cacheDirectory {
                SessionDirectories(dataDirectory: dataDirectory, cacheDirectory: cacheDirectory)
            } else {
                SessionDirectories(dataDirectory: dataDirectory)
            }
        } else {
            SessionDirectories(userID: sessionWrapper.session.userId)
        }
        
        self = try .init(session: sessionWrapper.session,
                         sessionDirectories: sessionDirectories,
                         passphrase: container.decodeIfPresent(String.self, forKey: .passphrase),
                         pusherNotificationClientIdentifier: container.decodeIfPresent(String.self, forKey: .pusherNotificationClientIdentifier),
                         slidingSyncProxyURLString: sessionWrapper.slidingSyncProxyURLString)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(SessionWrapper(session: session, slidingSyncProxyURLString: slidingSyncProxyURLString), forKey: .session)
        try container.encode(sessionDirectories.dataDirectory, forKey: .sessionDirectory)
        try container.encode(sessionDirectories.cacheDirectory, forKey: .cacheDirectory)
        try container.encode(passphrase, forKey: .passphrase)
        try container.encode(pusherNotificationClientIdentifier, forKey: .pusherNotificationClientIdentifier)
    }
}

/// Temporary struct to smooth the forced migration by keeping a user session.
/// In the future we can remove this and throw a migration error when the URL
/// is decoded to a non-nil value.
private struct SessionWrapper {
    let session: MatrixRustSDK.Session
    let slidingSyncProxyURLString: String?
}

extension SessionWrapper: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: MatrixRustSDK.Session.CodingKeys.self)
        session = try Session(from: decoder)
        
        // TODO: In the future we should decode this in the Session and throw a migration error if it contains a value.
        slidingSyncProxyURLString = try container.decodeIfPresent(String.self, forKey: .slidingSyncProxy)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: MatrixRustSDK.Session.CodingKeys.self)
        try session.encode(to: encoder)
        try container.encode(slidingSyncProxyURLString, forKey: .slidingSyncProxy)
    }
}

extension MatrixRustSDK.Session: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self = try .init(accessToken: container.decode(String.self, forKey: .accessToken),
                         refreshToken: container.decodeIfPresent(String.self, forKey: .refreshToken),
                         userId: container.decode(String.self, forKey: .userId),
                         deviceId: container.decode(String.self, forKey: .deviceId),
                         homeserverUrl: container.decode(String.self, forKey: .homeserverUrl),
                         oidcData: container.decodeIfPresent(String.self, forKey: .oidcData),
                         slidingSyncVersion: .native)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(refreshToken, forKey: .refreshToken)
        try container.encode(userId, forKey: .userId)
        try container.encode(deviceId, forKey: .deviceId)
        try container.encode(homeserverUrl, forKey: .homeserverUrl)
        try container.encode(oidcData, forKey: .oidcData)
    }
    
    enum CodingKeys: String, CodingKey {
        case accessToken, refreshToken, userId, deviceId, homeserverUrl, oidcData, slidingSyncProxy
    }
}
