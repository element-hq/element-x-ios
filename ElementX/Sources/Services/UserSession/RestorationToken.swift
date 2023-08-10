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

import CryptoKit
import Foundation

import MatrixRustSDK

struct RestorationToken: Codable, Equatable {
    let session: MatrixRustSDK.Session
    let pusherNotificationClientIdentifier: String?

    init(session: MatrixRustSDK.Session) {
        self.session = session
        if let data = session.userId.data(using: .utf8) {
            let digest = SHA256.hash(data: data)
            pusherNotificationClientIdentifier = digest.compactMap { String(format: "%02x", $0) }.joined()
        } else {
            pusherNotificationClientIdentifier = nil
        }
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
                         slidingSyncProxy: container.decode(String.self, forKey: .slidingSyncProxy))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(refreshToken, forKey: .refreshToken)
        try container.encode(userId, forKey: .userId)
        try container.encode(deviceId, forKey: .deviceId)
        try container.encode(homeserverUrl, forKey: .homeserverUrl)
        try container.encode(oidcData, forKey: .oidcData)
        try container.encode(slidingSyncProxy, forKey: .slidingSyncProxy)
    }
    
    enum CodingKeys: String, CodingKey {
        case accessToken, refreshToken, userId, deviceId, homeserverUrl, oidcData, slidingSyncProxy
    }
}
