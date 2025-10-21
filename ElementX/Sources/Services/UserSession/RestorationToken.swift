//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum RestorationTokenError: Error {
    case slidingSyncProxyNotSupported
}

struct RestorationToken: Equatable {
    let session: MatrixRustSDK.Session
    let sessionDirectories: SessionDirectories
    let passphrase: String
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
        
        let session = try container.decode(Session.self, forKey: .session)
        let dataDirectory = try container.decode(URL.self, forKey: .sessionDirectory)
        let cacheDirectory = try container.decodeIfPresent(URL.self, forKey: .cacheDirectory)
        
        let sessionDirectories = if let cacheDirectory {
            SessionDirectories(dataDirectory: dataDirectory, cacheDirectory: cacheDirectory)
        } else {
            SessionDirectories(dataDirectory: dataDirectory)
        }
        
        self = try .init(session: session,
                         sessionDirectories: sessionDirectories,
                         passphrase: container.decode(String.self, forKey: .passphrase),
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

extension MatrixRustSDK.Session: @retroactive Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // The SDK no longer supports sliding sync proxies. We must bail here otherwise the
        // session would be restored using native sliding sync, but if the proxy was still
        // active its sync loop would be stealing keys away from us.
        //
        // Note: As tempting as it is to use container.contains(.slidingSyncProxy), that will always
        // return true as our coding keys have resulted in the key being encoded with a nil value 🤦‍♂️.
        if (try? container.decodeIfPresent(String.self, forKey: .slidingSyncProxy)) != nil {
            throw RestorationTokenError.slidingSyncProxyNotSupported
        }
        
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
