//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import Foundation
import SwiftUI

enum ManageStorageScreenViewModelAction {
    /// The whole state store is to be cleared: the app clears its caches and restarts.
    case clearCache
    case viewLogs
}

struct ManageStorageScreenViewState: BindableState {
    /// The smallest room worth listing.
    static let listedRoomMinimumBytes: UInt64 = 1_000_000

    var isLoading = true
    /// Whether the rooms are still being walked (they fill in progressively).
    var isLoadingRooms = false
    /// The size of each cache across all rooms (the stores' sizes on disk), the log files included.
    var totalBytes: [StorageCacheKind: UInt64] = [:]
    /// The rooms with cached data, largest first.
    var rooms: [StorageUsageRoom] = []
    var selectedRoomIDs: Set<String> = []

    var bindings = ManageStorageScreenViewStateBindings()

    var isFiltered: Bool { !selectedRoomIDs.isEmpty }

    /// The rooms shown: the ones using more than ``listedRoomMinimumBytes``, and the selected
    /// ones regardless (clearing shrinks them, but they shouldn't vanish from under the selection).
    var listedRooms: [StorageUsageRoom] {
        rooms.filter { $0.totalBytes >= Self.listedRoomMinimumBytes || selectedRoomIDs.contains($0.id) }
    }

    var selectedRooms: [StorageUsageRoom] {
        rooms.filter { selectedRoomIDs.contains($0.id) }
    }

    /// The caches that apply to the current scope: the logs are session-wide, so they're
    /// greyed out (shown, not clearable) when rooms are selected.
    var activeCaches: [StorageCacheKind] {
        isFiltered ? StorageCacheKind.allCases.filter(\.isPerRoom) : StorageCacheKind.allCases
    }

    /// The size of a cache within the current scope (session-wide caches always show their total).
    func bytes(for cache: StorageCacheKind) -> UInt64 {
        guard isFiltered, cache.isPerRoom else { return totalBytes[cache] ?? 0 }
        return selectedRooms.reduce(0) { $0 + ($1.bytes[cache] ?? 0) }
    }

    /// The largest listed room's total, the width every room's bar is relative to.
    var largestListedRoomBytes: UInt64 {
        listedRooms.first?.totalBytes ?? 0
    }

    /// The label of the bar chart: all rooms, the selected room, or the number of selected rooms,
    /// with the scope's total (the active caches only, so no logs when filtered to rooms).
    var scopeTitle: String {
        let scope = switch selectedRooms.count {
        case 0: UntranslatedL10n.screenManageStorageScopeAllRooms
        case 1: selectedRooms[0].displayName
        case let count: UntranslatedL10n.screenManageStorageScopeRooms(count)
        }
        let total = activeCaches.reduce(0) { $0 + bytes(for: $1) }
        return if isFiltered {
            "\(scope) (\(StorageUsageChart.megabytes(total)))"
        } else {
            "\(scope) (\(StorageUsageChart.megabytes(total)), \(UntranslatedL10n.screenManageStorageScopeRooms(rooms.count)))"
        }
    }

    var clearAllTitle: String {
        switch selectedRooms.count {
        case 0: UntranslatedL10n.screenManageStorageClearAll
        case 1: UntranslatedL10n.screenManageStorageClearForRoom(selectedRooms[0].displayName)
        case let count: UntranslatedL10n.screenManageStorageClearForRooms(count)
        }
    }
}

struct ManageStorageScreenViewStateBindings {
    /// The clear the user is being asked to confirm.
    var clearRequest: ManageStorageClearRequest?
    var alertInfo: AlertInfo<ManageStorageScreenAlert>?
}

enum ManageStorageScreenAlert {
    case failure
}

/// A clear awaiting confirmation: one cache, or all of them (`nil`).
struct ManageStorageClearRequest: Identifiable, Equatable, AlertProtocol {
    let cache: StorageCacheKind?
    /// Whether clearing means clearing the whole state store, which restarts the app.
    let restartsApp: Bool
    /// The alert's title: the cache, or the scope (all caches, or the selected rooms').
    let title: String

    var id: String { cache.map(\.title) ?? "all" }

    /// The warnings for what's about to be cleared.
    var message: String {
        var lines = [String]()
        if cache == nil || cache == .messageKeys {
            lines.append(UntranslatedL10n.screenManageStorageWarningMessageKeys)
        }
        if cache == .roomState || cache == .messages {
            lines.append(UntranslatedL10n.screenManageStorageWarningRoomState)
        }
        if restartsApp {
            lines.append(UntranslatedL10n.screenManageStorageWarningRestart)
        }
        return lines.joined(separator: "\n\n")
    }
}

enum ManageStorageScreenViewAction {
    case reload
    case toggleRoom(String)
    /// Ask to clear one cache, or all of them (`nil`).
    case requestClear(StorageCacheKind?)
    /// Perform the pending clear request.
    case confirmClear
    case viewLogs
}

extension StorageCacheKind {
    var title: String {
        switch self {
        case .messageKeys: UntranslatedL10n.screenManageStorageCacheMessageKeys
        case .roomState: UntranslatedL10n.screenManageStorageCacheRoomState
        case .messages: UntranslatedL10n.screenManageStorageCacheMessages
        case .media: UntranslatedL10n.screenManageStorageCacheMedia
        case .logs: UntranslatedL10n.screenManageStorageCacheLogs
        }
    }

    /// The bar colour, one of Compound's decorative colours.
    var color: Color {
        switch self {
        case .messageKeys: .compound.textDecorative1
        case .roomState: .compound.textDecorative2
        case .messages: .compound.textDecorative3
        case .media: .compound.textDecorative4
        case .logs: .compound.textDecorative5
        }
    }
}

extension StorageUsageRoom {
    var displayName: String {
        name ?? id
    }
}
