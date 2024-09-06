//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

struct APSAlert: Encodable {
    let locKey: String
    let locArgs: [String]

    enum CodingKeys: String, CodingKey {
        case locKey = "loc-key"
        case locArgs = "loc-args"
    }
}

struct APSInfo: Encodable {
    let mutableContent: Int
    let alert: APSAlert

    enum CodingKeys: String, CodingKey {
        case mutableContent = "mutable-content"
        case alert
    }
}

struct APNSPayload: Encodable {
    let aps: APSInfo
    let pusherNotificationClientIdentifier: String?

    enum CodingKeys: String, CodingKey {
        case aps
        case pusherNotificationClientIdentifier = "pusher_notification_client_identifier"
    }
}
