//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import QuickLook
import XCTest

@MainActor
class TimelineMediaPreviewDataSourceTests: XCTestCase {
    var initialMediaItems: [EventBasedMessageTimelineItemProtocol]!
    var initialMediaViewStates: [RoomTimelineItemViewState]!
    let initialItemIndex = 2
    
    var initialPadding = 100
    let previewController = QLPreviewController()
    
    override func setUp() {
        initialMediaItems = newChunk()
        initialMediaViewStates = initialMediaItems.map { RoomTimelineItemViewState(item: $0, groupStyle: .single) }
    }
    
    func testInitialItems() -> TimelineMediaPreviewDataSource {
        // Given a data source built with the initial items.
        let dataSource = TimelineMediaPreviewDataSource(itemViewStates: initialMediaViewStates,
                                                        initialItem: initialMediaItems[initialItemIndex],
                                                        initialPadding: initialPadding)
        
        // When the preview controller displays the data.
        let previewItemCount = dataSource.numberOfPreviewItems(in: previewController)
        let displayedItem = dataSource.previewController(previewController, previewItemAt: dataSource.initialItemIndex) as? TimelineMediaPreviewItem
        
        // Then the preview controller should be showing the initial item and the data source should reflect this.
        XCTAssertEqual(dataSource.initialItemIndex, initialItemIndex + initialPadding, "The initial item index should be padded for the preview controller.")
        XCTAssertEqual(displayedItem?.id, initialMediaItems[initialItemIndex].id, "The displayed item should be the initial item.")
        XCTAssertEqual(dataSource.currentItem?.id, initialMediaItems[initialItemIndex].id, "The current item should also be the initial item.")
        
        XCTAssertEqual(dataSource.previewItems.count, initialMediaViewStates.count, "The initial count of preview items should be correct.")
        XCTAssertEqual(previewItemCount, initialMediaViewStates.count + (2 * initialPadding), "The initial item count should be padded for the preview controller.")
        
        return dataSource
    }
    
    func testCurrentUpdateItem() {
        // Given a data source built with the initial items.
        let dataSource = TimelineMediaPreviewDataSource(itemViewStates: initialMediaViewStates, initialItem: initialMediaItems[initialItemIndex])
        
        // When a different item is displayed.
        let previewItem = dataSource.previewController(previewController, previewItemAt: 1 + initialPadding) as? TimelineMediaPreviewItem
        XCTAssertNotNil(previewItem, "A preview item should be found.")
        dataSource.updateCurrentItem(previewItem)
        
        // Then the data source should reflect the change of item.
        XCTAssertEqual(dataSource.currentItem?.id, previewItem?.id, "The displayed item should be the initial item.")
        
        // When a loading item is displayed.
        let loadingItem = dataSource.previewController(previewController, previewItemAt: initialPadding - 1) as? TimelineMediaPreviewLoadingItem
        XCTAssertNotNil(loadingItem, "A loading item should be be returned.")
        dataSource.updateCurrentItem(nil)
        
        // Then the data source should indicate that no item is being displayed.
        XCTAssertNil(dataSource.currentItem, "The current item should be nil.")
    }
    
    func testUpdatedItems() async throws {
        // Given a data source built with the initial items.
        let dataSource = testInitialItems()
        
        // When one of the items changes but no pagination has occurred.
        let deferred = deferFailure(dataSource.previewItemsPaginationPublisher, timeout: 1) { _ in true }
        dataSource.updatePreviewItems(itemViewStates: initialMediaViewStates)
        
        // Then no pagination should be detected and none of the data should have changed.
        try await deferred.fulfill()
        
        let previewItemCount = dataSource.numberOfPreviewItems(in: previewController)
        let displayedItem = dataSource.previewController(previewController, previewItemAt: dataSource.initialItemIndex) as? TimelineMediaPreviewItem
        XCTAssertEqual(displayedItem?.id, initialMediaItems[initialItemIndex].id, "The displayed item should not change.")
        XCTAssertEqual(dataSource.currentItem?.id, initialMediaItems[initialItemIndex].id, "The current item should not change.")
        
        XCTAssertEqual(dataSource.previewItems.count, initialMediaViewStates.count, "The number of items should not change.")
        XCTAssertEqual(previewItemCount, initialMediaViewStates.count + (2 * initialPadding), "The padded number of items should not change.")
    }
    
