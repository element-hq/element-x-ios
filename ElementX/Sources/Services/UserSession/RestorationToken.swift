//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct RestorationToken: Equatable {
    let session: MatrixRustSDK.Session
    let sessionDirectories: SessionDirectories
    let passphrase: String?
    let pusherNotificationClientIdentifier: String?
    
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
        
        let session = try container.decode(MatrixRustSDK.Session.self, forKey: .session)
        let dataDirectory = try container.decodeIfPresent(URL.self, forKey: .sessionDirectory)
        let cacheDirectory = try container.decodeIfPresent(URL.self, forKey: .cacheDirectory)
        
        let sessionDirectories = if let dataDirectory {
            if let cacheDirectory {
                SessionDirectories(dataDirectory: dataDirectory, cacheDirectory: cacheDirectory)
            } else {
                SessionDirectories(dataDirectory: dataDirectory)
            }
        } else {
            SessionDirectories(userID: session.userId)
        }
        
        self = try .init(session: session,
                         sessionDirectories: sessionDirectories,
                         passphrase: container.decodeIfPresent(String.self, forKey: .passphrase),
                         pusherNotificationClientIdentifier: container.decodeIfPresent(String.self, forKey: .pusherNotificationClientIdentifier))
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(session, forKey: .session)
        try container.encode(sessionDirectories.dataDirectory, forKey: .sessionDirectory)
        try container.encode(sessionDirectories.cacheDirectory, forKey: .cacheDirectory)
        try container.encode(passphrase, forKey: .passphrase)
        try container.encode(pusherNotificationClientIdentifier, forKey: .pusherNotificationClientIdentifier)
    }
}

extension MatrixRustSDK.Session: Codable {
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

private extension SlidingSyncVersion {
    var proxyURL: String? {
        guard case let .proxy(url) = self else { return nil }
        return url
    }
}
