//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import MatrixRustSDK
import MatrixRustSDKMocks
import Testing

@MainActor
final class RoomSummaryProviderTests {
    private let baseFilters: [RoomListEntriesDynamicFilterKind] = [.any(filters: [.all(filters: [.nonSpace, .nonLeft]),
                                                                                  .all(filters: [.space, .invite])]),
                                                                   .deduplicateVersions]
    
    var userSettings: UserSettings!
    var roomList: RoomListSDKMock!
    var dynamicEntriesController: RoomListDynamicEntriesControllerSDKMock!
    var roomSummaryProvider: RoomSummaryProvider!
    
    enum TestError: Error {
        case missingRoomInfo
    }
    
    @Test
    func defaultRustFilters() async {
        // Given a new room provider.
        setup()
        await Task.yield()
        
        // Then it should have the default Rust filters enabled.
        #expect(dynamicEntriesController.setFilterKindCallsCount == 1)
        #expect(dynamicEntriesController.setFilterKindReceivedInvocations.last == .all(filters: baseFilters))
        
        // When setting one our user filters.
        roomSummaryProvider.setFilter(.all(filters: [.favourites]))
        await Task.yield()
        
        // Then that filter should be added to the default Rust filters.
        #expect(dynamicEntriesController.setFilterKindCallsCount == 2)
        #expect(dynamicEntriesController.setFilterKindReceivedInvocations.last == .all(filters: [.all(filters: [.favourite, .joined])] + baseFilters))
    }
    
    @Test
    func joinedRoomsOnlyRustFilters() async {
        // Given a new room provider that only includes joined rooms.
        setup(includesOnlyJoinedRooms: true)
        await Task.yield()
        
        // Then the joined filter should be added to the default Rust filters.
        #expect(dynamicEntriesController.setFilterKindReceivedInvocations.last == .all(filters: baseFilters + [.joined]))
        
        // When searching.
        roomSummaryProvider.setFilter(.search(query: "Foundation"))
        await Task.yield()
        
        // Then the search should be restricted to joined rooms too.
        #expect(dynamicEntriesController.setFilterKindReceivedInvocations.last == .all(filters: [.normalizedMatchRoomName(pattern: "Foundation")] + baseFilters + [.joined]))
    }
    
    @Test
    func filterSetBeforeTheRoomListIsKept() async {
        // Given a new room provider that is filtered before it has a room list.
        setup(setsRoomList: false)
        roomSummaryProvider.setFilter(.search(query: "Foundation"))
        
        // When setting its room list.
        roomSummaryProvider.setRoomList(roomList)
        await Task.yield()
        
        // Then the filter should be applied instead of the default one.
        #expect(dynamicEntriesController.setFilterKindCallsCount == 1)
        #expect(dynamicEntriesController.setFilterKindReceivedInvocations.last == .all(filters: [.normalizedMatchRoomName(pattern: "Foundation")] + baseFilters))
    }
    
    @Test
    func lowPriorityRustFilters() async {
        // Given a new room provider with the low priority filter enabled.
        setup(isLowPriorityFilterEnabled: true)
        await Task.yield()
        
        // Then the default Rust filters should include the non-low priority filter,
        // so that low priority rooms are hidden from the top of the room list.
        #expect(dynamicEntriesController.setFilterKindCallsCount == 1)
        #expect(dynamicEntriesController.setFilterKindReceivedInvocations.last == .all(filters: baseFilters + [.nonLowPriority]))
        
        // When setting the low priority filter.
        roomSummaryProvider.setFilter(.all(filters: [.lowPriority]))
        await Task.yield()
        
        // Then the non-low priority filter should be replaced with the low priority filter.
        #expect(dynamicEntriesController.setFilterKindCallsCount == 2)
        #expect(dynamicEntriesController.setFilterKindReceivedInvocations.last == .all(filters: [.all(filters: [.lowPriority, .joined])] + baseFilters))
        
        // When setting another one of our filters.
        roomSummaryProvider.setFilter(.all(filters: [.rooms]))
        await Task.yield()
        
        // Then the filter should be combined with the non-low priority filter.
        #expect(dynamicEntriesController.setFilterKindCallsCount == 3)
        #expect(dynamicEntriesController.setFilterKindReceivedInvocations.last == .all(filters: [.all(filters: [.category(expect: .group), .joined])] + baseFilters + [.nonLowPriority]))
    }
    
    @Test
    func roomIdentifierFilters() async {
        setup()
        await Task.yield()
        
        // Then it should have the default Rust filters enabled.
        #expect(dynamicEntriesController.setFilterKindCallsCount == 1)
        #expect(dynamicEntriesController.setFilterKindReceivedInvocations.last == .all(filters: baseFilters))
        
        // When setting one our user filters.
        roomSummaryProvider.setFilter(.rooms(roomsIDs: ["SomeRoom"], filters: [.favourites]))
        await Task.yield()
        
        // Then that filter should be added to the default Rust filters.
        #expect(dynamicEntriesController.setFilterKindCallsCount == 2)
        #expect(dynamicEntriesController.setFilterKindReceivedInvocations.last == .all(filters: [.all(filters: [.favourite, .joined])] + baseFilters + [.identifiers(identifiers: ["SomeRoom"])]))
    }
    
