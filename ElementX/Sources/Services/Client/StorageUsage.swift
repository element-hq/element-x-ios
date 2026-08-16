//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

/// How much storage each of the SDK's caches uses, overall and per room.
struct StorageUsage: Equatable {
    /// The size of each cache, all rooms included, in bytes.
    let totalBytes: [StorageCacheKind: UInt64]
    /// The rooms with cached data, largest first.
    let rooms: [StorageUsageRoom]
    
    init(totalBytes: [StorageCacheKind: UInt64], rooms: [StorageUsageRoom]) {
        self.totalBytes = totalBytes
        self.rooms = rooms
    }
    
    init(rustReport report: StorageUsageReport) {
        totalBytes = [.messageKeys: report.roomKeysBytes,
                      .roomState: report.roomStateBytes,
                      .messages: report.eventsBytes,
                      .media: report.mediaBytes]
        rooms = report.rooms.map { room in
            StorageUsageRoom(id: room.roomId,
                             name: room.displayName,
                             lastActivity: room.lastActivityTs.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) },
                             bytes: [.messageKeys: room.roomKeysBytes,
                                     .roomState: room.roomStateBytes,
                                     .messages: room.eventsBytes,
                                     .media: room.mediaBytes])
        }
    }
}

/// The caches the SDK keeps on disk (the log files are the app's own).
enum StorageCacheKind: CaseIterable, Identifiable, Hashable {
    case messageKeys, roomState, messages, media, logs
    
    var id: Self { self }
    
    /// Whether the cache's data is attributable to rooms (the logs are session-wide).
    var isPerRoom: Bool { self != .logs }
}

/// One room's share of each cache.
struct StorageUsageRoom: Identifiable, Equatable {
    let id: String
    let name: String?
    /// When the room was last active, if known.
    let lastActivity: Date?
    let bytes: [StorageCacheKind: UInt64]
    
    var totalBytes: UInt64 { bytes.values.reduce(0, +) }
}
