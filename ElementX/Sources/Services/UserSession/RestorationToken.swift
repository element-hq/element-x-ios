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

import Foundation
import MatrixRustSDK

struct RestorationToken: Equatable {
    let session: MatrixRustSDK.Session
    let sessionDirectory: URL
    let cacheDirectory: URL
    let passphrase: String?
    let pusherNotificationClientIdentifier: String?
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
                         sessionDirectory: sessionDirectories.dataDirectory,
                         cacheDirectory: sessionDirectories.cacheDirectory,
                         passphrase: container.decodeIfPresent(String.self, forKey: .passphrase),
                         pusherNotificationClientIdentifier: container.decodeIfPresent(String.self, forKey: .pusherNotificationClientIdentifier))
    }
}

extension MatrixRustSDK.Session: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let slidingSyncVersion: SlidingSyncVersion = try container.decodeIfPresent(String.self, forKey: .slidingSyncProxy).map { .proxy(url: $0) } ?? .native
        self = try .init(accessToken: container.decode(String.self, forKey: .accessToken),
                         refreshToken: container.decodeIfPresent(String.self, forKey: .refreshToken),
                         userId: container.decode(String.self, forKey: .userId),
                         deviceId: container.decode(String.self, forKey: .deviceId),
                         homeserverUrl: container.decode(String.self, forKey: .homeserverUrl),
                         oidcData: container.decodeIfPresent(String.self, forKey: .oidcData),
                         slidingSyncVersion: slidingSyncVersion)
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
