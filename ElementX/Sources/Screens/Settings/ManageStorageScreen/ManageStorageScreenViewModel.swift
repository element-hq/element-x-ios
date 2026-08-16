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
            state.bindings.clearRequest = .init(cache: cache, restartsApp: clearsState && !state.isFiltered)
        case .confirmClear(let age):
            guard let request = state.bindings.clearRequest else { return }
            state.bindings.clearRequest = nil
            Task { await clear(request, age: age) }
        }
    }

    // MARK: - Private

    private func reload() async {
        state.isLoading = true
        defer { state.isLoading = false }

        switch await clientProxy.storageUsage() {
        case .success(let usage):
            var totalBytes = usage.totalBytes
            totalBytes[.logs] = logFiles().reduce(0) { $0 + $1.size }
            state.totalBytes = totalBytes
            state.rooms = usage.rooms
            state.selectedRoomIDs = state.selectedRoomIDs.intersection(usage.rooms.map(\.id))
        case .failure(let error):
            MXLog.error("Failed measuring the storage usage: \(error)")
            state.bindings.alertInfo = .init(id: .failure, title: L10n.errorUnknown, message: String(describing: error))
        }
    }

    private static let clearingIndicatorID = "\(ManageStorageScreenViewModel.self)-Clearing"

    /// Clears the requested cache(s) within the current scope (the selected rooms, or everything),
    /// limited to what's older than the chosen age: media not accessed for that long, log files
    /// older than that, and (for the per-room caches) the rooms with no activity for that long.
    private func clear(_ request: ManageStorageClearRequest, age: ManageStorageClearAge) async {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.clearingIndicatorID,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                              title: L10n.commonPleaseWait,
                                                              persistent: true))
        defer { userIndicatorController.retractIndicatorWithId(Self.clearingIndicatorID) }

        let caches = request.cache.map { [$0] } ?? state.visibleCaches
        // The rooms whose per-room caches are cleared: the selection (or all), pruned by inactivity when an age is set.
        let scopedRoomIDs: [String]? = state.isFiltered ? Array(state.selectedRoomIDs) : nil
        let roomIDs: [String]? = if let duration = age.duration {
            (state.isFiltered ? state.selectedRooms : state.rooms)
                .filter { room in room.lastActivity.map { $0 < Date.now.addingTimeInterval(-duration) } ?? false }
                .map(\.id)
        } else {
            scopedRoomIDs
        }

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
                if case .failure = await clientProxy.clearMediaCache(roomIDs: scopedRoomIDs, notAccessedFor: age.duration) { failed = true }
            case .logs:
                deleteLogFiles(olderThan: age.duration)
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

    private func deleteLogFiles(olderThan duration: TimeInterval?) {
        let cutoff = duration.map { Date.now.addingTimeInterval(-$0) }
        for file in logFiles() where cutoff.map({ file.modificationDate < $0 }) ?? true {
            try? FileManager.default.removeItem(at: file.url)
        }
    }
}
