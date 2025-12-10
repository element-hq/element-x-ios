//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum TraceLogPack: Codable, CaseIterable {
    case eventCache, sendQueue, timeline, notificationClient, syncProfiling, latestEvents
    
    var title: String {
        switch self {
        case .eventCache: "Event cache"
        case .sendQueue: "Send queue"
        case .timeline: "Timeline"
        case .notificationClient: "Notification client"
        case .syncProfiling: "Sync profiling"
        case .latestEvents: "Latest events"
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
        case .syncProfiling: self = .syncProfiling
        case .latestEvents: self = .latestEvents
        }
    }
    
    var rustLogPack: MatrixRustSDK.TraceLogPacks {
        switch self {
        case .eventCache: .eventCache
        case .sendQueue: .sendQueue
        case .timeline: .timeline
        case .notificationClient: .notificationClient
        case .syncProfiling: .syncProfiling
        case .latestEvents: .latestEvents
        }
    }
}
