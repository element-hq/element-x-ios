//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK
import MatrixRustSDKMocks
import XCTest

@testable import ElementX

final class RoomSummaryProviderTests: XCTestCase {
    var appSettings: AppSettings!
    var roomList: RoomListSDKMock!
    var dynamicEntriesController: RoomListDynamicEntriesControllerSDKMock!
    
    let baseFilters: [RoomListEntriesDynamicFilterKind] = [.any(filters: [.all(filters: [.nonSpace, .nonLeft]),
                                                                          .all(filters: [.space, .invite])]),
                                                           .deduplicateVersions]
    
    var roomSummaryProvider: RoomSummaryProvider!
    
    override func setUp() {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
    }
    
    override func tearDown() {
        AppSettings.resetAllSettings()
    }
    
    func testDefaultRustFilters() async {
        // Given a new room provider.
        setupProvider()
        await Task.yield()
        
        // Then it should have the default Rust filters enabled.
        XCTAssertEqual(dynamicEntriesController.setFilterKindCallsCount, 1)
        XCTAssertEqual(dynamicEntriesController.setFilterKindReceivedInvocations.last,
                       .all(filters: baseFilters))
        
        // When setting one our user filters.
        roomSummaryProvider.setFilter(.all(filters: [.favourites]))
        await Task.yield()
        
        // Then that filter should be added to the default Rust filters.
        XCTAssertEqual(dynamicEntriesController.setFilterKindCallsCount, 2)
        XCTAssertEqual(dynamicEntriesController.setFilterKindReceivedInvocations.last,
                       .all(filters: [.all(filters: [.favourite, .joined])] + baseFilters))
    }
    
    func testLowPriorityRustFilters() async {
        // Given a new room provider with the low priority filter enabled.
        setupProvider(isLowPriorityFilterEnabled: true)
        await Task.yield()
        
        // Then the default Rust filters should include the non-low priority filter,
        // so that low priority rooms are hidden from the top of the room list.
        XCTAssertEqual(dynamicEntriesController.setFilterKindCallsCount, 1)
        XCTAssertEqual(dynamicEntriesController.setFilterKindReceivedInvocations.last,
                       .all(filters: baseFilters + [.nonLowPriority]))
        
        // When setting the low priority filter.
        roomSummaryProvider.setFilter(.all(filters: [.lowPriority]))
        await Task.yield()
        
        // Then the non-low priority filter should be replaced with the low priority filter.
        XCTAssertEqual(dynamicEntriesController.setFilterKindCallsCount, 2)
        XCTAssertEqual(dynamicEntriesController.setFilterKindReceivedInvocations.last,
                       .all(filters: [.all(filters: [.lowPriority, .joined])] + baseFilters))
        
        // When setting another one of our filters.
        roomSummaryProvider.setFilter(.all(filters: [.rooms]))
        await Task.yield()
        
        // Then the filter should be combined with the non-low priority filter.
        XCTAssertEqual(dynamicEntriesController.setFilterKindCallsCount, 3)
        XCTAssertEqual(dynamicEntriesController.setFilterKindReceivedInvocations.last,
                       .all(filters: [.all(filters: [.category(expect: .group), .joined])] + baseFilters + [.nonLowPriority]))
    }
    
    // MARK: - Helpers
    
    private func setupProvider(isLowPriorityFilterEnabled: Bool = false) {
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