    func testPagination() async throws {
        // Given a data source built with the initial items.
        let dataSource = testInitialItems()
        
        // When more items are loaded in a back pagination.
        var deferred = deferFulfillment(dataSource.previewItemsPaginationPublisher) { _ in true }
        let backPaginationChunk = newChunk().map { RoomTimelineItemViewState(item: $0, groupStyle: .single) }
        var newViewStates = backPaginationChunk + initialMediaViewStates
        dataSource.updatePreviewItems(itemViewStates: newViewStates)
        
        // Then the new items should be added but the displayed item should not change or move in the array.
        try await deferred.fulfill()
        XCTAssertEqual(dataSource.previewItems.count, newViewStates.count, "The new items should be added.")
        
        var previewItemCount = dataSource.numberOfPreviewItems(in: previewController)
        var displayedItem = dataSource.previewController(previewController, previewItemAt: dataSource.initialItemIndex) as? TimelineMediaPreviewItem
        XCTAssertEqual(displayedItem?.id, initialMediaItems[initialItemIndex].id, "The displayed item should not change.")
        XCTAssertEqual(dataSource.currentItem?.id, initialMediaItems[initialItemIndex].id, "The current item should not change.")
        XCTAssertEqual(previewItemCount, initialMediaViewStates.count + (2 * initialPadding), "The number of items should not change")
        
        // When more items are loaded in a forward pagination or sync.
        deferred = deferFulfillment(dataSource.previewItemsPaginationPublisher) { _ in true }
        let forwardPaginationChunk = newChunk().map { RoomTimelineItemViewState(item: $0, groupStyle: .single) }
        newViewStates += forwardPaginationChunk
        dataSource.updatePreviewItems(itemViewStates: newViewStates)
        
        // Then the new items should be added but the displayed item should not change or move in the array.
        try await deferred.fulfill()
        XCTAssertEqual(dataSource.previewItems.count, newViewStates.count, "The new items should be added.")
        
        previewItemCount = dataSource.numberOfPreviewItems(in: previewController)
        displayedItem = dataSource.previewController(previewController, previewItemAt: dataSource.initialItemIndex) as? TimelineMediaPreviewItem
        XCTAssertEqual(displayedItem?.id, initialMediaItems[initialItemIndex].id, "The displayed item should not change.")
        XCTAssertEqual(dataSource.currentItem?.id, initialMediaItems[initialItemIndex].id, "The current item should not change.")
        XCTAssertEqual(previewItemCount, initialMediaViewStates.count + (2 * initialPadding), "The number of items should not change")
    }
    
    func testPaginationLimits() async throws {
        // Given a data source with a small amount of padding remaining.
        initialPadding = 2
        let dataSource = testInitialItems()
        
        // When paginating backwards by more than the available padding.
        var deferred = deferFulfillment(dataSource.previewItemsPaginationPublisher) { _ in true }
        let backPaginationChunk = newChunk().map { RoomTimelineItemViewState(item: $0, groupStyle: .single) }
        var newViewStates = backPaginationChunk + initialMediaViewStates
        XCTAssertTrue(newViewStates.count > initialPadding)
        dataSource.updatePreviewItems(itemViewStates: newViewStates)
        
        // Then all the items should be added but the preview-able count shouldn't grow and displayed item should not change or move.
        try await deferred.fulfill()
        XCTAssertEqual(dataSource.previewItems.count, newViewStates.count, "The new items should be added.")
        
        var previewItemCount = dataSource.numberOfPreviewItems(in: previewController)
        var displayedItem = dataSource.previewController(previewController, previewItemAt: dataSource.initialItemIndex) as? TimelineMediaPreviewItem
        XCTAssertEqual(displayedItem?.id, initialMediaItems[initialItemIndex].id, "The displayed item should not change.")
        XCTAssertEqual(dataSource.currentItem?.id, initialMediaItems[initialItemIndex].id, "The current item should not change.")
        XCTAssertEqual(previewItemCount, initialMediaViewStates.count + (2 * initialPadding), "The number of items should not change")
        
        // When paginating forwards by more than the available padding.
        deferred = deferFulfillment(dataSource.previewItemsPaginationPublisher) { _ in true }
        let forwardPaginationChunk = newChunk().map { RoomTimelineItemViewState(item: $0, groupStyle: .single) }
        newViewStates += forwardPaginationChunk
        dataSource.updatePreviewItems(itemViewStates: newViewStates)
        
        // Then all the items should be added but the preview-able count shouldn't grow and displayed item should not change or move.
        try await deferred.fulfill()
        XCTAssertEqual(dataSource.previewItems.count, newViewStates.count, "The new items should be added.")
        
        previewItemCount = dataSource.numberOfPreviewItems(in: previewController)
        displayedItem = dataSource.previewController(previewController, previewItemAt: dataSource.initialItemIndex) as? TimelineMediaPreviewItem
        XCTAssertEqual(displayedItem?.id, initialMediaItems[initialItemIndex].id, "The displayed item should not change.")
        XCTAssertEqual(dataSource.currentItem?.id, initialMediaItems[initialItemIndex].id, "The current item should not change.")
        XCTAssertEqual(previewItemCount, initialMediaViewStates.count + (2 * initialPadding), "The number of items should not change")
    }
    
    // MARK: Helpers
    
    func newChunk() -> [EventBasedMessageTimelineItemProtocol] {
        RoomTimelineItemFixtures.mediaChunk
            .compactMap { $0 as? EventBasedMessageTimelineItemProtocol }
            .filter(\.supportsMediaCaption) // Voice messages can't be previewed (and don't support captions).
    }
}
