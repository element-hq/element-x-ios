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
}

struct ManageStorageScreenViewState: BindableState {
    /// The smallest room worth listing.
    static let listedRoomMinimumBytes: UInt64 = 5_000_000

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

    /// The rooms shown: the ones using more than ``listedRoomMinimumBytes``.
    var listedRooms: [StorageUsageRoom] {
        rooms.filter { $0.totalBytes >= Self.listedRoomMinimumBytes }
    }

    var selectedRooms: [StorageUsageRoom] {
        rooms.filter { selectedRoomIDs.contains($0.id) }
    }

    /// The caches shown for the current scope: the logs are session-wide, so they hide when rooms are selected.
    var visibleCaches: [StorageCacheKind] {
        isFiltered ? StorageCacheKind.allCases.filter(\.isPerRoom) : StorageCacheKind.allCases
    }

    /// The size of a cache within the current scope.
    func bytes(for cache: StorageCacheKind) -> UInt64 {
        guard isFiltered else { return totalBytes[cache] ?? 0 }
        return selectedRooms.reduce(0) { $0 + ($1.bytes[cache] ?? 0) }
    }

    /// The label of the bar chart: all rooms, the selected room, or the number of selected rooms.
    var scopeTitle: String {
        switch selectedRooms.count {
        case 0: UntranslatedL10n.screenManageStorageScopeAllRooms
        case 1: selectedRooms[0].displayName
        case let count: UntranslatedL10n.screenManageStorageScopeRooms(count)
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
    /// The clear the user is being asked to confirm (and scope by age).
    var clearRequest: ManageStorageClearRequest?
    var alertInfo: AlertInfo<ManageStorageScreenAlert>?
}

enum ManageStorageScreenAlert {
    case failure
}

/// A clear awaiting confirmation: one cache, or all of them (`nil`).
struct ManageStorageClearRequest: Identifiable, Equatable, ConfirmationDialogProtocol {
    let cache: StorageCacheKind?
    /// Whether clearing means clearing the whole state store, which restarts the app.
    let restartsApp: Bool

    var id: String { cache.map(\.title) ?? "all" }

    var title: String {
        UntranslatedL10n.screenManageStorageClearCacheTitle(cache?.title.lowercased() ?? UntranslatedL10n.screenManageStorageClearAll.lowercased())
    }

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
        lines.append(UntranslatedL10n.screenManageStorageWarningOlderThan)
        return lines.joined(separator: "\n\n")
    }
}

/// The age options offered when clearing.
enum ManageStorageClearAge: CaseIterable {
    case everything, olderThan30Days, olderThan90Days

    var days: Int? {
        switch self {
        case .everything: nil
        case .olderThan30Days: 30
        case .olderThan90Days: 90
        }
    }

    var title: String {
        switch days {
        case .none: UntranslatedL10n.screenManageStorageClearOptionEverything
        case .some(let days): UntranslatedL10n.screenManageStorageClearOptionOlderThan(days)
        }
    }

    var duration: TimeInterval? {
        days.map { TimeInterval($0) * 24 * 60 * 60 }
    }
}

enum ManageStorageScreenViewAction {
    case reload
    case toggleRoom(String)
    /// Ask to clear one cache, or all of them (`nil`).
    case requestClear(StorageCacheKind?)
    /// Perform the pending clear request with the chosen age.
    case confirmClear(ManageStorageClearAge)
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
