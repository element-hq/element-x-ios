//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum TraceLogPack: Codable, CaseIterable {
    case eventCache, sendQueue, timeline, notificationClient
    
    var title: String {
        switch self {
        case .eventCache: "Event cache"
        case .sendQueue: "Send queue"
        case .timeline: "Timeline"
        case .notificationClient: "Notification client"
        }
    }
}

extension TraceLogPack {
    // periphery:ignore - Unused, but added to detect new cases when updating the SDK.
    init(rustLogPack: MatrixRustSDK.TraceLogPacks) {
        switch rustLogPack {
        case .eventCache: self = .eventCache
        case .sendQueue: self = .sendQueue
        case .timeline: self = .timeline
        case .notificationClient: self = .notificationClient
        }
    }
    
    var rustLogPack: MatrixRustSDK.TraceLogPacks {
        switch self {
        case .eventCache: .eventCache
        case .sendQueue: .sendQueue
        case .timeline: .timeline
        case .notificationClient: .notificationClient
        }
    }
}