    @Test
    func reachingTheBottomAddsAPage() async throws {
        // Given a provider showing its first page of rooms.
        setup(roomListPageSize: 10)
        try await loadRooms(count: 10)
        
        // When a picker reports reaching the bottom with an empty range at the end of the list.
        roomSummaryProvider.updateVisibleRange(10..<10)
        
        // Then the next page should be requested.
        #expect(dynamicEntriesController.addOnePageCallsCount == 1)
        
        // When reaching the bottom again before that page has loaded.
        roomSummaryProvider.updateVisibleRange(10..<10)
        
        // Then the request shouldn't be repeated.
        #expect(dynamicEntriesController.addOnePageCallsCount == 1)
    }
    
    @Test
    func scrollingNearTheBottomPrefetchesAPage() async throws {
        // Given a provider showing its first page of rooms.
        setup(roomListPageSize: 10)
        try await loadRooms(count: 10)
        
        // When scrolling to more than half a page away from the bottom.
        roomSummaryProvider.updateVisibleRange(0..<4)
        
        // Then no page should be requested yet.
        #expect(dynamicEntriesController.addOnePageCallsCount == 0)
        
        // When scrolling to half a page away from the bottom.
        roomSummaryProvider.updateVisibleRange(1..<5)
        
        // Then the next page should be requested.
        #expect(dynamicEntriesController.addOnePageCallsCount == 1)
    }
    
    @Test
    func reachingTheTopDoesNotAddAPage() async throws {
        // Given a provider with fewer rooms than half a page.
        setup(roomListPageSize: 10)
        try await loadRooms(count: 4)
        
        // When a picker reports reaching the top with an empty range at the start of the list.
        roomSummaryProvider.updateVisibleRange(0..<0)
        
        // Then no page should be requested.
        #expect(dynamicEntriesController.addOnePageCallsCount == 0)
    }
    
    // MARK: - Helpers
    
    private func setup(isLowPriorityFilterEnabled: Bool = false,
                       includesOnlyJoinedRooms: Bool = false,
                       roomListPageSize: UInt32 = 100,
                       setsRoomList: Bool = true) {
        userSettings = UserSettings.mock()
        userSettings.app.lowPriorityFilterEnabled = isLowPriorityFilterEnabled
        
        let stateEventStringBuilder = RoomStateEventStringBuilder(userID: "@me:matrix.org")
        let attributedStringBuilder = AttributedStringBuilder(mentionBuilder: MentionBuilder())
        let eventStringBuilder = RoomEventStringBuilder(stateEventStringBuilder: stateEventStringBuilder,
                                                        messageEventStringBuilder: RoomMessageEventStringBuilder(attributedStringBuilder: attributedStringBuilder,
                                                                                                                 style: .senderPrefixed),
                                                        shouldPrefixSenderName: true)
        
        roomSummaryProvider = RoomSummaryProvider(roomListService: RoomListServiceSDKMock(),
                                                  eventStringBuilder: eventStringBuilder,
                                                  name: "Test",
                                                  includesOnlyJoinedRooms: includesOnlyJoinedRooms,
                                                  roomListPageSize: roomListPageSize,
                                                  notificationSettings: NotificationSettingsProxyMock(with: .init()),
                                                  userSettings: userSettings)
        
        dynamicEntriesController = RoomListDynamicEntriesControllerSDKMock()
        dynamicEntriesController.setFilterKindReturnValue = true
        let dynamicAdaptersResult = RoomListEntriesWithDynamicAdaptersResultSDKMock()
        dynamicAdaptersResult.controllerReturnValue = dynamicEntriesController
        roomList = RoomListSDKMock()
        roomList.entriesWithDynamicAdaptersPageSizeListenerReturnValue = dynamicAdaptersResult
        roomList.loadingStateListenerReturnValue = .some(.init(state: .notLoaded, stateStream: TaskHandleSDKMock()))
        
        if setsRoomList {
            roomSummaryProvider.setRoomList(roomList)
        }
    }
    
    private func loadRooms(count: Int) async throws {
        let listener = try #require(roomList.entriesWithDynamicAdaptersPageSizeListenerReceivedArguments?.listener)
        let rooms = (0..<count).map { index in
            let room = RoomSDKMock()
            room.idReturnValue = "!room\(index):matrix.org"
            room.latestEventReturnValue = LatestEventValue.none
            // Only the room count matters, so placeholder summaries avoid mocking a whole RoomInfo.
            room.roomInfoThrowableError = TestError.missingRoomInfo
            return room
        }
        
        let deferred = deferFulfillment(roomSummaryProvider.roomListPublisher) { $0.count == count }
        listener.onUpdate(roomEntriesUpdate: [.append(values: rooms)])
        try await deferred.fulfill()
    }
}
