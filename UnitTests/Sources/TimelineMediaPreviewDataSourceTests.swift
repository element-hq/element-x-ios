//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import QuickLook
import Testing

@Suite
@MainActor
struct TimelineMediaPreviewDataSourceTests {
    var initialMediaItems: [EventBasedMessageTimelineItemProtocol]!
    var initialMediaViewStates: [RoomTimelineItemViewState]!
    let initialItemIndex = 2
    
    var initialPadding = 100
    let previewController = QLPreviewController()
    
    init() {
        initialMediaItems = newChunk()
        initialMediaViewStates = initialMediaItems.map { RoomTimelineItemViewState(item: $0, groupStyle: .single) }
    }
    
    @Test
    func initialItems() throws {
        _ = try makeInitialDataSource()
    }
    
    @Test
    func currentUpdateItem() throws {
        // Given a data source built with the initial items.
        let dataSource = TimelineMediaPreviewDataSource(itemViewStates: initialMediaViewStates,
                                                        initialItem: initialMediaItems[initialItemIndex],
                                                        paginationState: .initial)
        
        // When a different item is displayed.
        let previewItem = try #require(dataSource.previewController(previewController, previewItemAt: 1 + initialPadding) as? TimelineMediaPreviewItem.Media,
                                       "A preview item should be found.")
        dataSource.updateCurrentItem(.media(previewItem))
        
        // Then the data source should reflect the change of item.
        #expect(dataSource.currentMediaItemID == previewItem.id, "The displayed item should be the initial item.")
        
        // When a loading item is displayed.
        guard let loadingItem = dataSource.previewController(previewController, previewItemAt: initialPadding - 1) as? TimelineMediaPreviewItem.Loading else {
            Issue.record("A loading item should be be returned.")
            return
        }
        dataSource.updateCurrentItem(.loading(loadingItem))
        
