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

struct RestorationToken: Codable, Equatable {
    let session: MatrixRustSDK.Session
}

extension MatrixRustSDK.Session: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self = .init(accessToken: try container.decode(String.self, forKey: .accessToken),
                     refreshToken: try container.decodeIfPresent(String.self, forKey: .refreshToken),
                     userId: try container.decode(String.self, forKey: .userId),
                     deviceId: try container.decode(String.self, forKey: .deviceId),
                     homeserverUrl: try container.decode(String.self, forKey: .homeserverUrl),
                     isSoftLogout: try container.decode(Bool.self, forKey: .isSoftLogout))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(refreshToken, forKey: .refreshToken)
        try container.encode(userId, forKey: .userId)
        try container.encode(deviceId, forKey: .deviceId)
        try container.encode(homeserverUrl, forKey: .homeserverUrl)
        try container.encode(isSoftLogout, forKey: .isSoftLogout)
    }
    
    enum CodingKeys: String, CodingKey {
        case accessToken, refreshToken, userId, deviceId, homeserverUrl, isSoftLogout
    }
}

#warning("Remove this in a couple of releases - sceriu 03.11.2022")
struct LegacyRestorationToken: Decodable {
    let isGuest: Bool?
    let isSoftLogout: Bool?
    let homeURL: String
    let session: Session
    
    enum CodingKeys: String, CodingKey {
        case isGuest = "is_guest"
        case isSoftLogout = "is_soft_logout"
        case homeURL = "homeurl"
        case session
    }
    
    struct Session: Decodable {
        let accessToken: String
        let userId: String
        let deviceId: String
    
        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case userId = "user_id"
            case deviceId = "device_id"
        }
    }
}
