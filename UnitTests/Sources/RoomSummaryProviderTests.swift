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

@Suite(.serialized)
@MainActor
final class RoomSummaryProviderTests {
    private let baseFilters: [RoomListEntriesDynamicFilterKind] = [.any(filters: [.all(filters: [.nonSpace, .nonLeft]),
                                                                                  .all(filters: [.space, .invite])]),
                                                                   .deduplicateVersions]

    var appSettings: AppSettings!
    var roomList: RoomListSDKMock!
    var dynamicEntriesController: RoomListDynamicEntriesControllerSDKMock!
    var roomSummaryProvider: RoomSummaryProvider!

    deinit {
        AppSettings.resetAllSettings()
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
    
    // MARK: - Helpers
    
    private func setup(isLowPriorityFilterEnabled: Bool = false) {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
        appSettings.lowPriorityFilterEnabled = isLowPriorityFilterEnabled

        let stateEventStringBuilder = RoomStateEventStringBuilder(userID: "@me:matrix.org")
        let attributedStringBuilder = AttributedStringBuilder(mentionBuilder: MentionBuilder())
        let eventStringBuilder = RoomEventStringBuilder(stateEventStringBuilder: stateEventStringBuilder,
                                                        messageEventStringBuilder: RoomMessageEventStringBuilder(attributedStringBuilder: attributedStringBuilder,
                                                                                                                 destination: .roomList),
                                                        shouldDisambiguateDisplayNames: true,
                                                        shouldPrefixSenderName: true)

        roomSummaryProvider = RoomSummaryProvider(roomListService: RoomListServiceSDKMock(),
                                                  eventStringBuilder: eventStringBuilder,
                                                  name: "Test",
                                                  notificationSettings: NotificationSettingsProxyMock(with: .init()),
                                                  appSettings: appSettings)

        dynamicEntriesController = RoomListDynamicEntriesControllerSDKMock()
        dynamicEntriesController.setFilterKindReturnValue = true
        let dynamicAdaptersResult = RoomListEntriesWithDynamicAdaptersResultSDKMock()
        dynamicAdaptersResult.controllerReturnValue = dynamicEntriesController
        roomList = RoomListSDKMock()
        roomList.entriesWithDynamicAdaptersWithPageSizeEnableLatestEventSorterListenerReturnValue = dynamicAdaptersResult
        roomList.loadingStateListenerReturnValue = .some(.init(state: .notLoaded, stateStream: .init(noHandle: .init())))
        roomSummaryProvider.setRoomList(roomList)
    }
}
