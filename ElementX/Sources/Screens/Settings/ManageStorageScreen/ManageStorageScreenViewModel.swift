//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias ManageStorageScreenViewModelType = StateStoreViewModelV2<ManageStorageScreenViewState, ManageStorageScreenViewAction>

class ManageStorageScreenViewModel: ManageStorageScreenViewModelType, ManageStorageScreenViewModelProtocol {
    private let clientProxy: ClientProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let logsDirectory: URL

    private var roomsTask: Task<Void, Never>?

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

        Task { await reload() }
    }

    isolated deinit {
        roomsTask?.cancel()
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

    /// The totals (the stores' sizes on disk, instant) come first; the rooms then fill in as the
    /// SDK walks them, biggest first.
    private func reload() async {
        state.isLoading = true

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
        state.rooms = []
        state.isLoadingRooms = true
        roomsTask = Task { [weak self, clientProxy] in
            for await rooms in clientProxy.storageUsageByRoom() {
                self?.upsert(rooms)
            }
            guard !Task.isCancelled, let self else { return }
            state.selectedRoomIDs = state.selectedRoomIDs.intersection(state.rooms.map(\.id))
            state.isLoadingRooms = false
        }
    }

    /// Adds a batch of rooms (replacing their previous numbers), keeping the rooms sorted by total, largest first.
    private func upsert(_ batch: [StorageUsageRoom]) {
        let batchIDs = Set(batch.map(\.id))
        state.rooms = (state.rooms.filter { !batchIDs.contains($0.id) } + batch).sorted { $0.totalBytes > $1.totalBytes }
    }

    private static let clearingIndicatorID = "\(ManageStorageScreenViewModel.self)-Clearing"

    /// Clears the requested cache(s) within the current scope (the selected rooms, or everything).
    private func clear(_ request: ManageStorageClearRequest) async {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.clearingIndicatorID,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                              title: L10n.commonPleaseWait,
                                                              persistent: true))
        defer { userIndicatorController.retractIndicatorWithId(Self.clearingIndicatorID) }

        let caches = request.cache.map { [$0] } ?? state.visibleCaches
        // The rooms whose caches are cleared: the selection, or all.
        let roomIDs: [String]? = state.isFiltered ? Array(state.selectedRoomIDs) : nil

        var failed = false
        var restartsApp = false

        for cache in caches {
            switch cache {
            case .messageKeys:
                if case .failure = await clientProxy.clearRoomKeys(roomIDs: roomIDs) { failed = true }
            case .roomState, .messages:
                // The two are cleared together, so once is enough when clearing everything.
                guard cache == .roomState || !caches.contains(.roomState) else { continue }
                if let roomIDs {
                    if case .failure = await clientProxy.clearRoomCaches(roomIDs: roomIDs) { failed = true }
                } else {
                    restartsApp = true // The whole state store: the app clears its caches and restarts.
                }
            case .media:
                if case .failure = await clientProxy.clearMediaCache(roomIDs: roomIDs, notAccessedFor: nil) { failed = true }
            case .logs:
                deleteLogFiles()
            }
        }

        if restartsApp {
            actionsSubject.send(.clearCache)
            return
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
