//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import AsyncAlgorithms
import Combine
import SwiftUI

typealias ManageStorageScreenViewModelType = StateStoreViewModelV2<ManageStorageScreenViewState, ManageStorageScreenViewAction>

class ManageStorageScreenViewModel: ManageStorageScreenViewModelType, ManageStorageScreenViewModelProtocol {
    private let clientProxy: ClientProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let logsDirectory: URL

    private var roomsTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>?

    private let actionsSubject: PassthroughSubject<ManageStorageScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<ManageStorageScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(clientProxy: ClientProxyProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         logsDirectory: URL = Tracing.logsDirectory) {
        self.clientProxy = clientProxy
        self.userIndicatorController = userIndicatorController
        self.logsDirectory = logsDirectory

        super.init(initialViewState: ManageStorageScreenViewState())

        let searchQueryStream = context.observe(\.viewState.bindings.searchQuery).removeDuplicates()
        searchTask = Task { [weak self] in
            for await _ in searchQueryStream {
                self?.updateListedRooms()
            }
        }

        Task { await reload() }
    }

    isolated deinit {
        roomsTask?.cancel()
        searchTask?.cancel()
    }

    override func process(viewAction: ManageStorageScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")

        switch viewAction {
        case .reload:
            Task { await reload() }
        case .toggleRoom(let roomID):
            if state.selectedRoomIDs.contains(roomID) {
                state.selectedRoomIDs.remove(roomID)
            } else {
                state.selectedRoomIDs.insert(roomID)
            }
            updateListedRooms()
        case .requestClear(let cache):
            let clearsState = cache == nil || cache == .roomState || cache == .messages
            state.bindings.clearRequest = .init(cache: cache,
                                                restartsApp: clearsState && !state.isFiltered,
                                                title: cache.map { UntranslatedL10n.screenManageStorageClearCacheTitle($0.title.lowercased()) }
                                                    ?? UntranslatedL10n.screenManageStorageClearScopeTitle(state.clearAllTitle))
        case .confirmClear:
            guard let request = state.bindings.clearRequest else { return }
            state.bindings.clearRequest = nil
            Task { await clear(request) }
        case .viewLogs:
            state.bindings.clearRequest = nil
            actionsSubject.send(.viewLogs)
        }
    }

    // MARK: - Private

    /// Re-filters the listed rooms: once per change to the rooms, the selection or the search query.
    private func updateListedRooms() {
        state.listedRooms = ManageStorageScreenViewState.listedRooms(in: state.rooms,
                                                                     selectedRoomIDs: state.selectedRoomIDs,
                                                                     searchQuery: state.bindings.searchQuery)
    }

    /// The totals (the stores' sizes on disk, instant) come first; the rooms follow once measured.
    private func reload() async {
        state.isLoading = true
        state.isLoadingRooms = true

        switch await clientProxy.storeSizes() {
        case .success(let sizes):
            state.totalBytes = [.messageKeys: sizes.cryptoStore ?? 0,
                                .roomState: sizes.stateStore ?? 0,
                                .messages: sizes.eventCacheStore ?? 0,
                                .media: sizes.mediaStore ?? 0,
                                .logs: logFiles().reduce(0) { $0 + $1.size }]
        case .failure(let error):
            MXLog.error("Failed measuring the store sizes: \(error)")
            state.bindings.alertInfo = .init(id: .failure, title: L10n.errorUnknown, message: String(describing: error))
        }
        state.isLoading = false

        roomsTask?.cancel()
        roomsTask = Task { [weak self, clientProxy] in
            let result = await clientProxy.storageUsageByRoom()
            guard !Task.isCancelled, let self else { return }
            switch result {
            case .success(let rooms):
                // A selected room cleared to nothing is no longer reported: keep it listed (empty)
                // rather than dropping the selection out from under the user.
                let reportedIDs = Set(rooms.map(\.id))
                let emptiedSelection = state.rooms
                    .filter { state.selectedRoomIDs.contains($0.id) && !reportedIDs.contains($0.id) }
                    .map { StorageUsageRoom(id: $0.id, name: $0.name, lastActivity: $0.lastActivity, bytes: [:]) }
                state.rooms = rooms + emptiedSelection
                updateListedRooms()
            case .failure(let error):
                MXLog.error("Failed measuring the rooms' storage usage: \(error)")
                state.bindings.alertInfo = .init(id: .failure, title: L10n.errorUnknown, message: String(describing: error))
            }
            state.isLoadingRooms = false
        }
    }

