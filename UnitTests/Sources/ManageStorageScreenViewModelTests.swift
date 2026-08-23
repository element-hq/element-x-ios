//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Foundation
import MatrixRustSDK
import Testing

@MainActor
struct ManageStorageScreenViewModelTests {
    let clientProxy: ClientProxyMock
    let viewModel: ManageStorageScreenViewModel
    let logsDirectory: URL

    var context: ManageStorageScreenViewModelType.Context { viewModel.context }

    init() throws {
        clientProxy = ClientProxyMock(.init())
        // The second measurement (after a clear) is marked, so tests can wait for it.
        clientProxy.storeSizesClosure = { [clientProxy] in
            var sizes = StoreSizes.mock
            if clientProxy.storeSizesCallsCount > 1 {
                sizes.eventCacheStore = 1
            }
            return .success(sizes)
        }
        clientProxy.storageUsageByRoomClosure = { [clientProxy] in
            // After a clear, the big room reports nothing at all.
            let rooms = [StorageUsageRoom].mock
            return .success(clientProxy.storageUsageByRoomCallsCount > 1 ? rooms.filter { $0.id != "!big:example.org" } : rooms)
        }
        clientProxy.clearRoomKeysRoomIDsReturnValue = .success(())
        clientProxy.clearRoomCachesRoomIDsReturnValue = .success(())
        clientProxy.clearMediaCacheRoomIDsNotAccessedForReturnValue = .success(())

        logsDirectory = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString)
        try FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
        try Data(repeating: 1, count: 1000).write(to: logsDirectory.appending(component: "a.log"))
        try Data(repeating: 1, count: 2000).write(to: logsDirectory.appending(component: "b.log"))

