//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Foundation
import Testing

@MainActor
struct ManageStorageScreenViewModelTests {
    let clientProxy: ClientProxyMock
    let viewModel: ManageStorageScreenViewModel
    let logsDirectory: URL

    var context: ManageStorageScreenViewModelType.Context { viewModel.context }

    static let day: TimeInterval = 24 * 60 * 60

    init() throws {
        clientProxy = ClientProxyMock(.init())
        // The second measurement (after a clear) is marked, so tests can wait for it.
        clientProxy.storageUsageClosure = { [clientProxy] in
            var usage = StorageUsage.mock
            if clientProxy.storageUsageCallsCount > 1 {
                usage = .init(totalBytes: usage.totalBytes.merging([.messages: 1]) { _, new in new }, rooms: usage.rooms)
            }
            return .success(usage)
        }
        clientProxy.clearRoomKeysRoomIDsReturnValue = .success(())
        clientProxy.clearRoomCachesRoomIDsReturnValue = .success(())
        clientProxy.clearMediaCacheRoomIDsNotAccessedForReturnValue = .success(())

        logsDirectory = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString)
        try FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
        // Two log files: one fresh, one 40 days old.
        try Data(repeating: 1, count: 1000).write(to: logsDirectory.appending(component: "fresh.log"))
        let oldURL = logsDirectory.appending(component: "old.log")
        try Data(repeating: 1, count: 2000).write(to: oldURL)
        try FileManager.default.setAttributes([.modificationDate: Date.now.addingTimeInterval(-40 * Self.day)], ofItemAtPath: oldURL.path())

        viewModel = ManageStorageScreenViewModel(clientProxy: clientProxy,
                                                 userIndicatorController: UserIndicatorControllerMock(),
                                                 logsDirectory: logsDirectory)
    }

    @Test
    func loadingAndScoping() async throws {
        try await waitForLoad()

        // All rooms: every cache including the logs, sized from the report and the files.
        #expect(context.viewState.visibleCaches == StorageCacheKind.allCases)
        #expect(context.viewState.bytes(for: .logs) == 3000)
        #expect(context.viewState.bytes(for: .media) == StorageUsage.mock.totalBytes[.media])
        #expect(context.viewState.scopeTitle == UntranslatedL10n.screenManageStorageScopeAllRooms)
        #expect(context.viewState.rooms.map(\.id) == StorageUsage.mock.rooms.map(\.id))

        // One room selected: its sizes only, no logs.
        context.send(viewAction: .toggleRoom("!medium:example.org"))
        #expect(context.viewState.visibleCaches == StorageCacheKind.allCases.filter(\.isPerRoom))
        #expect(context.viewState.bytes(for: .roomState) == 60_000_000)
        #expect(context.viewState.scopeTitle == "Matrix HQ")
        #expect(context.viewState.clearAllTitle == UntranslatedL10n.screenManageStorageClearForRoom("Matrix HQ"))

        // Two rooms: summed.
        context.send(viewAction: .toggleRoom("!big:example.org"))
        #expect(context.viewState.bytes(for: .roomState) == 90_000_000)
        #expect(context.viewState.scopeTitle == UntranslatedL10n.screenManageStorageScopeRooms(2))
        #expect(context.viewState.clearAllTitle == UntranslatedL10n.screenManageStorageClearForRooms(2))
    }

    @Test
    func clearingSelectedRooms() async throws {
        try await waitForLoad()
        context.send(viewAction: .toggleRoom("!big:example.org"))

        // Clearing everything for a room clears each cache for that room only, without a restart.
        context.send(viewAction: .requestClear(nil))
        let request = try #require(context.viewState.bindings.clearRequest)
        #expect(!request.restartsApp)

        let deferred = deferFulfillment(context.observe(\.viewState.totalBytes)) { $0[.messages] == 1 }
        context.send(viewAction: .confirmClear(.everything))
        try await deferred.fulfill()

        #expect(clientProxy.clearRoomKeysRoomIDsReceivedRoomIDs == ["!big:example.org"])
        #expect(clientProxy.clearRoomCachesRoomIDsCallsCount == 1)
        #expect(clientProxy.clearRoomCachesRoomIDsReceivedRoomIDs == ["!big:example.org"])
        #expect(clientProxy.clearMediaCacheRoomIDsNotAccessedForReceivedArguments?.roomIDs == ["!big:example.org"])
        #expect(clientProxy.clearMediaCacheRoomIDsNotAccessedForReceivedArguments?.notAccessedFor == nil)
        // The logs are session-wide: untouched.
        #expect(context.viewState.totalBytes[.logs] == 3000)
    }

    @Test
    func clearingEverythingRestarts() async throws {
        try await waitForLoad()

        context.send(viewAction: .requestClear(.roomState))
        let request = try #require(context.viewState.bindings.clearRequest)
        #expect(request.restartsApp)
        #expect(request.message.contains(UntranslatedL10n.screenManageStorageWarningRoomState))

        let deferred = deferFulfillment(viewModel.actionsPublisher) { $0 == .clearCache }
        context.send(viewAction: .confirmClear(.everything))
        try await deferred.fulfill()
        #expect(clientProxy.clearRoomCachesRoomIDsCallsCount == 0)
    }

    @Test
    func clearingOlderThan() async throws {
        try await waitForLoad()

        // Older than 30 days, all rooms: only the inactive room's caches, media by last access, old log files.
        context.send(viewAction: .requestClear(nil))
        let deferred = deferFulfillment(context.observe(\.viewState.totalBytes)) { $0[.messages] == 1 }
        context.send(viewAction: .confirmClear(.olderThan30Days))
        try await deferred.fulfill()

        #expect(clientProxy.clearRoomKeysRoomIDsReceivedRoomIDs == ["!medium:example.org"])
        #expect(clientProxy.clearRoomCachesRoomIDsReceivedRoomIDs == ["!medium:example.org"])
        #expect(clientProxy.clearMediaCacheRoomIDsNotAccessedForCallsCount == 1)
        #expect(clientProxy.clearMediaCacheRoomIDsNotAccessedForReceivedArguments?.roomIDs == nil)
        #expect(clientProxy.clearMediaCacheRoomIDsNotAccessedForReceivedArguments?.notAccessedFor == 30 * Self.day)
        #expect(context.viewState.totalBytes[.logs] == 1000)
        #expect(FileManager.default.fileExists(atPath: logsDirectory.appending(component: "fresh.log").path()))
        #expect(!FileManager.default.fileExists(atPath: logsDirectory.appending(component: "old.log").path()))
    }

    private func waitForLoad() async throws {
        let deferred = deferFulfillment(context.observe(\.viewState.isLoading)) { !$0 && !self.context.viewState.rooms.isEmpty }
        try await deferred.fulfill()
    }
}