        // Then the data source should show a loading item
        #expect(dataSource.currentItem == .loading(loadingItem), "The displayed item should be the loading item.")
    }
    
    @Test
    func updatedItems() async throws {
        // Given a data source built with the initial items.
        let dataSource = try makeInitialDataSource()
        
        // When one of the items changes but no pagination has occurred.
        let deferred = deferFailure(dataSource.previewItemsPaginationPublisher, timeout: .seconds(1)) { _ in true }
        dataSource.updatePreviewItems(itemViewStates: initialMediaViewStates)
        
        // Then no pagination should be detected and none of the data should have changed.
        try await deferred.fulfill()
        
        let previewItemCount = dataSource.numberOfPreviewItems(in: previewController)
        let displayedItem = try #require(dataSource.previewController(previewController, previewItemAt: dataSource.initialItemIndex) as? TimelineMediaPreviewItem.Media)
        #expect(displayedItem.id == initialMediaItems[initialItemIndex].id.eventOrTransactionID, "The displayed item should not change.")
        #expect(dataSource.currentMediaItemID == initialMediaItems[initialItemIndex].id.eventOrTransactionID, "The current item should not change.")
        
        #expect(dataSource.previewItems.count == initialMediaViewStates.count, "The number of items should not change.")
        #expect(previewItemCount == initialMediaViewStates.count + (2 * initialPadding), "The padded number of items should not change.")
    }
    
    @Test
    func pagination() async throws {
        // Given a data source built with the initial items.
        let dataSource = try makeInitialDataSource()
        
        // When more items are loaded in a back pagination.
        var deferred = deferFulfillment(dataSource.previewItemsPaginationPublisher) { _ in true }
        let backPaginationChunk = newChunk().map { RoomTimelineItemViewState(item: $0, groupStyle: .single) }
        var newViewStates = backPaginationChunk + initialMediaViewStates
        dataSource.updatePreviewItems(itemViewStates: newViewStates)
        
        // Then the new items should be added but the displayed item should not change or move in the array.
        try await deferred.fulfill()
        #expect(dataSource.previewItems.count == newViewStates.count, "The new items should be added.")
        
        var previewItemCount = dataSource.numberOfPreviewItems(in: previewController)
        var displayedItem = try #require(dataSource.previewController(previewController, previewItemAt: dataSource.initialItemIndex) as? TimelineMediaPreviewItem.Media)
        #expect(displayedItem.id == initialMediaItems[initialItemIndex].id.eventOrTransactionID, "The displayed item should not change.")
        #expect(dataSource.currentMediaItemID == initialMediaItems[initialItemIndex].id.eventOrTransactionID, "The current item should not change.")
        #expect(previewItemCount == initialMediaViewStates.count + (2 * initialPadding), "The number of items should not change")
        
        // When more items are loaded in a forward pagination or sync.
        deferred = deferFulfillment(dataSource.previewItemsPaginationPublisher) { _ in true }
        let forwardPaginationChunk = newChunk().map { RoomTimelineItemViewState(item: $0, groupStyle: .single) }
        newViewStates += forwardPaginationChunk
        dataSource.updatePreviewItems(itemViewStates: newViewStates)
        
        // Then the new items should be added but the displayed item should not change or move in the array.
        try await deferred.fulfill()
        #expect(dataSource.previewItems.count == newViewStates.count, "The new items should be added.")
        
        previewItemCount = dataSource.numberOfPreviewItems(in: previewController)
        displayedItem = try #require(dataSource.previewController(previewController, previewItemAt: dataSource.initialItemIndex) as? TimelineMediaPreviewItem.Media)
        #expect(displayedItem.id == initialMediaItems[initialItemIndex].id.eventOrTransactionID, "The displayed item should not change.")
        #expect(dataSource.currentMediaItemID == initialMediaItems[initialItemIndex].id.eventOrTransactionID, "The current item should not change.")
        #expect(previewItemCount == initialMediaViewStates.count + (2 * initialPadding), "The number of items should not change")
    }
    
    @Test
    mutating func paginationLimits() async throws {
        // Given a data source with a small amount of padding remaining.
        initialPadding = 2
        let dataSource = try makeInitialDataSource()
        
        // When paginating backwards by more than the available padding.
        var deferred = deferFulfillment(dataSource.previewItemsPaginationPublisher) { _ in true }
        let backPaginationChunk = newChunk().map { RoomTimelineItemViewState(item: $0, groupStyle: .single) }
        var newViewStates = backPaginationChunk + initialMediaViewStates
        #expect(newViewStates.count > initialPadding)
        dataSource.updatePreviewItems(itemViewStates: newViewStates)
        
        // Then all the items should be added but the preview-able count shouldn't grow and displayed item should not change or move.
        try await deferred.fulfill()
        #expect(dataSource.previewItems.count == newViewStates.count, "The new items should be added.")
        
        var previewItemCount = dataSource.numberOfPreviewItems(in: previewController)
        var displayedItem = try #require(dataSource.previewController(previewController, previewItemAt: dataSource.initialItemIndex) as? TimelineMediaPreviewItem.Media)
        #expect(displayedItem.id == initialMediaItems[initialItemIndex].id.eventOrTransactionID, "The displayed item should not change.")
        #expect(dataSource.currentMediaItemID == initialMediaItems[initialItemIndex].id.eventOrTransactionID, "The current item should not change.")
        #expect(previewItemCount == initialMediaViewStates.count + (2 * initialPadding), "The number of items should not change")
        
        // When paginating forwards by more than the available padding.
        deferred = deferFulfillment(dataSource.previewItemsPaginationPublisher) { _ in true }
        let forwardPaginationChunk = newChunk().map { RoomTimelineItemViewState(item: $0, groupStyle: .single) }
        newViewStates += forwardPaginationChunk
        dataSource.updatePreviewItems(itemViewStates: newViewStates)
        
        // Then all the items should be added but the preview-able count shouldn't grow and displayed item should not change or move.
        try await deferred.fulfill()
        #expect(dataSource.previewItems.count == newViewStates.count, "The new items should be added.")
        
        previewItemCount = dataSource.numberOfPreviewItems(in: previewController)
        displayedItem = try #require(dataSource.previewController(previewController, previewItemAt: dataSource.initialItemIndex) as? TimelineMediaPreviewItem.Media)
        #expect(displayedItem.id == initialMediaItems[initialItemIndex].id.eventOrTransactionID, "The displayed item should not change.")
        #expect(dataSource.currentMediaItemID == initialMediaItems[initialItemIndex].id.eventOrTransactionID, "The current item should not change.")
        #expect(previewItemCount == initialMediaViewStates.count + (2 * initialPadding), "The number of items should not change")
    }
    
    @Test
    func emptyTimeline() async throws {
        // Given a data source built with no timeline items loaded.
        let initialItem = initialMediaItems[initialItemIndex]
        let dataSource = TimelineMediaPreviewDataSource(itemViewStates: [],
                                                        initialItem: initialItem,
                                                        initialPadding: initialPadding,
                                                        paginationState: .initial)
        
        // When the preview controller displays the data.
        var previewItemCount = dataSource.numberOfPreviewItems(in: previewController)
        var displayedItem = try #require(dataSource.previewController(previewController, previewItemAt: dataSource.initialItemIndex) as? TimelineMediaPreviewItem.Media,
                                         "A preview item should be found.")
        
        // Then the preview controller should always show the initial item.
        #expect(dataSource.previewItems.count == 1, "The initial item should be in the preview items array.")
        #expect(previewItemCount == 1 + (2 * initialPadding), "The initial item count should be padded for the preview controller.")
        #expect(dataSource.initialItemIndex == initialPadding, "The initial item index should be padded for the preview controller.")
        
        #expect(displayedItem.id == initialItem.id.eventOrTransactionID, "The displayed item should be the initial item.")
        #expect(dataSource.currentMediaItemID == initialItem.id.eventOrTransactionID, "The current item should also be the initial item.")
        
        // When the timeline loads the initial items.
        let deferred = deferFulfillment(dataSource.previewItemsPaginationPublisher) { _ in true }
        let loadedItems = initialMediaItems.map { RoomTimelineItemViewState(item: $0, groupStyle: .single) }
        dataSource.updatePreviewItems(itemViewStates: loadedItems)
        try await deferred.fulfill()
        
        // Then the preview controller should still show the initial item with the other items loaded around it.
        previewItemCount = dataSource.numberOfPreviewItems(in: previewController)
        displayedItem = try #require(dataSource.previewController(previewController, previewItemAt: dataSource.initialItemIndex) as? TimelineMediaPreviewItem.Media,
                                     "A preview item should be found.")
        
        #expect(dataSource.previewItems.count == initialMediaViewStates.count, "The preview items should now be loaded.")
        #expect(previewItemCount == 1 + (2 * initialPadding), "The item count should not change as the padding will be reduced.")
        #expect(dataSource.initialItemIndex == initialPadding, "The item index should not change.")
        
        #expect(displayedItem.id == initialMediaItems[initialItemIndex].id.eventOrTransactionID, "The displayed item should not change.")
        #expect(dataSource.currentMediaItemID == initialMediaItems[initialItemIndex].id.eventOrTransactionID, "The current item should not change.")
    }
    
    @Test
    func timelineUpdateWithoutInitialItem() async throws {
        // Given a data source built with no timeline items loaded.
        let initialItem = initialMediaItems[initialItemIndex]
        let dataSource = TimelineMediaPreviewDataSource(itemViewStates: [],
                                                        initialItem: initialItem,
                                                        initialPadding: initialPadding,
                                                        paginationState: .initial)
        
        // When the preview controller displays the data.
        var previewItemCount = dataSource.numberOfPreviewItems(in: previewController)
        var displayedItem = try #require(dataSource.previewController(previewController, previewItemAt: dataSource.initialItemIndex) as? TimelineMediaPreviewItem.Media,
                                         "A preview item should be found.")
        
        // Then the preview controller should always show the initial item.
        #expect(dataSource.previewItems.count == 1, "The initial item should be in the preview items array.")
        #expect(previewItemCount == 1 + (2 * initialPadding), "The initial item count should be padded for the preview controller.")
        #expect(dataSource.initialItemIndex == initialPadding, "The initial item index should be padded for the preview controller.")
        
        #expect(displayedItem.id == initialItem.id.eventOrTransactionID, "The displayed item should be the initial item.")
        #expect(dataSource.currentMediaItemID == initialItem.id.eventOrTransactionID, "The current item should also be the initial item.")
        
        // When the timeline loads more items but still doesn't include the initial item.
        let failure = deferFailure(dataSource.previewItemsPaginationPublisher, timeout: .seconds(1)) { _ in true }
        let loadedItems = newChunk().map { RoomTimelineItemViewState(item: $0, groupStyle: .single) }
        dataSource.updatePreviewItems(itemViewStates: loadedItems)
        try await failure.fulfill()
        
        // Then the preview controller shouldn't update the available preview items.
        previewItemCount = dataSource.numberOfPreviewItems(in: previewController)
        displayedItem = try #require(dataSource.previewController(previewController, previewItemAt: dataSource.initialItemIndex) as? TimelineMediaPreviewItem.Media,
                                     "A preview item should be found.")
        
        #expect(dataSource.previewItems.count == 1, "No new items should have been added to the array.")
        #expect(previewItemCount == 1 + (2 * initialPadding), "The initial item count should not change.")
        #expect(dataSource.initialItemIndex == initialPadding, "The initial item index should not change.")
        
        #expect(displayedItem.id == initialItem.id.eventOrTransactionID, "The displayed item should not change.")
        #expect(dataSource.currentMediaItemID == initialItem.id.eventOrTransactionID, "The current item not change.")
    }
    
    // MARK: Helpers
    
    func newChunk() -> [EventBasedMessageTimelineItemProtocol] {
        RoomTimelineItemFixtures.mediaChunk
            .compactMap { $0 as? EventBasedMessageTimelineItemProtocol }
            .filter(\.supportsMediaCaption) // Voice messages can't be previewed (and don't support captions).
    }
    
    private func makeInitialDataSource() throws -> TimelineMediaPreviewDataSource {
        // Given a data source built with the initial items.
        let dataSource = TimelineMediaPreviewDataSource(itemViewStates: initialMediaViewStates,
                                                        initialItem: initialMediaItems[initialItemIndex],
                                                        initialPadding: initialPadding,
                                                        paginationState: .initial)
        
        // When the preview controller displays the data.
        let previewItemCount = dataSource.numberOfPreviewItems(in: previewController)
        let displayedItem = try #require(dataSource.previewController(previewController, previewItemAt: dataSource.initialItemIndex) as? TimelineMediaPreviewItem.Media,
                                         "A preview item should be found.")
        
        // Then the preview controller should be showing the initial item and the data source should reflect this.
        #expect(dataSource.initialItemIndex == initialItemIndex + initialPadding, "The initial item index should be padded for the preview controller.")
        #expect(displayedItem.id == initialMediaItems[initialItemIndex].id.eventOrTransactionID, "The displayed item should be the initial item.")
        #expect(dataSource.currentMediaItemID == initialMediaItems[initialItemIndex].id.eventOrTransactionID, "The current item should also be the initial item.")
        
        #expect(dataSource.previewItems.count == initialMediaViewStates.count, "The initial count of preview items should be correct.")
        #expect(previewItemCount == initialMediaViewStates.count + (2 * initialPadding), "The initial item count should be padded for the preview controller.")
        
        return dataSource
    }
}

private extension TimelineMediaPreviewDataSource {
    var currentMediaItemID: TimelineItemIdentifier.EventOrTransactionID? {
        switch currentItem {
        case .media(let mediaItem): mediaItem.id
        case .loading: nil
        }
    }
}
