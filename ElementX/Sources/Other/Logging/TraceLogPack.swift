//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

nonisolated enum TraceLogPack: Codable, CaseIterable {
    case eventCache, sendQueue, timeline, notificationClient, syncProfiling, latestEvents, search
    
    var title: String {
        switch self {
        case .eventCache: "Event cache"
        case .sendQueue: "Send queue"
        case .timeline: "Timeline"
        case .notificationClient: "Notification client"
        case .syncProfiling: "Sync profiling"
        case .latestEvents: "Latest events"
        case .search: "Search"
        }
    }
}

nonisolated extension TraceLogPack {
    // periphery:ignore - Unused, but added to detect new cases when updating the SDK.
    init(rustLogPack: MatrixRustSDK.TraceLogPacks) {
        self = switch rustLogPack {
        case .eventCache: .eventCache
        case .sendQueue: .sendQueue
        case .timeline: .timeline
        case .notificationClient: .notificationClient
        case .syncProfiling: .syncProfiling
        case .latestEvents: .latestEvents
        case .search: .search
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
        case .search: .search
        }
    }
}
