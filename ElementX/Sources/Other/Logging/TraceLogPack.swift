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
    // RIG accommodation: `search` exists in the local rust-sdk (current main) but not yet in the
    // pinned release this file tracked — added to keep the exhaustive switches compiling.
    case eventCache, backPagination, sendQueue, timeline, notificationClient, syncProfiling, latestEvents, search

    var title: String {
        switch self {
        case .eventCache: "Event cache"
        case .backPagination: "Back-pagination queue"
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
        switch rustLogPack {
        case .eventCache: self = .eventCache
        case .backPagination: self = .backPagination
        case .sendQueue: self = .sendQueue
        case .timeline: self = .timeline
        case .notificationClient: self = .notificationClient
        case .syncProfiling: self = .syncProfiling
        case .latestEvents: self = .latestEvents
        case .search: self = .search
        }
    }
    
    var rustLogPack: MatrixRustSDK.TraceLogPacks {
        switch self {
        case .eventCache: .eventCache
        case .backPagination: .backPagination
        case .sendQueue: .sendQueue
        case .timeline: .timeline
        case .notificationClient: .notificationClient
        case .syncProfiling: .syncProfiling
        case .latestEvents: .latestEvents
        case .search: .search
        }
    }
}