        viewModel = ManageStorageScreenViewModel(clientProxy: clientProxy,
                                                 userIndicatorController: UserIndicatorControllerMock(),
                                                 logsDirectory: logsDirectory)
    }

    @Test
    func loadingAndScoping() async throws {
        try await waitForLoad()

        // All rooms: every cache including the logs, sized from the report and the files.
        #expect(context.viewState.activeCaches == StorageCacheKind.allCases)
        #expect(context.viewState.bytes(for: .logs) == 3000)
        #expect(context.viewState.bytes(for: .media) == StoreSizes.mock.mediaStore)
        #expect(context.viewState.scopeTitle == "\(UntranslatedL10n.screenManageStorageScopeAllRooms) (530.0 MB, 3 rooms)")
        #expect(context.viewState.rooms.map(\.id) == [StorageUsageRoom].mock.map(\.id))
        // The small room isn't worth listing.
        #expect(context.viewState.listedRooms.map(\.id) == ["!big:example.org", "!medium:example.org"])

        // One room selected: its sizes only; the logs have no per-room share so read zero (and
        // don't set the chart's scale), and aren't clearable.
        context.send(viewAction: .toggleRoom("!medium:example.org"))
        #expect(context.viewState.activeCaches == StorageCacheKind.allCases.filter(\.isPerRoom))
        #expect(context.viewState.bytes(for: .logs) == 0)
        #expect(context.viewState.bytes(for: .roomState) == 60_000_000)
        #expect(context.viewState.scopeTitle == "Matrix HQ (95.0 MB)")
        #expect(context.viewState.clearAllTitle == UntranslatedL10n.screenManageStorageClearForRoom("Matrix HQ"))

        // Two rooms: summed.
        context.send(viewAction: .toggleRoom("!big:example.org"))
        #expect(context.viewState.bytes(for: .roomState) == 90_000_000)
        #expect(context.viewState.scopeTitle == "\(UntranslatedL10n.screenManageStorageScopeRooms(2)) (467.0 MB)")
        #expect(context.viewState.clearAllTitle == UntranslatedL10n.screenManageStorageClearForRooms(2))
    }

    @Test
    func searchingListsSmallRooms() async throws {
        try await waitForLoad()

        // A search matches by name or ID and ignores the size threshold.
        context.searchQuery = "hq"
        #expect(context.viewState.listedRooms.map(\.id) == ["!medium:example.org"])
        context.searchQuery = "small"
        #expect(context.viewState.listedRooms.map(\.id) == ["!small:example.org"])
        context.searchQuery = ""
        #expect(context.viewState.listedRooms.map(\.id) == ["!big:example.org", "!medium:example.org"])
    }

    @Test
    func clearingSelectedRooms() async throws {
        try await waitForLoad()
        context.send(viewAction: .toggleRoom("!big:example.org"))

        // Clearing everything for a room clears each cache for that room only, without a restart.
        context.send(viewAction: .requestClear(nil))
        let request = try #require(context.viewState.bindings.clearRequest)
        #expect(!request.restartsApp)
        #expect(request.title == "Clear caches for Element X iOS?")

        let deferred = deferFulfillment(context.observe(\.viewState.totalBytes)) { $0[.messages] == 1 }
        context.send(viewAction: .confirmClear)
        try await deferred.fulfill()

        #expect(clientProxy.clearRoomKeysRoomIDsReceivedRoomIDs == ["!big:example.org"])
        #expect(clientProxy.clearRoomCachesRoomIDsCallsCount == 1)
        #expect(clientProxy.clearRoomCachesRoomIDsReceivedRoomIDs == ["!big:example.org"])
        #expect(clientProxy.clearMediaCacheRoomIDsNotAccessedForReceivedArguments?.roomIDs == ["!big:example.org"])
        #expect(clientProxy.clearMediaCacheRoomIDsNotAccessedForReceivedArguments?.notAccessedFor == nil)
        // The logs are session-wide: untouched.
        #expect(context.viewState.totalBytes[.logs] == 3000)
        // The cleared stores are vacuumed so their files shrink.
        #expect(clientProxy.optimizeEventCacheStoreCalled)
        #expect(clientProxy.optimizeMediaStoreCalled)

        // The cleared room stays listed and selected (empty) rather than vanishing from under the selection.
        try await waitForLoad()
        #expect(context.viewState.selectedRoomIDs == ["!big:example.org"])
        #expect(context.viewState.listedRooms.map(\.id) == ["!medium:example.org", "!big:example.org"])
        #expect(context.viewState.bytes(for: .roomState) == 0)
    }

    @Test
    func clearingRoomMessagesClearsItsMediaFirst() async throws {
        try await waitForLoad()
        context.send(viewAction: .toggleRoom("!big:example.org"))
        
        // When clearing only the room's messages.
        var order = [String]()
        clientProxy.clearMediaCacheRoomIDsNotAccessedForClosure = { _, _ in order.append("media"); return .success(()) }
        clientProxy.clearRoomCachesRoomIDsClosure = { _ in order.append("messages"); return .success(()) }
        context.send(viewAction: .requestClear(.messages))
        #expect(context.viewState.bindings.clearRequest?.message.contains(UntranslatedL10n.screenManageStorageWarningMessagesMedia) == true)
        // Wait for the reload that follows the clear (the rooms aren't loading at this point, so
        // waiting for them to finish would return at once).
        let reloaded = deferFulfillment(context.observe(\.viewState.isLoading)) { $0 }
        context.send(viewAction: .confirmClear)
        try await reloaded.fulfill()
        
        // Then its media is cleared too, and before the messages (the media is found through them).
        #expect(order == ["media", "messages"])
        #expect(clientProxy.clearMediaCacheRoomIDsNotAccessedForReceivedArguments?.roomIDs == ["!big:example.org"])
    }
    
    @Test
    func clearingEverythingRestarts() async throws {
        try await waitForLoad()

        context.send(viewAction: .requestClear(.roomState))
        let request = try #require(context.viewState.bindings.clearRequest)
        #expect(request.restartsApp)
        #expect(request.message.contains(UntranslatedL10n.screenManageStorageWarningRoomState))

        let deferred = deferFulfillment(viewModel.actionsPublisher) { $0 == .clearCache }
        context.send(viewAction: .confirmClear)
        try await deferred.fulfill()
        #expect(clientProxy.clearRoomCachesRoomIDsCallsCount == 0)
    }

    @Test
    func clearingLogs() async throws {
        try await waitForLoad()

        context.send(viewAction: .requestClear(.logs))
        let request = try #require(context.viewState.bindings.clearRequest)
        #expect(request.title == "Clear log files?")

        // Viewing them dismisses the alert without clearing.
        let viewLogs = deferFulfillment(viewModel.actionsPublisher) { $0 == .viewLogs }
        context.send(viewAction: .viewLogs)
        try await viewLogs.fulfill()
        #expect(context.viewState.bindings.clearRequest == nil)
        #expect(context.viewState.totalBytes[.logs] == 3000)

        context.send(viewAction: .requestClear(.logs))
        let deferred = deferFulfillment(context.observe(\.viewState.totalBytes)) { $0[.logs] == 0 }
        context.send(viewAction: .confirmClear)
        try await deferred.fulfill()
        #expect(try FileManager.default.contentsOfDirectory(atPath: logsDirectory.path()).isEmpty)
        #expect(clientProxy.clearRoomCachesRoomIDsCallsCount == 0)
    }

    private func waitForLoad() async throws {
        let deferred = deferFulfillment(context.observe(\.viewState.isLoadingRooms)) { !$0 && !self.context.viewState.rooms.isEmpty }
        try await deferred.fulfill()
    }
}
