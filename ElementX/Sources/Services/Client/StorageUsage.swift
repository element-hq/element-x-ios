//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

/// The caches the SDK keeps on disk (the log files are the app's own).
nonisolated enum StorageCacheKind: CaseIterable, Identifiable, Hashable {
    case messageKeys, roomState, messages, media, logs
    
    var id: Self { self }
    
    /// Whether the cache's data is attributable to rooms (the logs are session-wide).
    var isPerRoom: Bool { self != .logs }
}

/// One room's share of each cache, in bytes (the stored payloads' sizes).
nonisolated struct StorageUsageRoom: Identifiable, Equatable {
    let id: String
    let name: String?
    /// When the room was last active, if known.
    let lastActivity: Date?
    let bytes: [StorageCacheKind: UInt64]
    
    var totalBytes: UInt64 { bytes.values.reduce(0, +) }
    
    init(id: String, name: String?, lastActivity: Date?, bytes: [StorageCacheKind: UInt64]) {
        self.id = id
        self.name = name
        self.lastActivity = lastActivity
        self.bytes = bytes
    }
    
    init(rustUsage room: RoomStorageUsage) {
        self.init(id: room.roomId,
                  name: room.displayName,
                  lastActivity: room.lastActivityTs.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) },
                  bytes: [.messageKeys: room.roomKeysBytes,
                          .roomState: room.roomStateBytes,
                          .messages: room.eventsBytes,
                          .media: room.mediaBytes])
    }
}

/// Bridges the SDK's storage usage walk to an async stream of room batches (each batch
/// replacing the previous numbers of the rooms it contains).
extension StoreSizes {
    /// The store sizes shown in previews and tests.
    static var mock: StoreSizes {
        StoreSizes(cryptoStore: 20_000_000, stateStore: 100_000_000, eventCacheStore: 110_000_000, mediaStore: 300_000_000)
    }
}