    private static let clearingIndicatorID = "\(ManageStorageScreenViewModel.self)-Clearing"

    /// Clears the requested cache(s) within the current scope (the selected rooms, or everything).
    private func clear(_ request: ManageStorageClearRequest) async {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.clearingIndicatorID,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                              title: L10n.commonPleaseWait,
                                                              persistent: true))
        defer { userIndicatorController.retractIndicatorWithId(Self.clearingIndicatorID) }

        var caches = request.cache.map { [$0] } ?? state.activeCaches
        // The rooms whose caches are cleared: the selection, or all.
        let roomIDs: [String]? = state.isFiltered ? Array(state.selectedRoomIDs) : nil
        
        // A room's media is found through its stored messages: once those are cleared the media
        // can't be attributed to the room any more (clearing it afterwards found nothing, every
        // time). So media goes BEFORE messages/state, and clearing a room's messages clears its
        // media too, as clearing its messages clears its state.
        if roomIDs != nil, caches.contains(where: { $0 == .messages || $0 == .roomState }), !caches.contains(.media) {
            caches.append(.media)
        }
        caches.sort { lhs, rhs in (lhs == .media ? 0 : 1) < (rhs == .media ? 0 : 1) }

        var failed = false
        var restartsApp = false
        var clearedEventCache = false
        var clearedMedia = false

        for cache in caches {
            switch cache {
            case .messageKeys:
                if case .failure = await clientProxy.clearRoomKeys(roomIDs: roomIDs) { failed = true }
            case .roomState, .messages:
                // The two are cleared together, so once is enough when clearing everything.
                guard cache == .roomState || !caches.contains(.roomState) else { continue }
                if let roomIDs {
                    if case .failure = await clientProxy.clearRoomCaches(roomIDs: roomIDs) { failed = true } else { clearedEventCache = true }
                } else {
                    restartsApp = true // The whole state store: the app clears its caches and restarts.
                }
            case .media:
                if case .failure = await clientProxy.clearMediaCache(roomIDs: roomIDs, notAccessedFor: nil) { failed = true } else { clearedMedia = true }
            case .logs:
                deleteLogFiles()
            }
        }

        if restartsApp {
            actionsSubject.send(.clearCache)
            return
        }

        // Deleting rows leaves SQLite's file the same size (the freed pages are kept for reuse), so
        // the sizes shown wouldn't move: vacuum the stores that were cleared. Takes a while on a big
        // store, under the same "please wait".
        if clearedEventCache {
            await clientProxy.optimizeEventCacheStore()
        }
        if clearedMedia {
            await clientProxy.optimizeMediaStore()
        }

        if failed {
            state.bindings.alertInfo = .init(id: .failure, title: L10n.errorUnknown, message: UntranslatedL10n.screenManageStorageError)
        } else {
            userIndicatorController.submitIndicator(.init(title: UntranslatedL10n.screenManageStorageCleared, icon: \.check))
        }

        await reload()
    }

    // MARK: Log files

    private func logFiles() -> [(url: URL, size: UInt64, modificationDate: Date)] {
        let keys: Set<URLResourceKey> = [.fileSizeKey, .contentModificationDateKey]
        let urls = (try? FileManager.default.contentsOfDirectory(at: logsDirectory,
                                                                 includingPropertiesForKeys: Array(keys),
                                                                 options: .skipsSubdirectoryDescendants)) ?? []
        return urls.compactMap { url in
            guard url.lastPathComponent.hasSuffix(Tracing.fileExtension),
                  let values = try? url.resourceValues(forKeys: keys) else { return nil }
            return (url, UInt64(values.fileSize ?? 0), values.contentModificationDate ?? .distantPast)
        }
    }

    private func deleteLogFiles() {
        for file in logFiles() {
            try? FileManager.default.removeItem(at: file.url)
        }
    }
}
